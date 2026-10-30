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

  tearDown(() {
    Prompts.stopPromptAndroidPolling();
    Prompts.dismissTransientPrompt();
    Get.reset();
  });

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
    'scan notice transitions, replacement and cleanup are idempotent',
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
      expect(find.text(S.current.nfcWaitingMessage), findsOneWidget);

      Prompts.promptAndroidReading();
      Prompts.promptAndroidReading();
      await tester.pump();
      expect(find.text(S.current.nfcWaitingMessage), findsNothing);
      expect(find.text(S.current.readingAlertMessage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      Prompts.showPrompt('Read failed', ContentThemeColor.danger);
      await tester.pump();
      expect(Prompts.cardReadPhase.value, isNull);
      expect(find.text(S.current.readingAlertMessage), findsNothing);
      expect(find.text('Read failed'), findsOneWidget);
      Prompts.promptAndroidPolling();
      await tester.pump();
      expect(find.text('Read failed'), findsNothing);
      expect(find.text(S.current.nfcWaitingMessage), findsOneWidget);

      // A rapid replacement must leave one notice, and stop removes it on the
      // next frame even if no opening/closing animation has had time to run.
      Prompts.promptAndroidPolling();
      await tester.pump();
      expect(find.text(S.current.nfcWaitingMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
      Prompts.stopPromptAndroidPolling();
      Prompts.stopPromptAndroidPolling();
      await tester.pumpAndSettle();
      expect(find.text(S.current.nfcWaitingMessage), findsNothing);
      Prompts.promptAndroidPolling();
      Prompts.stopPromptAndroidPolling();
      await tester.pumpAndSettle();
      expect(find.text(S.current.nfcWaitingMessage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
