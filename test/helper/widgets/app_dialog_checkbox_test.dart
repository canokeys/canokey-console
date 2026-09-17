import 'dart:async';

import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('box, label and whitespace each toggle exactly once', (
    tester,
  ) async {
    var value = false;
    var changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 320,
              child: AppDialogCheckbox(
                value: value,
                title: const Text('Option'),
                onChanged: (next) => setState(() {
                  value = next!;
                  changes++;
                }),
              ),
            ),
          ),
        ),
      ),
    );
    final row = find.byType(AppDialogCheckbox);
    expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(value, isTrue);
    expect(changes, 1);
    await tester.tap(find.text('Option'));
    await tester.pump();
    expect(value, isFalse);
    expect(changes, 2);
    final rect = tester.getRect(row);
    await tester.tapAt(Offset(rect.right - 8, rect.center.dy));
    await tester.pump();
    expect(value, isTrue);
    expect(changes, 3);
  });

  testWidgets('keyboard activates the same row', (tester) async {
    var changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppDialogCheckbox(
            value: false,
            title: const Text('Option'),
            onChanged: (_) => changes++,
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(changes, 1);
  });

  testWidgets('disabled rows and large wrapped labels preserve layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: SizedBox(
              width: 240,
              child: AppDialogCheckbox(
                value: true,
                onChanged: null,
                title: const Text(
                  'A long setting label that wraps onto several lines',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(
      find.text('A long setting label that wraps onto several lines'),
    );
    await tester.pump();
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);
    expect(checkbox.onChanged, isNull);
    expect(
      tester.getSize(find.byType(AppDialogCheckbox)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('the whole row is disabled during an operation', (tester) async {
    final pending = Completer<void>();
    var changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppDialogSurface(
            child: SizedBox(
              width: 320,
              child: AppDialogLayout(
                header: const AppDialogHeader(title: 'Settings'),
                body: AppDialogCheckbox(
                  value: false,
                  title: const Text('Option'),
                  onChanged: (_) => changes++,
                ),
                actions: [
                  AppDialogAction(
                    label: 'Save',
                    onPressed: () => pending.future,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
    await tester.tap(find.text('Option'), warnIfMissed: false);
    await tester.pump();
    expect(changes, 0);
    pending.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Option'));
    await tester.pump();
    expect(changes, 1);
  });
}
