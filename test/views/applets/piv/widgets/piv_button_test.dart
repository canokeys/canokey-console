import 'package:canokey_console/views/applets/piv/widgets/piv_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final scale in [1.0, 1.8]) {
    testWidgets(
      'button bounds align for short, long and disabled labels at scale $scale',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Row(
                  children: [
                    PivButton(label: 'Cancel', onPressed: () {}),
                    PivButton(
                      label: 'Create Certificate',
                      onPressed: () {},
                      primary: true,
                    ),
                    const PivButton(
                      label: 'Download Attestation',
                      onPressed: null,
                      icon: Icons.download,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        final buttons = find.byType(PivButton);
        expect(tester.getSize(buttons.at(0)), tester.getSize(buttons.at(1)));
        expect(tester.getSize(buttons.at(1)), tester.getSize(buttons.at(2)));
        expect(tester.getSize(buttons.first).width, 120);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
