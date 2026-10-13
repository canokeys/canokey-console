import 'package:canokey_console/controller/applets/webauthn/webauthn_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/utils/card_session.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/webauthn_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Controller extends WebAuthnController {
  _Controller(WebAuthnCardClient client) : super(client: client);
  @override
  bool get supportsConfig => true;
  @override
  Future<void> doRefreshData() async {
    // Reproduce the real refresh entry point's non-reentrant session boundary.
    await SmartCard.process((_) async {});
  }
}

class _Client extends WebAuthnCardClient {
  bool uv = false, force = false;
  int minimum = 4, reads = 0;
  bool failReadback = false, failWrite = false;
  late CardLease configLease;
  late _Token token;

  @override
  Future<WebAuthnInfo> getInfo() async {
    if (reads++ == 0) {
      configLease = SmartCard.currentLease;
    } else {
      expect(identical(configLease, SmartCard.currentLease), isTrue);
      expect(token.closed, isTrue);
      if (failReadback) throw StateError('Read failed after successful write');
    }
    configLease.check();
    return WebAuthnInfo(
      credMgmt: true,
      clientPin: true,
      forcePinChange: force,
      minPinLength: minimum,
      alwaysUv: uv,
      pinUvAuthProtocols: [2],
    );
  }

  @override
  Future<WebAuthnPinSession> beginPinSession(WebAuthnInfo info) async {
    token = _Token(this);
    return _PinSession(token);
  }
}

class _PinSession extends Fake implements WebAuthnPinSession {
  _PinSession(this.token);
  final _Token token;
  @override
  Future<WebAuthnPinToken> getPinToken(
    String pin, {
    int permissions = WebAuthnCardClient.permissionCredentialManagement,
    String? rpId,
  }) async {
    expect(permissions, WebAuthnCardClient.permissionAuthenticatorConfig);
    return token;
  }

  @override
  void close() {}
}

class _Token extends Fake implements WebAuthnPinToken {
  _Token(this.client);
  final _Client client;
  bool closed = false;
  void check() {
    expect(identical(SmartCard.currentLease, client.configLease), isTrue);
    if (client.failWrite) throw StateError('Write failed');
  }

  @override
  Future<void> toggleAlwaysUv() async {
    check();
    client.uv = !client.uv;
  }

  @override
  Future<void> setMinPinLength(int minimum, {bool? forcePinChange}) async {
    check();
    client.minimum = minimum;
    client.force = forcePinChange ?? false;
  }

  @override
  Future<void> enableLongTouchForReset() async {
    check();
  }

  @override
  void close() {
    closed = true;
  }
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

  for (final operation in ['uv', 'pin', 'reset']) {
    testWidgets('$operation config re-reads state on the existing session', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      final client = _Client();
      final controller = _Controller(client);
      final result = await tester.runAsync(
        () async => switch (operation) {
          'uv' => await controller.toggleAlwaysUv(),
          'pin' => await controller.setMinPinLength(8, true),
          _ => await controller.enableLongTouchForReset(),
        },
      );
      expect(result, isTrue);
      expect(client.reads, 2);
      expect(client.token.closed, isTrue);
      expect(controller.alwaysUv, operation == 'uv');
      expect(controller.minPinLength, operation == 'pin' ? 8 : 4);
      expect(client.force, operation == 'pin');
      expect(client.configLease.check, throwsStateError);
      await tester.pump();
      expect(find.text(S.current.successfullyChanged), findsOneWidget);
    });
  }

  testWidgets('readback failure preserves write success and warns explicitly', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final client = _Client()..failReadback = true;
    final controller = _Controller(client);
    expect(await tester.runAsync(controller.toggleAlwaysUv), isTrue);
    expect(client.uv, isTrue);
    expect(controller.hasConfigInfo, isFalse);
    expect(client.token.closed, isTrue);
    await tester.pump();
    expect(find.text(S.current.webauthnConfigRefreshFailed), findsOneWidget);
    expect(find.text(S.current.successfullyChanged), findsNothing);
  });

  testWidgets('write failure closes token without publishing success', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final client = _Client()..failWrite = true;
    await tester.runAsync(() async {
      await expectLater(_Controller(client).toggleAlwaysUv(), throwsStateError);
    });
    expect(client.uv, isFalse);
    expect(client.reads, 1);
    expect(client.token.closed, isTrue);
    expect(find.text(S.current.successfullyChanged), findsNothing);
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
  home: const Scaffold(body: SizedBox.shrink()),
);
