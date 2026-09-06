import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/views/logs/logs_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:get/get.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/theme/app_style.dart';

Widget _app(LogStore store,
        {Locale locale = const Locale('en'), double scale = 1}) =>
    GetMaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
        home: LogsPage(store: store));

void main() {
  setUp(() {
    Get.testMode = true;
    AppStyle.init();
  });
  tearDown(Get.reset);

  testWidgets('plain text displays and copies full logs and supports pausing',
      (tester) async {
    final store = LogStore();
    addTearDown(store.dispose);
    final payload = '0020000006313233343536' * 300;
    store.record('USB', LogEvent(Level.trace, payload));
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.readOnly, isTrue);
    expect(field.maxLines, isNull);
    expect(field.controller!.text, contains(payload));
    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.byType(Switch), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(store.enabled, isFalse);
    store.record('USB', LogEvent(Level.trace, 'Paused event'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(field.controller!.text, isNot(contains('Paused event')));

    String? copied;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.tap(find.byTooltip('Copy'));
    await tester.pumpAndSettle();
    expect(copied, store.text);
    expect(copied, contains(payload));

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    store.record('USB', LogEvent(Level.trace, 'Resumed event'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(field.controller!.text, contains('Resumed event'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('viewer updates to contain only the latest 500 events',
      (tester) async {
    final store = LogStore();
    addTearDown(store.dispose);
    for (var i = 0; i < 510; i++) {
      store.record('Test', LogEvent(Level.trace, 'Event $i\n'));
    }
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();
    final controller =
        tester.widget<TextField>(find.byType(TextField)).controller!;
    expect(controller.text, isNot(contains('Event 9\n')));
    expect(controller.text, contains('Event 10\n'));
    expect(controller.text, contains('Event 509\n'));
    store.record('Test', LogEvent(Level.trace, 'Event 510\n'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.text, store.text);
    expect(controller.text, isNot(contains('Event 10\n')));
    expect(controller.text, contains('Event 510\n'));
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(360, 640),
    const Size(1200, 800),
    const Size(740, 360)
  ]) {
    testWidgets('Chinese logs fit $size with enlarged text', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final store = LogStore();
      addTearDown(store.dispose);
      store.record('Console:helper:storage',
          LogEvent(Level.trace, 'A long message ${'description ' * 100}'));
      await tester.pumpWidget(
          _app(store, locale: const Locale('zh', 'Hans'), scale: 1.3));
      await tester.pumpAndSettle();
      expect(find.text('\u67e5\u770b\u65e5\u5fd7'), findsOneWidget);
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = FakeViewPadding(bottom: size.height * 0.45);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
