import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/keyboard_safe_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  void configureKeyboardViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.viewInsets = const FakeViewPadding(bottom: 360);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);
  }

  testWidgets('keyboard safe dialog scrolls long content above the keyboard',
      (tester) async {
    configureKeyboardViewport(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: KeyboardSafeDialog(
          child: SizedBox(
            width: 400,
            child: _LongDialogContent(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const Key('bottom-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bottom-action')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('base dialog uses the same keyboard safe scrolling',
      (tester) async {
    configureKeyboardViewport(tester);

    await tester.pumpWidget(
      const GetMaterialApp(home: _TestBaseDialog()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const Key('bottom-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bottom-action')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard safe dialog supports a stepper inside a column',
      (tester) async {
    configureKeyboardViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: Dialog(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Provision key'),
                ),
                Flexible(
                  child: Stepper(
                    currentStep: 2,
                    controlsBuilder: (context, details) =>
                        const SizedBox.shrink(),
                    steps: [
                      const Step(
                        title: Text('Authenticate'),
                        content: TextField(
                          decoration: InputDecoration(labelText: 'PIN'),
                        ),
                      ),
                      const Step(
                        title: Text('Key options'),
                        content: SizedBox(height: 180),
                      ),
                      Step(
                        title: Text('Subject'),
                        content: Column(
                          children: [
                            for (var index = 0; index < 6; index++) ...[
                              TextField(
                                decoration: InputDecoration(
                                  labelText: 'Subject field ${index + 1}',
                                ),
                              ),
                              SizedBox(height: 16),
                            ],
                            Text('End of subject', key: Key('stepper-end')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('stepper-end')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stepper-end')), findsOneWidget);
    expect(find.byKey(const Key('stepper-end')).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('composited keyboard motion does not relayout dialog content',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);

    var layoutCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: KeyboardSafeDialog(
          useCompositedKeyboardMotion: true,
          child: _LayoutCounter(
            onLayout: () => layoutCount++,
            child: const SizedBox(
              key: Key('compact-dialog-content'),
              width: 360,
              height: 320,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final initialLayoutCount = layoutCount;

    for (final keyboardHeight in [100.0, 200.0, 360.0]) {
      tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
      await tester.pump();
    }

    expect(layoutCount, initialLayoutCount);
    expect(
      tester.getBottomRight(find.byKey(const Key('compact-dialog-content'))).dy,
      lessThanOrEqualTo(844 - 360),
    );
    expect(tester.takeException(), isNull);
  });
}

class _TestBaseDialog extends BaseDialog {
  const _TestBaseDialog();

  @override
  State<_TestBaseDialog> createState() => _TestBaseDialogState();
}

class _TestBaseDialogState extends BaseDialogState<_TestBaseDialog> {
  @override
  Widget buildDialogContent() => const _LongDialogContent();
}

class _LongDialogContent extends StatelessWidget {
  const _LongDialogContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Keyboard-safe dialog'),
        ),
        for (var index = 0; index < 6; index++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(labelText: 'Field ${index + 1}'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        const Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton(
            key: Key('bottom-action'),
            onPressed: null,
            child: Text('Confirm'),
          ),
        ),
      ],
    );
  }
}

class _LayoutCounter extends SingleChildRenderObjectWidget {
  final VoidCallback onLayout;

  const _LayoutCounter({required this.onLayout, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderLayoutCounter(onLayout);

  @override
  void updateRenderObject(
      BuildContext context, _RenderLayoutCounter renderObject) {
    renderObject.onLayout = onLayout;
  }
}

class _RenderLayoutCounter extends RenderProxyBox {
  VoidCallback onLayout;

  _RenderLayoutCounter(this.onLayout);

  @override
  void performLayout() {
    super.performLayout();
    onLayout();
  }
}
