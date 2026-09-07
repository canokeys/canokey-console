import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/models/webauthn.dart';
import 'package:canokey_console/views/applets/webauthn/dialogs/sm2_config_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  for (final legacy in [false, true]) {
    testWidgets(
        'SM2 dialog validates fields and enabled state (legacy=$legacy)',
        (tester) async {
      final submissions = <(bool, int, int)>[];
      await tester.pumpWidget(GetMaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
            body: Sm2ConfigDialog(
          config: WebAuthnSm2Config(
              enabled: false,
              curveId: 9,
              algoId: -54,
              canChangeEnabled: legacy),
          canChangeEnabled: legacy,
          onConfirm: (enabled, curve, algorithm) =>
              submissions.add((enabled, curve, algorithm)),
        )),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(Checkbox), legacy ? findsOneWidget : findsNothing);
      final fields = find.byType(TextFormField);
      for (final index in [0, 1]) {
        await tester.enterText(fields.at(index), '');
        await tester.tap(find.text(S.current.save));
        await tester.pumpAndSettle();
        expect(submissions, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.enterText(fields.at(index), index == 0 ? '9' : '-54');
      }
      await tester.enterText(fields.at(0), '-2147483648');
      await tester.enterText(fields.at(1), '2147483647');
      await tester.tap(find.text(S.current.save));
      await tester.pumpAndSettle();
      expect(submissions, [(!legacy, -2147483648, 2147483647)]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
