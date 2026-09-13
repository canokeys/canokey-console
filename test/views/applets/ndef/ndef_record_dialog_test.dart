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

  for (final locale in const [
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ]) {
    testWidgets('record types and contact fields use $locale on mobile', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_app(locale));
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

      await tester.tap(find.byType(PopupMenuButton<NdefEditableRecordType>));
      await tester.pumpAndSettle();

      final menuScrollView = find.byType(Scrollable).last;
      expect(tester.getSize(menuScrollView).height, lessThanOrEqualTo(320));

      for (final label in [
        S.current.ndefUri,
        S.current.ndefText,
        S.current.ndefPhone,
        S.current.ndefContact,
        S.current.ndefWifi,
        S.current.ndefAndroidApplication,
        S.current.ndefOther,
      ]) {
        expect(find.text(label), findsAtLeast(1));
      }
      for (final removedLabel in [
        S.current.ndefSmartPoster,
        S.current.ndefMime,
        S.current.ndefBluetoothClassic,
        S.current.ndefSignature,
      ]) {
        expect(find.text(removedLabel), findsNothing);
      }
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(S.current.ndefContact).last);
      await tester.pumpAndSettle();

      expect(find.text(S.current.ndefContactName), findsOneWidget);
      expect(find.text(S.current.ndefPhoneNumber), findsOneWidget);
      expect(find.text(S.current.ndefContactEmail), findsOneWidget);
      expect(find.text(S.current.ndefContactOrganization), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

Widget _app(Locale locale) {
  return GetMaterialApp(
    locale: locale,
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
