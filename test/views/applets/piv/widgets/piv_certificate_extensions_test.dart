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
    double textScale = 1,
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
      body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) =>
                PivCertificateExtensions(options: options, onChanged: setState),
          ),
        ),
      ),
    ),
  );

  testWidgets('all slots show certificate controls without a Mac preset', (
    tester,
  ) async {
    for (final slot in ['9A', '9C', '9D', '9E']) {
      final options = PivSelfSignOptions(
        slotNumber: slot,
        pinPolicy: PinPolicy.never,
      )..algorithm = AlgorithmType.ed25519;
      await tester.pumpWidget(app(options));
      await tester.pumpAndSettle();
      expect(find.text(S.current.pivMacOsApply), findsNothing);
      expect(find.text(S.current.pivMacOsDescription), findsNothing);
      expect(find.text(S.current.pivMacOsKeychainDescription), findsNothing);
      expect(find.text(S.current.pivMacOsOtherSlot), findsNothing);
      expect(find.text(S.current.pivCertificateExtensions), findsOneWidget);
      expect(options.algorithm, AlgorithmType.ed25519);
      expect(options.pinPolicy, PinPolicy.never);
    }
  });

  testWidgets(
    'critical can be changed before selecting usages and retains the choice',
    (tester) async {
      final options = PivSelfSignOptions(
        slotNumber: '9C',
        pinPolicy: PinPolicy.once,
      );
      await tester.pumpWidget(app(options));
      await tester.pumpAndSettle();
      expect(options.keyUsage, 0);
      await tester.tap(find.text(S.current.pivKeyUsageCritical));
      await tester.pumpAndSettle();
      expect(options.keyUsageCritical, isFalse);
      expect(options.keyUsage, 0);
      await tester.tap(find.text(S.current.pivUsageDigitalSignature));
      await tester.pumpAndSettle();
      expect(options.keyUsage, 1);
      expect(options.keyUsageCritical, isFalse);
      await tester.tap(find.text(S.current.pivKeyUsageCritical));
      await tester.tap(find.text(S.current.pivUsageDigitalSignature));
      await tester.pumpAndSettle();
      expect(options.keyUsage, 0);
      expect(options.keyUsageCritical, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('constraints and EKU labels are interactive', (tester) async {
    final options = PivSelfSignOptions(
      slotNumber: '9D',
      pinPolicy: PinPolicy.once,
    );
    await tester.pumpWidget(app(options));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.pivEndEntityConstraint));
    await tester.tap(find.text(S.current.pivUsageClientAuth));
    await tester.pumpAndSettle();
    expect(options.includeBasicConstraints, isTrue);
    expect(options.extendedKeyUsage, {PivSelfSignOptions.clientAuth});
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Chinese controls remain usable on narrow screens with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final options = PivSelfSignOptions(
        slotNumber: '9A',
        pinPolicy: PinPolicy.once,
      );
      await tester.pumpWidget(
        app(options, locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'), textScale: 1.5),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(S.current.pivKeyUsageCritical));
      await tester.tap(find.text(S.current.pivKeyUsageCritical));
      await tester.pumpAndSettle();
      expect(options.keyUsageCritical, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
