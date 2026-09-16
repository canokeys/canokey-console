import 'dart:async';

import 'package:canokey_console/helper/utils/card_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'lease resources release on rebind and despite a failing destructor',
    () async {
      final sessions = CardSessions();
      final released = <String>[];
      await expectLater(
        sessions.run((session) async {
          session.bind((_) async => '9000');
          session.lease.onClose(() => released.add('old'));
          session.bind((_) async => '9000');
          expect(released, ['old']);
          session.lease.onClose(() => released.add('new'));
          session.lease.onClose(() => throw StateError('cleanup failed'));
        }),
        throwsStateError,
      );
      expect(released, ['old', 'new']);
      await sessions.run((_) async => released.add('next'));
      expect(released.last, 'next');
      expect(sessions.isBusy, isFalse);
    },
  );

  test(
    'operation reservation excludes raw I/O and rebinding between APDUs',
    () async {
      final sessions = CardSessions();
      await sessions.run((session) async {
        final commands = <String>[];
        session.bind((command) async {
          commands.add(command);
          return '9000';
        });
        final reservation = session.lease.beginOperation();
        await reservation.exchange('READ');
        expect(session.lease.beginOperation, throwsStateError);
        await expectLater(session.lease.exchange('SELECT'), throwsStateError);
        expect(() => session.bind((_) async => '9000'), throwsStateError);
        await reservation.exchange('GET RESPONSE');
        reservation.close();
        reservation.close();
        await session.lease.exchange('NEXT');
        expect(commands, ['READ', 'GET RESPONSE', 'NEXT']);
      });
    },
  );

  test(
    'Admin authentication evidence follows selection and profile generations',
    () async {
      final sessions = CardSessions();
      await sessions.run((session) async {
        session.bind((_) async => '9000');
        final lease = session.lease;
        expect(lease.hasAdminAuthentication, isFalse);
        lease.recordAdminAuthentication();
        expect(lease.hasAdminAuthentication, isTrue);
        // Explicit invalidation, applet selection and profile invalidation
        // each expire the recorded evidence.
        lease.invalidateAdminAuthentication();
        expect(lease.hasAdminAuthentication, isFalse);
        lease.recordAdminAuthentication();
        lease.willSelectApplet();
        expect(lease.hasAdminAuthentication, isFalse);
        lease.recordAdminAuthentication();
        lease.invalidateProfileEvidence();
        expect(lease.hasAdminAuthentication, isFalse);
        // A replaced lease carries no evidence at all.
        lease.recordAdminAuthentication();
        session.bind((_) async => '9000');
        expect(session.lease.hasAdminAuthentication, isFalse);
      });
    },
  );

  test(
    'SmartCard scopes own and expire leases around complete callbacks',
    () async {
      SmartCard.connectionType = ConnectionType.ccid;
      addTearDown(() => SmartCard.connectionType = ConnectionType.none);
      final ready = Completer<void>();
      final finish = Completer<void>();
      late CardLease lease;
      var nextStarted = false;
      final first = SmartCard.process((_) async {
        lease = SmartCard.currentLease;
        ready.complete();
        await finish.future;
        lease.check();
      });
      await ready.future;
      final next = SmartCard.process((_) async {
        nextStarted = true;
        expect(() => lease.check(), throwsStateError);
        SmartCard.currentLease.check();
      });
      await Future<void>.delayed(Duration.zero);
      expect(nextStarted, isFalse);
      finish.complete();
      await Future.wait([first, next]);
      expect(() => SmartCard.currentLease, throwsStateError);
      expect(() => lease.check(), throwsStateError);
    },
  );

  test(
    'holds exclusivity across selection, authentication and publication',
    () async {
      final sessions = CardSessions();
      final selected = Completer<void>();
      final proceed = Completer<void>();
      final events = <String>[];
      late CardLease oldLease;
      final first = sessions.run((session) async {
        session.bind((command) async {
          events.add(command);
          return '9000';
        });
        oldLease = session.lease;
        await oldLease.exchange('SELECT');
        selected.complete();
        await proceed.future;
        await oldLease.exchange('VERIFY');
        await oldLease.exchange('READ');
        oldLease.check();
        events.add('publish');
      });
      await selected.future;
      final second = sessions.run((session) async {
        events.add('next');
        session.bind((_) async => '9000');
        expect(() => oldLease.check(), throwsStateError);
      });
      await Future<void>.delayed(Duration.zero);
      expect(events, ['SELECT']);
      proceed.complete();
      await Future.wait([first, second]);
      expect(events, ['SELECT', 'VERIFY', 'READ', 'publish', 'next']);
      expect(sessions.isBusy, isFalse);
    },
  );

  test(
    'disconnect rejects a late response and never switches its channel',
    () async {
      final sessions = CardSessions();
      final response = Completer<String>();
      await sessions.run((session) async {
        session.bind((_) => response.future);
        final lease = session.lease;
        final exchange = lease.exchange('READ');
        final rejected = expectLater(exchange, throwsStateError);
        sessions.invalidate();
        response.complete('old device response');
        await rejected;
        expect(() => lease.check(), throwsStateError);
        session.bind((_) async => 'new device');
        expect(await session.lease.exchange('SELECT'), 'new device');
        expect(() => lease.check(), throwsStateError);
      });
    },
  );

  test('even an unawaited I/O drains before the next use case', () async {
    final sessions = CardSessions();
    final response = Completer<String>();
    final started = Completer<void>();
    late Future<void> rejected;
    final first = sessions.run((session) async {
      session.bind((_) => response.future);
      rejected = expectLater(session.lease.exchange('READ'), throwsStateError);
      started.complete();
    });
    await started.future;
    var nextStarted = false;
    final next = sessions.run((_) async => nextStarted = true);
    await Future<void>.delayed(Duration.zero);
    expect(nextStarted, isFalse);
    response.complete('9000');
    await Future.wait([first, next, rejected]);
    expect(nextStarted, isTrue);
  });

  test('a transport error poisons the lease without replay', () async {
    final sessions = CardSessions();
    final failure = TimeoutException('transport timeout');
    var calls = 0;
    await sessions.run((session) async {
      session.bind((_) async {
        calls++;
        throw failure;
      });
      final lease = session.lease;
      await expectLater(lease.exchange('WRITE'), throwsA(same(failure)));
      await expectLater(lease.exchange('WRITE'), throwsStateError);
      expect(calls, 1);
    });
  });

  test(
    'refuses overlapping I/O and rebind while a command is pending',
    () async {
      final sessions = CardSessions();
      final response = Completer<String>();
      await sessions.run((session) async {
        session.bind((_) => response.future);
        final pending = session.lease.exchange('READ');
        await expectLater(session.lease.exchange('SELECT'), throwsStateError);
        expect(() => session.bind((_) async => '9000'), throwsStateError);
        response.complete('9000');
        await pending;
      });
    },
  );

  test(
    'bound UI callback retains ownership but cannot outlive its use case',
    () async {
      final sessions = CardSessions();
      final ready = Completer<void>();
      final submitted = Completer<void>();
      late Future<void> Function() submit;
      final useCase = sessions.run((session) async {
        session.bind((_) async => '9000');
        submit = Zone.current.bindCallback(() async {
          expect(sessions.current, same(session));
          await sessions.current!.lease.exchange('VERIFY');
          submitted.complete();
        });
        ready.complete();
        await submitted.future;
      });
      await ready.future;
      expect(sessions.current, isNull);
      await submit();
      await useCase;
      await expectLater(submit(), throwsStateError);
    },
  );
}
