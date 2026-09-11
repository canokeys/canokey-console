import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/views/applets/piv/widgets/piv_macos_setup_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../controller/applets/piv/piv_macos_setup_test.dart'
    show SetupController, entry;

void main() {
  Widget app(SetupController c) => MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Scaffold(body: PivMacOsSetupDialog(controller: c)),
  );
  testWidgets(
    'opening only inspects; configure preserves 9A and completes 9D',
    (tester) async {
      final c = SetupController([
        entry('9A', key: true, cert: true, compatible: true),
        entry('9D'),
      ])..pinOnlyMode = true;
      await tester.pumpWidget(app(c));
      await tester.pumpAndSettle();
      expect(c.writes, isEmpty);
      expect(find.text(S.current.pivMacSetupKeep), findsOneWidget);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text(S.current.pivMacSetupStart));
      await tester.pumpAndSettle();
      expect(c.writes, ['9D']);
      expect(find.text(S.current.pivMacSetupDone), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('replacement is disabled until explicitly accepted', (
    tester,
  ) async {
    final c = SetupController([entry('9A', key: true, cert: true), entry('9D')])
      ..pinOnlyMode = true;
    await tester.pumpWidget(app(c));
    await tester.pumpAndSettle();
    final button = find.widgetWithText(
      FilledButton,
      S.current.pivMacSetupStart,
    );
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    expect(c.writes, isEmpty);
  });
  testWidgets('failure requires rescan before retry and keeps completed work', (
    tester,
  ) async {
    final c = SetupController([entry('9A'), entry('9D')])
      ..pinOnlyMode = true
      ..failSlot = '9D';
    await tester.pumpWidget(app(c));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text(S.current.pivMacSetupStart));
    await tester.pumpAndSettle();
    expect(find.text(S.current.pivMacSetupError), findsOneWidget);
    c.failSlot = null;
    await tester.tap(find.text(S.current.pivMacSetupInspect));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.pivMacSetupStart));
    await tester.pumpAndSettle();
    expect(c.writes, ['9A', '9D', '9D']);
    expect(find.text(S.current.pivMacSetupDone), findsOneWidget);
  });
}
