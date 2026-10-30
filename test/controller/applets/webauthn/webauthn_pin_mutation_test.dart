import 'dart:async';

import 'package:canokey_console/controller/applets/webauthn/webauthn_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/utils/card_session.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/webauthn_card.dart';
import 'package:canokey_console/helper/widgets/input_pin_dialog.dart';
import 'package:canokey_console/views/applets/webauthn/dialogs/force_pin_change_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Client extends WebAuthnCardClient {
  bool failReadback = false, loseWriteReply = false;
  int reads = 0, sets = 0;
  int? failReadAt;
  bool installed = true, force = false;
  final pins = <String>[];
  final sessions = <_Session>[];
  late CardLease operationLease;
  @override
  Future<WebAuthnInfo> getInfo() async {
    reads++;
    if (reads == failReadAt || (failReadback && reads == 2)) {
      throw StateError('readback failed');
    }
    return WebAuthnInfo(
      clientPin: installed,
      credMgmt: true,
      forcePinChange: force,
      minPinLength: 4,
      alwaysUv: false,
      pinUvAuthProtocols: [2],
    );
  }

  @override
  Future<WebAuthnPinSession> beginPinSession(WebAuthnInfo info) async {
    operationLease = SmartCard.currentLease;
    final session = _Session(this);
    sessions.add(session);
    return session;
  }
}

class _Session extends Fake implements WebAuthnPinSession {
  _Session(this.client);
  final _Client client;
  bool closed = false;
  @override
  Future<void> changePin(String currentPin, String newPin) async {
    client.operationLease.check();
    client.pins.add(currentPin);
    client.force = false;
    if (client.loseWriteReply) {
      throw PlatformException(code: '500', message: 'write reply lost');
    }
  }

  @override
  Future<void> setPin(String pin) async {
    client.sets++;
    client.installed = true;
    if (client.loseWriteReply) {
      throw PlatformException(code: '500', message: 'write reply lost');
    }
  }

  @override
  Future<WebAuthnPinToken> getPinToken(
    String pin, {
    int permissions = WebAuthnCardClient.permissionCredentialManagement,
    String? rpId,
  }) async {
    throw StateError('terminal token operation failure');
  }

  @override
  void close() => closed = true;
}

class _ConfigController extends WebAuthnController {
  _ConfigController(_Client client) : super(client: client);
  @override
  bool get supportsConfig => true;
}

void main() {
  setUp(() async {
    Get.testMode = true;
    SmartCard.connectionType = ConnectionType.ccid;
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    await LocalStorage.setPinCache('', 'webauthn', '1234');
  });
  tearDown(() {
    Prompts.dismissTransientPrompt();
    SmartCard.connectionType = ConnectionType.none;
    Get.reset();
  });
  for (final mode in ['token', 'set', 'force', 'set_lost', 'force_lost']) {
    testWidgets(
      '$mode input settles parent and never retries a committed PIN',
      (tester) async {
        await LocalStorage.setPinCache('', 'webauthn', null);
        await tester.pumpWidget(_app());
        final isSet = mode.startsWith('set');
        final isForce = mode.startsWith('force');
        final lost = mode.endsWith('_lost');
        final client = _Client()
          ..installed = !isSet
          ..force = isForce
          ..loseWriteReply = lost
          ..failReadAt = mode == 'token' || lost ? null : 3;
        final c = _ConfigController(client);
        final operation = c.toggleAlwaysUv();
        final settled = mode == 'token' || lost
            ? expectLater(operation, throwsStateError)
            : expectLater(operation, completion(isFalse));
        await tester.pumpAndSettle();
        if (isForce) {
          expect(find.byType(ForcePinChangeDialog), findsOneWidget);
          await tester.enterText(find.byType(TextFormField).at(0), '1234');
          await tester.enterText(find.byType(TextFormField).at(1), '5678');
          await tester.enterText(find.byType(TextFormField).at(2), '5678');
          await tester.tap(find.text(S.current.save));
        } else {
          expect(find.byType(InputPinDialog), findsOneWidget);
          await tester.enterText(find.byType(TextFormField).at(0), '5678');
          if (isSet) {
            await tester.enterText(find.byType(TextFormField).at(1), '5678');
          }
          await tester.tap(find.text(S.current.confirm));
        }
        await tester.pumpAndSettle();
        await settled;
        expect(find.byType(InputPinDialog), findsNothing);
        expect(find.byType(ForcePinChangeDialog), findsNothing);
        if (mode != 'token' && !lost) {
          expect(
            find.text(S.current.operationSavedRefreshFailed),
            findsOneWidget,
          );
          expect(client.sets, mode == 'set' ? 1 : 0);
          expect(client.pins, mode == 'force' ? ['1234'] : isEmpty);
        }
        if (lost) {
          expect(LocalStorage.getPinCache('', 'webauthn'), isNull);
          expect(client.sets, isSet ? 1 : 0);
          expect(client.pins.length, isForce ? 1 : 0);
        }
        // A terminal prompt must release the global session queue.
        var nextStarted = false;
        await SmartCard.process((_) async {
          nextStarted = true;
        });
        expect(nextStarted, isTrue);
        expect(client.sessions.every((session) => session.closed), isTrue);
        c.onClose();
      },
    );
  }
  for (final save in [false, true]) {
    testWidgets('PIN commits before failed readback; saved=$save', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      unawaited(Get.dialog(const Dialog(child: Text('change PIN'))));
      await tester.pumpAndSettle();
      final client = _Client()..failReadback = true;
      final c = WebAuthnController(client: client)..polled = true;
      await tester.runAsync(() => c.changePin('5678', save));
      await tester.pumpAndSettle();
      expect(client.pins, ['1234']);
      expect(client.sessions.single.closed, isTrue);
      expect(c.polled, isFalse);
      expect(LocalStorage.getPinCache('', 'webauthn'), save ? '5678' : null);
      expect(find.text(S.current.operationSavedRefreshFailed), findsOneWidget);
      // A later operation must use the committed new PIN even without saving.
      client.failReadback = false;
      unawaited(Get.dialog(const Dialog(child: Text('change again'))));
      await tester.pumpAndSettle();
      await tester.runAsync(() => c.changePin('9012', false));
      expect(client.pins, ['1234', '5678']);
      expect(client.sessions.every((session) => session.closed), isTrue);
      c.onClose();
    });
  }
  testWidgets('lost write reply invalidates the old PIN without replay', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final client = _Client()..loseWriteReply = true;
    final c = WebAuthnController(client: client);
    await tester.runAsync(
      () => expectLater(c.changePin('5678', false), throwsStateError),
    );
    expect(LocalStorage.getPinCache('', 'webauthn'), isNull);
    await tester.runAsync(() => c.changePin('9012', false));
    expect(client.pins, ['1234']);
    expect(client.sessions.single.closed, isTrue);
    expect(client.operationLease.check, throwsStateError);
    c.onClose();
  });
}

Widget _app() => GetMaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: const Scaffold(),
);
