import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/search_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  Future<void> pumpSearch(WidgetTester tester) async {
    await tester.pumpWidget(GetMaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: const Scaffold(
        body: Column(children: [SearchBox(), TextField()]),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<bool> sendFind(
      WidgetTester tester, LogicalKeyboardKey modifier) async {
    await tester.sendKeyDownEvent(modifier);
    final handled = await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(modifier);
    await tester.pump();
    return handled;
  }

  for (final modifier in [
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.metaLeft,
  ]) {
    testWidgets('${modifier.keyLabel}+F focuses search from another input',
        (tester) async {
      await pumpSearch(tester);
      final fields = find.byType(EditableText);
      final search = tester.widget<EditableText>(fields.first);
      final other = tester.widget<EditableText>(fields.last);
      other.focusNode.requestFocus();
      await tester.pump();

      expect(await sendFind(tester, modifier), isTrue);
      expect(search.focusNode.hasFocus, isTrue);
      expect(other.focusNode.hasFocus, isFalse);
      expect(other.controller.text, isEmpty);
    });
  }

  testWidgets('find does not steal focus from a dialog or another route',
      (tester) async {
    await pumpSearch(tester);
    final search = tester.widget<EditableText>(find.byType(EditableText).first);
    final context = tester.element(find.byType(SearchBox));
    showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(content: TextField(autofocus: true)),
    );
    await tester.pumpAndSettle();
    await sendFind(tester, LogicalKeyboardKey.controlLeft);
    expect(search.focusNode.hasFocus, isFalse);
    expect(
        tester
            .widget<EditableText>(find.byType(EditableText).last)
            .focusNode
            .hasFocus,
        isTrue);

    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Another page')),
    ));
    await tester.pumpAndSettle();
    expect(await sendFind(tester, LogicalKeyboardKey.metaLeft), isFalse);
    expect(search.focusNode.hasFocus, isFalse);
  });

  testWidgets('removing search unregisters the shortcut', (tester) async {
    await pumpSearch(tester);
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    await tester.pumpAndSettle();
    expect(await sendFind(tester, LogicalKeyboardKey.controlLeft), isFalse);
    expect(tester.takeException(), isNull);
  });
}
