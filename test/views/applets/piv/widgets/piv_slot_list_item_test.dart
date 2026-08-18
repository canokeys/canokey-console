import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:canokey_console/views/applets/piv/widgets/piv_slot_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(AppTheme.init);

  Widget buildItem({
    required double width,
    SlotInfo? slot,
  }) {
    return MaterialApp(
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
            child: PivSlotListItem(
              title: 'Card Authentication',
              slotNumber: '9E',
              slot: slot,
              hasCertificate: slot != null,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('does not truncate the slot title at card width', (tester) async {
    await tester.pumpWidget(buildItem(width: 520));
    await tester.pumpAndSettle();

    final title = find.text('Card Authentication - 9E');
    expect(title, findsOneWidget);
    expect(
        tester.renderObject<RenderParagraph>(title).didExceedMaxLines, false);
    expect(find.text('Empty'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wraps populated slot details on narrow layouts', (tester) async {
    final slot = SlotInfo(
      0x9E,
      AlgorithmType.rsa2048,
      PinPolicy.always,
      TouchPolicy.cached,
      Origin.generated,
      const [],
      false,
      3,
      3,
    );

    await tester.pumpWidget(buildItem(width: 280, slot: slot));
    await tester.pumpAndSettle();

    expect(find.text('Card Authentication - 9E'), findsOneWidget);
    expect(find.text('RSA2048'), findsOneWidget);
    expect(find.text('Certificate'), findsOneWidget);
    expect(find.text('PIN: Always'), findsOneWidget);
    expect(find.text('Touch: Cached for 15 seconds'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
