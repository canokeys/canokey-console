import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/views/applets/piv/widgets/piv_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Form extends BaseDialog {
  final Widget content;
  const _Form(this.content);
  @override
  BaseDialogState<_Form> createState() => _FormState();
}

class _FormState extends BaseDialogState<_Form> {
  @override
  Widget buildDialogContent() => widget.content;
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() {
    Prompts.stopPromptAndroidPolling();
    Prompts.dismissTransientPrompt();
    Get.reset();
  });

  for (final form in [true, false]) {
    testWidgets(
      '${form ? 'Base' : 'Custom'} dialog shares scan UI and retries',
      (tester) async {
        var submissions = 0;
        var pending = Completer<void>();
        final content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppDialogHeader(title: 'Test form'),
            const TextField(),
            PivButton(label: 'PIV', onPressed: () {}),
            AppDialogAction(
              label: 'Submit',
              onPressed: () async {
                submissions++;
                Prompts.promptAndroidPolling();
                try {
                  await pending.future;
                } finally {
                  Prompts.stopPromptAndroidPolling();
                }
              },
            ),
          ],
        );
        await tester.pumpWidget(
          GetMaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const [S.delegate],
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => AppDialog.show(
                    form
                        ? _Form(content)
                        : AppDialogSurface(
                            child: SizedBox(width: 460, child: content),
                          ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Submit'));
        await tester.pump();
        expect(submissions, 1);
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'PIV'))
              .onPressed,
          isNull,
        );
        expect(find.text(S.current.nfcWaitingMessage), findsOneWidget);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        expect(
          tester.widget<IconButton>(find.byType(IconButton)).onPressed,
          isNull,
        );
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(find.text('Test form'), findsOneWidget);

        Prompts.promptAndroidReading();
        await tester.pump();
        expect(find.text(S.current.nfcWaitingMessage), findsNothing);
        expect(find.text(S.current.readingAlertMessage), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        Prompts.showPrompt('Scan timed out', ContentThemeColor.danger);
        pending.complete();
        await tester.pumpAndSettle();
        expect(find.text('Scan timed out'), findsOneWidget);
        expect(Prompts.cardReadPhase.value, isNull);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );

        pending = Completer<void>();
        await tester.tap(find.text('Submit'));
        await tester.pump();
        expect(submissions, 2);
        expect(find.text('Scan timed out'), findsNothing);
        expect(find.text(S.current.nfcWaitingMessage), findsOneWidget);
        pending.complete();
        await tester.pumpAndSettle();
        expect(Prompts.cardReadPhase.value, isNull);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.text('Test form'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
