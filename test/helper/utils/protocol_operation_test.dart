import 'dart:typed_data';

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
  _Operation(this.steps);
  final List<ProtocolStep> steps;
  final responses = <List<int>>[];
  Uint8List? borrowedResponse;
  bool closed = false;
  bool disposed = false;

  @override
  ProtocolStep start() => steps.removeAt(0);
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
