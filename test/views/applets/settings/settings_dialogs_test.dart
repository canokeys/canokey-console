import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/utils/screenshot_mode.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/views/applets/settings/dialogs/language_dialog.dart';
import 'package:canokey_console/views/applets/settings/dialogs/applet_switches_dialog.dart';
import 'package:canokey_console/views/applets/settings/dialogs/switch_dialog.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });
  tearDown(Get.reset);

  testWidgets(
    'settings dialogs fit desktop, phone and large text in both themes',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final card = ScreenshotMode.canoKey();
      for (final (size, dark, scale) in [
        (const Size(1100, 900), false, 1.0),
        (const Size(390, 844), true, 1.0),
        (const Size(320, 640), false, 2.0),
      ]) {
        tester.view.physicalSize = size;
        for (final dialog in <Widget>[
          const LanguageDialog(),
          AppletSwitchesDialog(
            canokey: card,
            functionSet: card.getFunctionSet(),
            onConfirm: (_) async {},
          ),
          SwitchDialog(title: 'NFC', initialValue: true, onConfirm: (_) {}),
        ]) {
          await tester.pumpWidget(_app(dialog, dark: dark, scale: scale));
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(AppDialogHeader), findsOneWidget);
          await tester.ensureVisible(find.text(S.current.confirm));
          await tester.pumpAndSettle();
          expect(find.text(S.current.confirm).hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
          Get.back();
          await tester.pumpAndSettle();
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    },
  );

  testWidgets('applet selection is staged until confirmation', (tester) async {
    final card = ScreenshotMode.canoKey();
    Map<Func, bool>? submitted;
    await tester.pumpWidget(
      _app(
        AppletSwitchesDialog(
          canokey: card,
          functionSet: card.getFunctionSet(),
          onConfirm: (values) async {
            submitted = values;
          },
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(submitted, isNull);
    await tester.ensureVisible(find.text(S.current.confirm));
    await tester.tap(find.text(S.current.confirm));
    await tester.pump();
    expect(submitted, {Func.passSwitch: !card.passEnabled});
    Get.back();
    await tester.pumpAndSettle();
  });
}

Widget _app(Widget dialog, {bool dark = false, double scale = 1}) =>
    GetMaterialApp(
      theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
      locale: const Locale('zh', 'Hans'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => AppDialog.show(dialog),
            child: const Text('Open'),
          ),
        ),
      ),
    );
