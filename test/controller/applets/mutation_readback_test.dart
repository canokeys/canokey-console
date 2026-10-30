import 'dart:async';
import 'dart:typed_data';

import 'package:canokey_console/controller/base/polling_controller.dart';
import 'package:canokey_console/controller/applets/oath/oath_controller.dart';
import 'package:canokey_console/controller/applets/openpgp/openpgp_controller.dart';
import 'package:canokey_console/controller/applets/pass/pass_controller.dart';
import 'package:canokey_console/controller/applets/settings/settings_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/admin_card.dart';
import 'package:canokey_console/helper/utils/card_session.dart';
import 'package:canokey_console/helper/utils/oath_card.dart';
import 'package:canokey_console/helper/utils/openpgp_card.dart';
import 'package:canokey_console/helper/utils/pass_card.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Writes {
  _Writes(this.reject);
  final bool reject;
  int writes = 0, reads = 0;
  late CardLease lease;
  void write() {
    writes++;
    lease = SmartCard.currentLease;
    if (reject) throw StateError('write failed');
  }

  Never read() {
    reads++;
    if (!identical(lease, SmartCard.currentLease)) {
      throw StateError('new session');
    }
    lease.check();
    throw StateError('readback interrupted after committed write');
  }
}

class _Oath extends OathCardClient {
  _Oath(this.w);
  final _Writes w;
  final calculation = Completer<(int, int)>();
  int calculations = 0;
  @override
  Future<(int, int)> calculate({
    required String name,
    required OathType type,
    String? challengeHex,
    Uint8List? key,
  }) {
    calculations++;
    return calculation.future;
  }

  @override
  Future<void> prepare() async {}
  @override
  Future<OathSelection> select() async =>
      const OathSelection(version: OathVersion.legacy, requiresCode: false);
  @override
  Future<void> delete(String name, {Uint8List? key}) async => w.write();
  @override
  Future<List<OathCalculatedEntry>> calculateAll(
    String challengeHex, {
    Uint8List? key,
  }) async => w.read();
}

class _Pgp extends OpenPgpCardClient {
  _Pgp(this.w);
  final _Writes w;
  @override
  Future<void> prepare() async {}
  @override
  Future<bool> changeUserPin(String oldPin, String newPin) async {
    w.write();
    return true;
  }

  @override
  Future<OpenPgpCardInfo> readCardInfo() async => w.read();
}

class _Pass extends PassCardClient {
  _Pass(this.w);
  final _Writes w;
  @override
  Future<void> prepare() async {}
  @override
  Future<bool> setSlot(
    int index,
    PassSlotType type,
    String password,
    bool withEnter, {
    required String pin,
  }) async {
    w.write();
    return true;
  }

  @override
  Future<List<PassSlot>> readSlots({String? pin}) async => w.read();
}

class _PassController extends PassController {
  _PassController(_Pass client) : super(client: client);
  @override
  Future<bool> authenticate(String sn) async => true;
  @override
  String get adminPinForCurrentLease => '123456';
}

class _Admin extends AdminCardClient {
  _Admin(this.w);
  final _Writes w;
  final events = <String>[];
  bool disabled = false;
  @override
  Future<void> setNfcEnabled(bool enabled, {required String pin}) async {
    events.add("nfc");
    w.write();
    disabled = !enabled;
  }

  @override
  Future<void> prepare() async {
    if (disabled) throw StateError("read after disabling NFC");
    events.add("prepare");
  }

  @override
  Future<void> prepareIfStale() async {}
  @override
  Future<void> configure({
    required String pin,
    bool? ledOn,
    bool? ndefReadOnly,
    bool? ndefEnabled,
    bool? webusbLanding,
    int featureMask = 0,
    int featureValues = 0,
  }) async {
    events.add("configure");
    w.write();
  }

  @override
  Future<String> readFirmwareVersion() async => w.read();
}

