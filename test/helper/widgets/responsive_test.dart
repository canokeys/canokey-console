import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keyboard insets do not rebuild responsive content',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);

    var buildCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Responsive(
          builder: (context, constraints, screenType) {
            buildCount++;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    expect(buildCount, 1);

    tester.view.viewInsets = const FakeViewPadding(bottom: 360);
    await tester.pump();

    expect(buildCount, 1);
  });
}
