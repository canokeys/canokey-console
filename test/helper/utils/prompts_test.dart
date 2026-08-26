import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('dismissTransientPrompt immediately removes the current error',
      (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(body: SizedBox.shrink()),
      ),
    );

    Prompts.showPrompt('Previous NFC read failed', ContentThemeColor.danger);
    await tester.pump();
    expect(find.text('Previous NFC read failed'), findsOneWidget);

    Prompts.dismissTransientPrompt();
    await tester.pump();
    expect(find.text('Previous NFC read failed'), findsNothing);
  });

  testWidgets('an older timeout does not dismiss a newer prompt',
      (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(body: SizedBox.shrink()),
      ),
    );

    Prompts.showPrompt('First error', ContentThemeColor.danger);
    await tester.pump(const Duration(seconds: 2));
    Prompts.showPrompt('Second error', ContentThemeColor.danger);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Second error'), findsOneWidget);
  });
}
