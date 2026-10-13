import 'dart:typed_data';
import 'dart:async';
import 'package:canokey_console/helper/utils/card_session.dart';

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/src/rust/api/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'passes complete responses and wipes exchange copies before closing',
    () async {
      final command = Uint8List.fromList([0, 0xfd, 0, 0, 0]);
      final data = Uint8List.fromList([6, 0, 0]);
      final operation = _Operation([
        ProtocolStep(command: command),
        ProtocolStep(data: data),
      ]);
      final transport = _Transport((command) async {
        expect(command, '00FD000000');
        return '0600009000';
      });
      expect(await executeProtocolOperation(operation, transport), data);
      expect(operation.responses, [
        [6, 0, 0, 0x90, 0],
      ]);
      expect(command, everyElement(0));
      expect(operation.borrowedResponse, everyElement(0));
      expect(operation.closed, isTrue);
      expect(operation.disposed, isTrue);
      expect(data, [6, 0, 0]);
    },
  );

  test(
    'transport failure propagates unchanged, closes, and never retries',
    () async {
      final failure = StateError('disconnected');
      final command = Uint8List.fromList([0, 0xfd, 0, 0, 0]);
      final operation = _Operation([ProtocolStep(command: command)]);
      var calls = 0;
      await expectLater(
        executeProtocolOperation(
          operation,
          _Transport((_) async {
            calls++;
            throw failure;
          }),
        ),
        throwsA(same(failure)),
      );
      expect(calls, 1);
      expect(operation.responses, isEmpty);
      expect(command, everyElement(0));
      expect(operation.closed && operation.disposed, isTrue);
    },
  );

  test('malformed transport hex closes without advancing', () async {
    final operation = _Operation([ProtocolStep(command: Uint8List(5))]);
    await expectLater(
      executeProtocolOperation(operation, _Transport((_) async => 'xyz')),
      throwsFormatException,
    );
    expect(operation.responses, isEmpty);
    expect(operation.closed && operation.disposed, isTrue);
  });

  test('protocol error retains all structured details and closes', () async {
    const details = ProtocolError(
      kind: 'AuthenticationFailed',
      phase: 'Authentication',
      statusWord: 0x63c2,
      reference: 'Pin',
      retriesRemaining: 2,
    );
    final operation = _Operation([const ProtocolStep(error: details)]);
    await expectLater(
      executeProtocolOperation(
        operation,
        _Transport((_) async {
          fail('No exchange after failure');
        }),
      ),
      throwsA(
        isA<ProtocolException>().having(
          (error) => error.details,
          'details',
          same(details),
        ),
      ),
    );
    expect(operation.closed && operation.disposed, isTrue);
  });

  test(
    'cancellation waits for I/O and closes before releasing the lease',
    () async {
      final sessions = CardSessions();
      final cancellation = CardCancellation();
      final response = Completer<String>();
      final started = Completer<void>();
      final command = Uint8List.fromList([0, 0xfd, 0, 0, 0]);
      final operation = _Operation([ProtocolStep(command: command)]);
      final useCase = sessions.run((session) async {
        session.bind((_) {
          started.complete();
          return response.future;
        });
        await expectLater(
          executeProtocolOperation(
            operation,
            _Transport((_) async => throw StateError('Wrong transport')),
            lease: session.lease,
            cancellation: cancellation,
          ),
          throwsStateError,
        );
      });
      await started.future;
      cancellation.cancel();
      var nextStarted = false;
      final next = sessions.run((_) async {
        expect(operation.closed && operation.disposed, isTrue);
        nextStarted = true;
      });
      await Future<void>.delayed(Duration.zero);
      expect(operation.closed, isFalse);
      expect(nextStarted, isFalse);
      response.complete('0600009000');
      await Future.wait([useCase, next]);
      expect(operation.responses, isEmpty);
      expect(command, everyElement(0));
    },
  );

  test('connection replacement rejects response before Rust advance', () async {
    final sessions = CardSessions();
    final operation = _Operation([ProtocolStep(command: Uint8List(5))]);
    await sessions.run((session) async {
      session.bind((_) async {
        sessions.invalidate();
        return '9000';
      });
      await expectLater(
        executeProtocolOperation(
          operation,
          _Transport((_) async => throw StateError('Wrong transport')),
          lease: session.lease,
        ),
        throwsStateError,
      );
    });
    expect(operation.responses, isEmpty);
    expect(operation.closed && operation.disposed, isTrue);
  });

  test('cancellation before start performs no exchange and closes', () async {
    final cancellation = CardCancellation()..cancel();
    final operation = _Operation([]);
    await expectLater(
      executeProtocolOperation(
        operation,
        _Transport((_) async => fail('Unexpected exchange')),
        cancellation: cancellation,
      ),
      throwsStateError,
    );
    expect(operation.closed && operation.disposed, isTrue);
  });

  test(
    'production transport refuses an operation outside a use-case lease',
    () async {
      final operation = _Operation([]);
      await expectLater(
        executeProtocolOperation(operation, const SmartCardApduTransport()),
        throwsStateError,
      );
      expect(operation.closed && operation.disposed, isTrue);
    },
  );

  test('cancelled probe result is freed instead of published', () async {
    final cancellation = CardCancellation();
    final profile = _Profile();
    final operation = _Operation([
      ProtocolStep(profile: profile),
    ], onStart: cancellation.cancel);
    final sessions = CardSessions();
    await sessions.run((session) async {
      session.bind((_) async => fail('Unexpected exchange'));
      await expectLater(
        executeProfileProbe(
          operation,
          _Transport((_) async => fail('Unexpected exchange')),
          lease: session.lease,
          cancellation: cancellation,
        ),
        throwsStateError,
      );
      expect(profile.closed && profile.disposed, isTrue);
      // The executor releases its reservation even when result publication fails.
      session.lease.beginOperation().close();
    });
    expect(operation.closed && operation.disposed, isTrue);
  });

  test('unexpected bridge exception still releases the operation', () async {
    final operation = _Operation([]);
    await expectLater(
      executeProtocolOperation(operation, _Transport((_) async => '9000')),
      throwsRangeError,
    );
    expect(operation.closed && operation.disposed, isTrue);
  });
}

class _Operation implements ProtocolOperation {
  _Operation(this.steps, {this.onStart});
  final void Function()? onStart;
  final List<ProtocolStep> steps;
  final responses = <List<int>>[];
  Uint8List? borrowedResponse;
  bool closed = false;
  bool disposed = false;

  @override
  ProtocolStep start() {
    onStart?.call();
    return steps.removeAt(0);
  }

  @override
  ProtocolStep advance({required List<int> response}) {
    responses.add(List.of(response));
    borrowedResponse = response as Uint8List;
    return steps.removeAt(0);
  }

  @override
  void close() => closed = true;
  @override
  void dispose() => disposed = true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Transport implements ApduTransport {
  _Transport(this.exchange);
  final Future<String> Function(String) exchange;
  @override
  Future<String> transceive(String capdu) => exchange(capdu);
}

class _Profile implements ProtocolProfile {
  bool closed = false;
  bool disposed = false;
  @override
  void close() => closed = true;
  @override
  void dispose() => disposed = true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
