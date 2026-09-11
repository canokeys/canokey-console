import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/views/applets/piv/widgets/piv_macos_next_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final slot in ['9A', '9D']) {
    testWidgets('after $slot, guide the user to the other slot', (
      tester,
    ) async {
      String? opened;
      final nextSlot = slot == '9A' ? '9D' : '9A';
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: Scaffold(
            body: PivMacOsNextStep(
              completedSlot: slot,
              onOpenSlot: (value) => opened = value,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          slot == '9A'
              ? S.current.pivMacOsAfterAuthentication
              : S.current.pivMacOsAfterKeychain,
        ),
        findsOneWidget,
      );
      expect(opened, isNull);
      await tester.tap(find.text(S.current.pivMacOsCheckSlot(nextSlot)));
      expect(opened, nextSlot);
      expect(tester.takeException(), isNull);
    });
  }
}
