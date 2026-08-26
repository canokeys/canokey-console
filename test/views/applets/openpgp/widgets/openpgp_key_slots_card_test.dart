import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:canokey_console/views/applets/openpgp/widgets/openpgp_key_slots_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUpAll(AppTheme.init);

  OpenPgpCardInfo buildInfo() {
    OpenPgpKeySlotInfo slot(
      OpenPgpKeyType type, {
      String? fingerprint,
    }) {
      return OpenPgpKeySlotInfo(
        type: type,
        fingerprint: fingerprint,
        generatedAt: null,
        touchPolicy: OpenPgpTouchPolicy.off,
        touchFixed: false,
      );
    }

    return OpenPgpCardInfo(
      version: '',
      manufacturer: '',
      serialNumber: '',
      cardHolder: '',
      publicKeyUrl: '',
      pinState: const OpenPgpPinState(
        signaturePinForced: false,
        userRetries: null,
        resetRetries: null,
        adminRetries: null,
      ),
      keySlots: {
        OpenPgpKeyType.signature: slot(OpenPgpKeyType.signature),
        OpenPgpKeyType.encryption: slot(OpenPgpKeyType.encryption),
        OpenPgpKeyType.authentication: slot(
          OpenPgpKeyType.authentication,
          fingerprint: '0123456789ABCDEF0123456789ABCDEF01234567',
        ),
      },
      touchCacheTime: null,
    );
  }

  Widget buildCard(double width) {
    return GetMaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Material(
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: OpenPgpKeySlotsCard(info: buildInfo()),
          ),
        ),
      ),
    );
  }

  testWidgets('does not truncate key titles at card width', (tester) async {
    await tester.pumpWidget(buildCard(520));
    await tester.pumpAndSettle();

    final title = find.text('Authentication');
    expect(title, findsOneWidget);
    expect(
      tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
      false,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('wraps key details on narrow layouts', (tester) async {
    await tester.pumpWidget(buildCard(280));
    await tester.pumpAndSettle();

    expect(find.text('Authentication'), findsOneWidget);
    expect(find.text('Imported'), findsOneWidget);
    expect(find.text('Touch: Off'), findsNWidgets(3));
    expect(find.text('01234567...01234567'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
