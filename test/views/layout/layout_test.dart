import 'package:canokey_console/controller/applets/oath/oath_controller.dart';
import 'package:canokey_console/views/applets/oath/widgets/top_actions.dart'
    as oath;
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('mobile top bar keeps actions compact and title visible',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Layout(
          title: 'TOTP / HOTP',
          topActions: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const Key('action-1'),
                onPressed: () {},
                icon: const Icon(Icons.sort),
              ),
              PopupMenuButton<void>(
                key: const Key('action-2'),
                icon: const Icon(Icons.add),
                itemBuilder: (_) => const [],
              ),
              IconButton(
                key: const Key('action-3'),
                onPressed: () {},
                icon: const Icon(Icons.lock),
              ),
            ],
          ),
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();

    for (final key in const ['action-1', 'action-2', 'action-3']) {
      expect(tester.getSize(find.byKey(Key(key))), const Size(40, 40));
    }

    final title = find.descendant(
      of: find.byType(AppBar),
      matching: find.text('TOTP / HOTP'),
    );
    final titleBox = tester.renderObject<RenderBox>(title);
    expect(
      titleBox.size.width,
      greaterThanOrEqualTo(titleBox.getMaxIntrinsicWidth(double.infinity)),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('TOTP top actions use narrow horizontal slots', (tester) async {
    final controller = OathController()..polled = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: oath.TopActions(
            controller: controller,
            leading: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.sort),
            ),
            onQrScan: () {},
            onScreenCapture: () {},
            onManualAdd: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    for (final button in find.byType(IconButton).evaluate()) {
      expect(tester.getSize(find.byWidget(button.widget)), const Size(32, 40));
    }
    expect(
      tester.getSize(
        find.byWidgetPredicate((widget) => widget is PopupMenuButton),
      ),
      const Size(32, 40),
    );
    expect(tester.takeException(), isNull);

    controller.timerController.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
