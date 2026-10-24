import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('dismissTransientPrompt immediately removes the current error', (
    tester,
  ) async {
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: SizedBox.shrink())),
    );

    Prompts.showPrompt('Previous NFC read failed', ContentThemeColor.danger);
    await tester.pump();
    expect(find.text('Previous NFC read failed'), findsOneWidget);

    Prompts.dismissTransientPrompt();
    await tester.pump();
    expect(find.text('Previous NFC read failed'), findsNothing);
  });

  testWidgets('an older timeout does not dismiss a newer prompt', (
    tester,
  ) async {
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: SizedBox.shrink())),
    );

    Prompts.showPrompt('First error', ContentThemeColor.danger);
    await tester.pump(const Duration(seconds: 2));
    Prompts.showPrompt('Second error', ContentThemeColor.danger);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Second error'), findsOneWidget);
  });

  testWidgets(
    'polling notice is replaced and removed without queued animations',
    (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [S.delegate],
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );
      await tester.pumpAndSettle();
      Prompts.promptAndroidPolling();
      await tester.pump();
      expect(find.text(S.current.readingAlertMessage), findsOneWidget);

      // A rapid replacement must leave one notice, and stop removes it on the
      // next frame even if no opening/closing animation has had time to run.
      Prompts.promptAndroidPolling();
      await tester.pump();
      expect(find.text(S.current.readingAlertMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
      Prompts.stopPromptAndroidPolling();
      Prompts.stopPromptAndroidPolling();
      await tester.pumpAndSettle();
      expect(find.text(S.current.readingAlertMessage), findsNothing);
      Prompts.promptAndroidPolling();
      Prompts.stopPromptAndroidPolling();
      await tester.pumpAndSettle();
      expect(find.text(S.current.readingAlertMessage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dialog polling replaces the page notice and stops cleanly', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [S.delegate],
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
    await tester.pumpAndSettle();
    Prompts.promptAndroidPolling();
    await tester.pump();
    final polling = Get.put(RxBool(false), tag: 'dialog_polling');
    Prompts.promptAndroidPolling();
    await tester.pump();
    expect(polling.value, isTrue);
    expect(find.text(S.current.readingAlertMessage), findsNothing);
    Prompts.stopPromptAndroidPolling();
    expect(polling.value, isFalse);
    await tester.pumpAndSettle();
  });
}
