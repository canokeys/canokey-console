import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/models/ndef.dart';
import 'package:canokey_console/views/applets/ndef/dialogs/ndef_record_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('record type selector shows the seven user-facing types',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byType(PopupMenuButton<NdefEditableRecordType>),
      findsOneWidget,
    );
    final typeMenu = tester.widget<PopupMenuButton<NdefEditableRecordType>>(
      find.byType(PopupMenuButton<NdefEditableRecordType>),
    );
    expect(typeMenu.color?.a, 1);

    await tester.tap(
      find.byType(PopupMenuButton<NdefEditableRecordType>),
    );
    await tester.pumpAndSettle();

    final menuScrollView = find.byType(Scrollable).last;
    expect(tester.getSize(menuScrollView).height, lessThanOrEqualTo(320));

    for (final label in const [
      'URI',
      'Text',
      'Phone',
      'Contact',
      'Wi-Fi',
      'AAR',
      'Other',
    ]) {
      expect(find.text(label), findsAtLeast(1));
    }
    for (final removedLabel in const [
      'Smart Poster',
      'MIME',
      'Bluetooth Classic',
      'Signature',
    ]) {
      expect(find.text(removedLabel), findsNothing);
    }
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Contact').last);
    await tester.pumpAndSettle();

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Email (optional)'), findsOneWidget);
    expect(find.text('Organization (optional)'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
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
    home: const NdefRecordDialog(defaultLanguage: 'en'),
  );
}