class _Settings extends SettingsController {
  _Settings(_Admin client, {this.nfc = false}) : super(client: client);
  final bool nfc;
  @override
  Future<bool> authenticate(String sn) async {
    if (nfc) SmartCard.connectionType = ConnectionType.nfc;
    return true;
  }

  @override
  String get adminPinForCurrentLease => '123456';
}

void main() {
  setUp(() {
    Get.testMode = true;
    SmartCard.connectionType = ConnectionType.ccid;
  });
  tearDown(() {
    Prompts.dismissTransientPrompt();
    SmartCard.connectionType = ConnectionType.none;
    Get.reset();
  });
  test(
    'concurrent HOTP taps share one calculation and one counter advance',
    () async {
      final client = _Oath(_Writes(false));
      final c = OathController(client: client);
      c.oathMap['entry'] = OathItem('', 'entry')..type = OathType.hotp;
      final first = c.calculate('entry', OathType.hotp);
      final second = c.calculate('entry', OathType.hotp);
      expect(identical(first, second), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(client.calculations, 1);
      client.calculation.complete((6, 123456));
      expect(await first, '123456');
      expect(await second, '123456');
      expect(c.isCalculating('entry'), isFalse);
      c.onClose();
    },
  );
  testWidgets('NFC disable is last and has no dependent read', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: const Scaffold(),
      ),
    );
    unawaited(Get.dialog(const Dialog(child: Text('edit'))));
    await tester.pumpAndSettle();
    final w = _Writes(false);
    final client = _Admin(w);
    final c = _Settings(client, nfc: true)..polled = true;
    await tester.runAsync(
      () => c.changeSwitches({Func.nfcSwitch: false, Func.led: true}),
    );
    await tester.pumpAndSettle();
    expect(client.events.last, 'nfc');
    expect(
      client.events.indexOf('configure'),
      lessThan(client.events.indexOf('nfc')),
    );
    expect(w.reads, 0);
    expect(w.writes, 2);
    expect(c.polled, isFalse);
    expect(find.text(S.current.successfullyChanged), findsOneWidget);
    c.onClose();
  });
  for (final applet in ['OATH', 'OpenPGP', 'Pass', 'Settings']) {
    for (final reject in [false, true]) {
      testWidgets(
        '$applet distinguishes write failure from readback failure ($reject)',
        (tester) async {
          await tester.pumpWidget(
            GetMaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
              home: const Scaffold(),
            ),
          );
          unawaited(Get.dialog(const Dialog(child: Text('edit'))));
          await tester.pumpAndSettle();
          final w = _Writes(reject);
          late PollingController controller;
          late Future<void> Function() mutate;
          switch (applet) {
            case 'OATH':
              final c = OathController(client: _Oath(w));
              controller = c;
              mutate = () => c.delete('entry');
            case 'OpenPGP':
              final c = OpenPgpController(client: _Pgp(w));
              controller = c;
              mutate = () => c.changeUserPin('123456', '654321');
            case 'Pass':
              final c = _PassController(_Pass(w));
              controller = c;
              mutate = () =>
                  c.setSlot(1, PassSlotType.static, 'password', false);
            case 'Settings':
              final c = _Settings(_Admin(w));
              controller = c;
              mutate = () => c.changeSwitch(Func.led, true);
          }
          controller.polled = true;
          if (reject) {
            await tester.runAsync(
              () => expectLater(mutate(), throwsStateError),
            );
            expect(w.reads, 0);
            expect(find.text('edit'), findsOneWidget);
          } else {
            await tester.runAsync(mutate);
            await tester.pumpAndSettle();
            expect(w.reads, 1);
            expect(controller.polled, isFalse);
            expect(find.text('edit'), findsNothing);
            expect(
              find.text(S.current.operationSavedRefreshFailed),
              findsOneWidget,
            );
          }
          expect(w.writes, 1, reason: 'Never replay a mutation');
          expect(w.lease.check, throwsStateError);
          controller.onClose();
        },
      );
    }
  }
}
