import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/views/applets/piv/widgets/piv_management_key_authentication.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final pinProtected in [true, false]) {
    for (final requiresPin in [true, false]) {
      testWidgets(
        'authentication fields: protected=$pinProtected, operation PIN=$requiresPin',
        (tester) async {
          var usePinOnly = pinProtected;
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
              home: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) =>
                      PivManagementKeyAuthentication(
                        pinProtected: pinProtected,
                        usePinOnly: usePinOnly,
                        requiresPin: requiresPin,
                        onChanged: (value) =>
                            setState(() => usePinOnly = value),
                        pinField: const TextField(key: ValueKey('pin')),
                        managementKeyField: const TextField(
                          key: ValueKey('key'),
                        ),
                      ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('pin')),
            pinProtected || requiresPin ? findsOneWidget : findsNothing,
          );
          expect(
            find.byKey(const ValueKey('key')),
            pinProtected ? findsNothing : findsOneWidget,
          );
          if (pinProtected) {
            await tester.tap(find.text(S.current.pivManualManagementKey));
            await tester.pumpAndSettle();
            expect(find.byKey(const ValueKey('key')), findsOneWidget);
            expect(
              find.byKey(const ValueKey('pin')),
              requiresPin ? findsOneWidget : findsNothing,
            );
            expect(
              find.text(S.current.pivOperationRequiresPin),
              requiresPin ? findsOneWidget : findsNothing,
            );
            await tester.tap(find.text(S.current.pivPinProtectedKeyOnCard));
            await tester.pumpAndSettle();
            expect(find.byKey(const ValueKey('pin')), findsOneWidget);
            expect(find.byKey(const ValueKey('key')), findsNothing);
          } else {
            expect(find.byType(RadioListTile<bool>), findsNothing);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
