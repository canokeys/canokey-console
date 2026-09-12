import 'package:canokey_console/helper/widgets/responsive_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'uses available width, caps columns and preserves natural heights',
    (tester) async {
      Future<void> pumpGrid(double width, {int? maxColumns}) =>
          tester.pumpWidget(
            MaterialApp(
              home: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  child: ResponsiveGrid(
                    minWidth: 200,
                    spacing: 10,
                    maxColumns: maxColumns,
                    minChildHeight: 40,
                    children: [
                      for (var i = 0; i < 3; i++)
                        SizedBox(key: ValueKey(i), height: i == 1 ? 90 : 20),
                    ],
                  ),
                ),
              ),
            ),
          );

      await pumpGrid(650);
      expect(
        tester.getSize(find.byKey(const ValueKey(0))).width,
        closeTo(210, .01),
      );
      expect(tester.getSize(find.byKey(const ValueKey(0))).height, 40);
      expect(tester.getSize(find.byKey(const ValueKey(1))).height, 90);
      expect(tester.getTopLeft(find.byKey(const ValueKey(2))).dx, 440);

      await pumpGrid(650, maxColumns: 2);
      expect(tester.getSize(find.byKey(const ValueKey(0))).width, 320);
      expect(tester.getTopLeft(find.byKey(const ValueKey(2))).dy, 100);

      await pumpGrid(150);
      expect(tester.getSize(find.byKey(const ValueKey(0))).width, 150);
      expect(tester.getTopLeft(find.byKey(const ValueKey(1))).dy, 50);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty grid takes no space', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Align(child: ResponsiveGrid(children: [])),
      ),
    );
    expect(tester.getSize(find.byType(ResponsiveGrid)), Size.zero);
    expect(tester.takeException(), isNull);
  });
}
