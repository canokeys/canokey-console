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

Widget _app() {
  return GetMaterialApp(
    locale: const Locale('en'),
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
