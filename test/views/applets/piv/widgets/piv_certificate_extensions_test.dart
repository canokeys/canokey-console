import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:canokey_console/models/piv_self_sign_options.dart';
import 'package:canokey_console/views/applets/piv/widgets/piv_certificate_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(
    PivSelfSignOptions options, {
    Locale locale = const Locale('en'),
  }) => MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: StatefulBuilder(
          builder: (context, setState) =>
              PivCertificateExtensions(options: options, onChanged: setState),
        ),
      ),
    ),
  );

  testWidgets('preset updates summary, expanded controls and custom state', (
    tester,
  ) async {
    final options = PivSelfSignOptions(
      slotNumber: '9A',
      pinPolicy: PinPolicy.never,
    )..algorithm = AlgorithmType.ed25519;
    await tester.pumpWidget(app(options));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.pivMacOsApply));
    await tester.pumpAndSettle();
    expect(find.text(S.current.pivMacOsSlotApplied('9A')), findsOneWidget);
    expect(find.textContaining('ECC P-256'), findsOneWidget);
    await tester.tap(find.text(S.current.pivCertificateExtensions));
    await tester.pumpAndSettle();
    final digitalSignature = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'digitalSignature'),
    );
    expect(digitalSignature.selected, isTrue);
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'clientAuth'))
          .selected,
      isTrue,
    );
    await tester.tap(find.text('contentCommitment'));
    await tester.pumpAndSettle();
    expect(find.text(S.current.pivCertificateCustom), findsOneWidget);
    expect(options.keyUsage, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'other slots explain the two-slot setup without a preset button',
    (tester) async {
      await tester.pumpWidget(
        app(PivSelfSignOptions(slotNumber: '9C', pinPolicy: PinPolicy.once)),
      );
      await tester.pumpAndSettle();
      expect(find.text(S.current.pivMacOsApply), findsNothing);
      expect(find.text(S.current.pivMacOsOtherSlot), findsOneWidget);
    },
  );

  testWidgets('9D preset selects key agreement and explains the role of 9A', (
    tester,
  ) async {
    final options = PivSelfSignOptions(
      slotNumber: '9D',
      pinPolicy: PinPolicy.once,
    );
    await tester.pumpWidget(app(options));
    await tester.pumpAndSettle();
    expect(find.text(S.current.pivMacOsKeychainDescription), findsOneWidget);
    await tester.tap(find.text(S.current.pivMacOsApply));
    await tester.pumpAndSettle();
    expect(find.text(S.current.pivMacOsSlotApplied('9D')), findsOneWidget);
    await tester.tap(find.text(S.current.pivCertificateExtensions));
    await tester.pumpAndSettle();
    for (final entry in {
      'keyAgreement': true,
      'digitalSignature': false,
      'clientAuth': false,
    }.entries) {
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, entry.key))
            .selected,
        entry.value,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Chinese expanded controls fit a narrow viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      app(
        PivSelfSignOptions(slotNumber: '9A', pinPolicy: PinPolicy.once),
        locale: const Locale('zh', 'Hans'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.pivMacOsApply));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.pivCertificateExtensions));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
