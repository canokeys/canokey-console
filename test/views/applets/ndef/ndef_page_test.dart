import 'package:canokey_console/helper/theme/app_theme.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:canokey_console/controller/applets/ndef/ndef_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/models/ndef.dart';
import 'package:canokey_console/views/applets/ndef/ndef_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ndef/ndef.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('empty and read-only states retain safe edit and save controls', (
    tester,
  ) async {
    _setTestSize(tester, const Size(1536, 1000));
    final controller = _TestNdefController()..polled = true;
    Get.put<NdefController>(controller);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text(S.current.ndefNoRecords), findsOneWidget);
    expect(find.text(S.current.ndefWritable), findsOneWidget);
    expect(_button(tester, S.current.ndefAddRecord).onPressed, isNotNull);
    expect(_button(tester, S.current.ndefSaveToKey).onPressed, isNull);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0,
    );
    controller.addRecord(NdefDocument.textRecord('Hello', language: 'en'));
    await tester.pumpAndSettle();
    expect(_button(tester, S.current.ndefSaveToKey).onPressed, isNotNull);
    controller.readOnly = true;
    controller.update();
    await tester.pumpAndSettle();
    expect(find.text(S.current.ndefReadOnlyStatus), findsOneWidget);
    expect(find.text(S.current.ndefReadOnlyDescription), findsOneWidget);
    expect(_button(tester, S.current.ndefAddRecord).onPressed, isNull);
    expect(_button(tester, S.current.ndefSaveToKey).onPressed, isNull);
    expect(tester.takeException(), isNull);
    await _disposePage(tester);
  });

  testWidgets('capacity and decoding failures disable saving', (tester) async {
    _setTestSize(tester, const Size(1280, 1000));
    final controller = _configuredController()
      ..dirty = true
      ..maxMessageLength = 1;
    Get.put<NdefController>(controller);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text(S.current.ndefCapacityExceeded), findsOneWidget);
    expect(_button(tester, S.current.ndefSaveToKey).onPressed, isNull);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      1,
    );
    controller.maxMessageLength = 1022;
    controller.decodeError = S.current.ndefInvalidMessage;
    controller.update();
    await tester.pumpAndSettle();
    expect(find.text(S.current.ndefInvalidMessage), findsOneWidget);
    expect(_button(tester, S.current.ndefAddRecord).onPressed, isNull);
    expect(_button(tester, S.current.ndefSaveToKey).onPressed, isNull);
    expect(tester.takeException(), isNull);
    await _disposePage(tester);
  });

  testWidgets(
    'overview and records fit narrow screens with large text in both themes',
    (tester) async {
      _setTestSize(tester, const Size(320, 1000));
      final controller = _TestNdefController()..polled = true;
      Get.put<NdefController>(controller);
      for (final dark in [false, true]) {
        await tester.pumpWidget(_app(dark: dark, scale: 2));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        controller.records = [
          NdefDocument.textRecord('Long record ' * 30, language: 'en'),
        ];
        controller.readOnly = true;
        controller.update();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text(S.current.ndefSaveToKey));
        expect(tester.takeException(), isNull);
        controller.records = [];
        controller.readOnly = false;
        controller.update();
      }
      await _disposePage(tester);
    },
  );

  testWidgets('renders configured records at desktop width', (tester) async {
    _setTestSize(tester, const Size(1280, 800));
    Get.put<NdefController>(_configuredController());
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.text('NFC tag content'), findsOneWidget);
    expect(find.text('https://canokeys.org'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('application/example'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _disposePage(tester);
  });

  testWidgets('renders compact record actions at mobile width', (tester) async {
    _setTestSize(tester, const Size(390, 844));
    Get.put<NdefController>(_configuredController());
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.byIcon(LucideIcons.moreHorizontal), findsNWidgets(3));
    expect(find.text('Save to CanoKey'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _disposePage(tester);
  });
}

void _setTestSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _disposePage(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await Get.delete<NdefController>(force: true);
}

NdefController _configuredController() {
  return _TestNdefController()
    ..polled = true
    ..records = [
      NdefDocument.uriRecord('https://canokeys.org'),
      NdefDocument.textRecord('Hello', language: 'en'),
      NDEFRecord(
        tnf: TypeNameFormat.media,
        type: Uint8List.fromList(utf8.encode('application/example')),
        payload: Uint8List.fromList([1, 2, 3]),
      ),
    ];
}

class _TestNdefController extends NdefController {
  @override
  void onReady() {}
}

FilledButton _button(WidgetTester tester, String label) =>
    tester.widget<FilledButton>(
      find.ancestor(of: find.text(label), matching: find.byType(FilledButton)),
    );

Widget _app({bool dark = false, double scale = 1}) {
  return GetMaterialApp(
    locale: const Locale('en'),
    theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: const NdefPage(),
  );
}
