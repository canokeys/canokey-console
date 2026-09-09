import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:canokey_console/views/applets/piv/widgets/piv_slot_list_item.dart';
import 'package:canokey_console/views/applets/piv/widgets/piv_slot_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SlotInfo slot(int id) => SlotInfo(
    id,
    AlgorithmType.mldsa65,
    PinPolicy.once,
    TouchPolicy.always,
    Origin.generated,
    const [],
    false,
    0,
    0,
  );
  Widget app({
    double width = 600,
    Locale locale = const Locale('en'),
    Brightness brightness = Brightness.light,
    void Function(String, String, SlotInfo?)? onOpen,
    VoidCallback? onSetupMac,
  }) => MaterialApp(
    locale: locale,
    theme: ThemeData(brightness: brightness),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: width,
          child: PivSlotManager(
            slots: {0x9A: slot(0x9A), 0x9C: slot(0x9C), 0x82: slot(0x82)},
            retiredSlots: [for (var i = 0x82; i <= 0x95; i++) i],
            hasCertificate: (id) => {0x9A, 0x9D, 0x95}.contains(id),
            onOpenSlot: onOpen ?? (_, _, _) {},
            onSetupMac: onSetupMac,
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'retired slots start collapsed, count keys and certificates, and open on tap',
    (tester) async {
      String? opened;
      await tester.pumpWidget(app(onOpen: (_, number, _) => opened = number));
      await tester.pumpAndSettle();
      expect(find.byType(PivSlotListItem), findsNWidgets(4));
      expect(find.text('2 occupied'), findsOneWidget);
      await tester.tap(find.text(S.current.pivRetiredSlots));
      await tester.pumpAndSettle();
      expect(find.byType(PivSlotListItem), findsNWidgets(24));
      await tester.ensureVisible(find.text('95'));
      await tester.tap(find.text('95'));
      expect(opened, '95');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Chinese dark narrow layout exposes all four distinct slot states',
    (tester) async {
      await tester.pumpWidget(
        app(
          width: 280,
          locale: const Locale('zh', 'Hans'),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(S.current.pivSlotKeyAndCertificate), findsOneWidget);
      expect(find.text(S.current.pivSlotKeyOnly), findsOneWidget);
      expect(find.text(S.current.pivSlotCertificateOnly), findsOneWidget);
      expect(find.text(S.current.pivEmpty), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'independent Mac setup button is visible without expanding slots',
    (tester) async {
      var opened = false;
      await tester.pumpWidget(app(onSetupMac: () => opened = true));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.current.pivMacSetupTitle));
      expect(opened, isTrue);
      expect(find.byType(PivSlotListItem), findsNWidgets(4));
    },
  );
}
