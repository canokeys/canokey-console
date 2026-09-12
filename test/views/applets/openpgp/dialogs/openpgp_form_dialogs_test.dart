import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:canokey_console/views/applets/openpgp/dialogs/openpgp_pin_retries_dialog.dart';
import 'package:canokey_console/views/applets/openpgp/dialogs/openpgp_reset_code_dialog.dart';
import 'package:canokey_console/views/applets/openpgp/dialogs/openpgp_signature_pin_policy_dialog.dart';
import 'package:canokey_console/views/applets/openpgp/dialogs/openpgp_touch_cache_time_dialog.dart';
import 'package:canokey_console/views/applets/openpgp/dialogs/openpgp_touch_policy_dialog.dart';
import 'package:canokey_console/views/applets/openpgp/dialogs/openpgp_unblock_pin_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const _pinState = OpenPgpPinState(
  signaturePinForced: false,
  userRetries: 3,
  resetRetries: 3,
  adminRetries: 3,
);
const _slot = OpenPgpKeySlotInfo(
  type: OpenPgpKeyType.signature,
  fingerprint: null,
  generatedAt: null,
  touchPolicy: OpenPgpTouchPolicy.off,
  touchFixed: false,
);

void main() {
  setUpAll(AppTheme.init);
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  for (final kind in [
    'reset',
    'retries',
    'cache',
    'signature',
    'touch',
    'unblock',
  ]) {
    testWidgets(
      '$kind dialog retains validation, submission, errors and cancel',
      (tester) async {
        List<Object>? submitted;
        final dialog = switch (kind) {
          'reset' => OpenPgpResetCodeDialog(
            onSubmit: (pin, code) async {
              submitted = [pin, code];
            },
          ),
          'retries' => OpenPgpPinRetriesDialog(
            pinState: _pinState,
            onSubmit: (pin, user, reset, admin) async {
              submitted = [pin, user, reset, admin];
            },
          ),
          'cache' => OpenPgpTouchCacheTimeDialog(
            currentSeconds: 10,
            onSubmit: (pin, seconds) async {
              submitted = [pin, seconds];
            },
          ),
          'signature' => OpenPgpSignaturePinPolicyDialog(
            pinState: _pinState,
            onSubmit: (pin, policy) async {
              submitted = [pin, policy];
            },
          ),
          'touch' => OpenPgpTouchPolicyDialog(
            slot: _slot,
            onSubmit: (key, policy, pin) async {
              submitted = [key, policy, pin];
            },
          ),
          _ => OpenPgpUnblockPinDialog(
            onSubmitWithAdmin: (pin, value) async {
              submitted = [pin, value];
            },
            onSubmitWithResetCode: (_, _) async {
              fail('Unexpected recovery method');
            },
          ),
        };
        await _open(tester, dialog);
        await _tap(tester, S.current.confirm);
        expect(submitted, isNull);

        final inputs = switch (kind) {
          'reset' => ['12345678', '87654321'],
          'retries' => ['12345678', '5', '4', '2'],
          'cache' => ['12345678', '25'],
          'unblock' => ['12345678', '654321'],
          _ => ['12345678'],
        };
        for (var i = 0; i < inputs.length; i++) {
          final field = find.byType(TextFormField).at(i);
          await tester.ensureVisible(field);
          await tester.enterText(field, inputs[i]);
        }
        await _tap(tester, S.current.confirm);
        expect(submitted, switch (kind) {
          'reset' => ['12345678', '87654321'],
          'retries' => ['12345678', 5, 4, 2],
          'cache' => ['12345678', 25],
          'signature' => ['12345678', false],
          'touch' => [
            OpenPgpKeyType.signature,
            OpenPgpTouchPolicy.off,
            '12345678',
          ],
          _ => ['12345678', '654321'],
        });

        Get.find<RxString>(tag: 'dialog_error').value =
            'Device rejected operation';
        await tester.pump();
        expect(find.text('Device rejected operation'), findsOneWidget);
        await _tap(tester, S.current.cancel);
        expect(find.byType(dialog.runtimeType), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('permanent touch policy remains gated by explicit confirmation', (
    tester,
  ) async {
    OpenPgpTouchPolicy? submitted;
    await _open(
      tester,
      OpenPgpTouchPolicyDialog(
        slot: _slot,
        onSubmit: (_, policy, _) async {
          submitted = policy;
        },
      ),
    );
    await _tap(tester, OpenPgpTouchPolicy.permanent.label);
    final confirm = find.ancestor(
      of: find.text(S.current.confirm),
      matching: find.byType(CustomizedButton),
    );
    expect(tester.widget<CustomizedButton>(confirm).onPressed, isNull);
    await _tap(tester, S.current.openpgpPermanentTouchConfirmation);
    expect(tester.widget<CustomizedButton>(confirm).onPressed, isNotNull);
    final field = find.byType(TextFormField);
    await tester.ensureVisible(field);
    await tester.enterText(field, '12345678');
    await _tap(tester, S.current.confirm);
    expect(submitted, OpenPgpTouchPolicy.permanent);
    await _tap(tester, OpenPgpTouchPolicy.off.label);
    await _tap(tester, OpenPgpTouchPolicy.permanent.label);
    expect(tester.widget<CustomizedButton>(confirm).onPressed, isNull);
  });
}

Future<void> _tap(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, Widget dialog) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 900);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(1.4)),
        child: child!,
      ),
      home: Scaffold(
        body: TextButton(
          onPressed: () => AppDialog.show(dialog),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
