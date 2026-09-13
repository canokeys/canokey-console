import 'package:canokey_console/controller/applets/pass/pass_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:canokey_console/views/applets/pass/pass_page.dart';
import 'package:canokey_console/views/applets/pass/dialogs/slot_config_dialog.dart';
import 'package:canokey_console/views/applets/pass/widgets/slot_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Controller extends PassController {
  @override
  void onReady() {}
}

void main() {
  setUp(() {
    Get.testMode = true;
  });
  tearDown(Get.reset);

  testWidgets('slot cards and configuration fit desktop and mobile', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    Get.put<PassController>(
      _Controller()
        ..polled = true
        ..hmacSha1Supported = true,
    );
    for (final (size, dark, scale) in [
      (const Size(1536, 1000), false, 1.0),
      (const Size(390, 844), true, 1.0),
      (const Size(320, 844), false, 2.0),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(_app(const PassPage(), dark: dark, scale: scale));
      await tester.pumpAndSettle();
      expect(find.byType(SlotCard), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(S.current.passStatus).first);
      await tester.pumpAndSettle();
      expect(find.byType(SlotConfigDialog), findsOneWidget);
      expect(find.byType(RadioListTile<PassSlotType>), findsNWidgets(3));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text(S.current.cancel));
      await tester.tap(find.text(S.current.cancel));
      await tester.pumpAndSettle();
      expect(find.byType(SlotConfigDialog), findsNothing);
    }
  });

  testWidgets(
    'static passwords validate and preserve slot index and Enter setting',
    (tester) async {
      final submissions = <(int, PassSlotType, String, bool)>[];
      await tester.pumpWidget(
        _app(
          SlotConfigDialog(
            index: 2,
            slot: PassSlot.empty(),
            hmacSha1Supported: true,
            onSetSlot: (index, type, secret, enter) =>
                submissions.add((index, type, secret, enter)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.current.passSlotStatic));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(S.current.save));
      await tester.tap(find.text(S.current.save));
      await tester.pumpAndSettle();
      expect(submissions, isEmpty);
      await tester.enterText(find.byType(TextFormField), 'valid password');
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(S.current.save));
      await tester.tap(find.text(S.current.save));
      await tester.pump();
      expect(submissions, [(2, PassSlotType.static, 'valid password', true)]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('HMAC-SHA1 validates and normalizes the key without Enter', (
    tester,
  ) async {
    final submissions = <(int, PassSlotType, String, bool)>[];
    await tester.pumpWidget(
      _app(
        SlotConfigDialog(
          index: 1,
          slot: PassSlot(type: PassSlotType.static, name: '', withEnter: true),
          hmacSha1Supported: true,
          onSetSlot: (index, type, secret, enter) =>
              submissions.add((index, type, secret, enter)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.passSlotHmacSha1));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'invalid');
    await tester.ensureVisible(find.text(S.current.save));
    await tester.tap(find.text(S.current.save));
    await tester.pumpAndSettle();
    expect(submissions, isEmpty);
    final key = 'AB' * 20;
    await tester.enterText(find.byType(TextFormField), key);
    await tester.ensureVisible(find.text(S.current.save));
    await tester.tap(find.text(S.current.save));
    await tester.pump();
    expect(submissions, [(1, PassSlotType.hmacSha1, key.toLowerCase(), false)]);
    expect(find.byType(Checkbox), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('older firmware omits HMAC-SHA1 and can disable a slot', (
    tester,
  ) async {
    PassSlotType? saved;
    await tester.pumpWidget(
      _app(
        SlotConfigDialog(
          index: 1,
          slot: PassSlot.empty(),
          hmacSha1Supported: false,
          onSetSlot: (_, type, secret, enter) => saved = type,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(S.current.passSlotHmacSha1), findsNothing);
    await tester.ensureVisible(find.text(S.current.save));
    await tester.tap(find.text(S.current.save));
    await tester.pump();
    expect(saved, PassSlotType.none);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget child, {bool dark = false, double scale = 1}) =>
    GetMaterialApp(
      theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
      locale: const Locale('en'),
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
      home: child,
    );
