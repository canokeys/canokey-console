import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/input_pin_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  for (final showSaveOption in [false, true]) {
    testWidgets(
      'PIN visibility toggles without losing input (save option=$showSaveOption)',
      (tester) async {
        await tester.pumpWidget(
          GetMaterialApp(
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            home: Scaffold(
              body: InputPinDialog(
                title: 'PIN',
                label: 'PIN',
                prompt: 'Enter PIN',
                required: true,
                showSaveOption: showSaveOption,
                validators: const [],
                onFocus: () async {},
                onSubmit: (_, _) async {},
                onCancel: () async {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), '123456');

        EditableText field() =>
            tester.widget<EditableText>(find.byType(EditableText));
        expect(field().obscureText, isTrue);

        await tester.tap(find.byIcon(Icons.visibility_off));
        await tester.pumpAndSettle();
        expect(field().obscureText, isFalse);
        expect(field().controller.text, '123456');
        expect(find.byIcon(Icons.visibility), findsOneWidget);

        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pumpAndSettle();
        expect(field().obscureText, isTrue);
        expect(field().controller.text, '123456');
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      },
    );
  }

  testWidgets('submitting releases the PIN field focus before NFC work', (
    tester,
  ) async {
    var submittedWithoutFocus = false;
    late FocusNode pinFocusNode;

    await tester.pumpWidget(
      GetMaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: InputPinDialog(
            title: 'PIN',
            label: 'PIN',
            prompt: 'Enter PIN',
            required: true,
            showSaveOption: false,
            validators: const [],
            onSubmit: (_, _) async {
              submittedWithoutFocus = !pinFocusNode.hasFocus;
            },
            onCancel: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byType(TextFormField);
    expect(field, findsOneWidget);
    pinFocusNode = tester
        .widget<EditableText>(find.byType(EditableText))
        .focusNode;
    expect(pinFocusNode.hasFocus, isTrue);

    await tester.enterText(field, '123456');
    await tester.tap(find.text(S.current.confirm));
    await tester.pump();

    expect(submittedWithoutFocus, isTrue);
    expect(pinFocusNode.hasFocus, isFalse);
  });
}
