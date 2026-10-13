import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/widgets/input_pin_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  for (final dismissal in ['cancel', 'close', 'back']) {
    testWidgets('PIN cancellation completes exactly once via $dismissal', (
      tester,
    ) async {
      var canceled = 0;
      await tester.pumpWidget(
        _app(
          InputPinDialog(
            title: 'Unlock',
            label: 'PIN',
            prompt: 'Enter PIN',
            required: true,
            showSaveOption: false,
            validators: const [],
            onSubmit: (_, _) async {},
            onCancel: () async {
              canceled++;
            },
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      switch (dismissal) {
        case 'cancel':
          await tester.tap(find.text(S.current.cancel));
        case 'close':
          await tester.tap(find.byTooltip('Close'));
        case 'back':
          await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(find.byType(InputPinDialog), findsNothing);
      expect(canceled, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'busy dialogs block duplicate submit and back; failures allow retry',
    (tester) async {
      var calls = 0;
      final pending = Completer<void>();
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => AppDialogSurface(
              child: SizedBox(
                width: 460,
                child: AppDialogLayout(
                  header: const AppDialogHeader(title: 'Settings'),
                  body: const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Form'),
                  ),
                  actions: [
                    AppDialogAction(
                      label: 'Save',
                      onPressed: () async {
                        calls++;
                        if (calls == 1) await pending.future;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Settings'), findsOneWidget);
      expect(calls, 1);
      pending.completeError(StateError('test transport failure'));
      await tester.pumpAndSettle();
      expect(
        find.text(S.current.operationFailed).hitTestable(),
        findsOneWidget,
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      Prompts.dismissTransientPrompt();
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('long results fit a small screen with the keyboard visible', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 480);
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(_app(const SizedBox.shrink()));
    Prompts.showPrompt('Long error message. ' * 80, ContentThemeColor.danger);
    await tester.pump();
    expect(find.byTooltip('Close').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
  });

  testWidgets(
    'result notices appear above a dialog and dismiss independently',
    (tester) async {
      await tester.pumpWidget(
        _app(
          const AppConfirmationDialog(
            title: 'Confirm',
            message: 'Message',
            confirmLabel: 'Apply',
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      Prompts.showPrompt('Saved', ContentThemeColor.success);
      await tester.pump();
      expect(find.text('Saved').hitTestable(), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      await tester.tap(find.byTooltip('Close').last);
      await tester.pump();
      expect(find.text('Saved'), findsNothing);
      expect(find.text('Confirm'), findsOneWidget);
      Prompts.showPrompt('First', ContentThemeColor.danger);
      await tester.pump(const Duration(seconds: 2));
      Prompts.showPrompt('Second', ContentThemeColor.danger);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Second'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

Widget _app(Widget dialog) => GetMaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => AppDialog.show(dialog),
        child: const Text('Open'),
      ),
    ),
  ),
);
