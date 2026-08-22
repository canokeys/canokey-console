import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('dialog ignores barrier taps but allows system back navigation', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const Key('open-dialog'),
              onPressed: () => AppDialog.show(
                AppDialogSurface(
                  child: SizedBox(
                    width: AppDialogWidth.compact,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Dialog content'),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();
    expect(find.text('Dialog content'), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.text('Dialog content'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Dialog content'), findsNothing);
  });

  testWidgets('large dialog surface respects compact viewport insets', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AppDialogSurface(
          child: SizedBox(
            key: Key('dialog-content'),
            width: AppDialogWidth.large,
            height: 120,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const Key('dialog-content'))).width,
      lessThanOrEqualTo(288),
    );

    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    expect(dialog.clipBehavior, Clip.antiAlias);

    final theme = Theme.of(tester.element(find.byKey(const Key('dialog-content'))));
    final shape = theme.dialogTheme.shape! as RoundedRectangleBorder;
    expect(shape.borderRadius, const BorderRadius.all(Radius.circular(8)));
  });
}
