import 'package:canokey_console/controller/applets/oath/oath_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/poll_canokey_screen.dart';
import 'package:canokey_console/views/applets/oath/widgets/top_actions.dart'
    as oath;
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:platform_detector/enums.dart';
import 'package:platform_detector/platform_detector.dart';

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

  testWidgets('iOS can pull to refresh when content is shorter than the screen',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final platform = PlatformDetector.platform;
    final originalType = platform.type;
    final originalName = platform.name;
    final originalCompany = platform.company;
    platform
      ..type = PlatformType.mobile
      ..name = PlatformName.iOS
      ..company = PlatformCompany.apple;
    addTearDown(() {
      platform
        ..type = originalType
        ..name = originalName
        ..company = originalCompany;
    });

    var refreshCount = 0;
    await tester.pumpWidget(
      GetMaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Layout(
          title: 'NDEF',
          onRefresh: () async {
            refreshCount++;
          },
          child: const PollCanoKeyScreen(
            key: Key('refresh-content'),
          ),
        ),
      ),
    );
    await tester.pump();

    final scrollView = find.byType(CustomScrollView);
    expect(scrollView, findsOneWidget);
    final scrollViewWidget = tester.widget<CustomScrollView>(scrollView);
    expect(
      scrollViewWidget.physics,
      isA<BouncingScrollPhysics>(),
    );
    expect(
      scrollViewWidget.slivers.whereType<CupertinoSliverRefreshControl>(),
      hasLength(1),
    );
    final content = find.byKey(const Key('refresh-content'));
    expect(tester.getSize(content).height, greaterThan(700));
    final scrollCenter = tester.getCenter(scrollView);
    final target = find.text(
      'Pull down or tap refresh, then hold your iPhone near your CanoKey, '
      'or insert it into the USB port',
    );
    expect(tester.getCenter(target).dy, closeTo(scrollCenter.dy, 1));

    final initialTargetTop = tester.getTopLeft(target).dy;
    final gesture = await tester.startGesture(tester.getCenter(target));
    await gesture.moveBy(const Offset(0, 300));
    await tester.pump();
    expect(tester.getTopLeft(target).dy, greaterThan(initialTargetTop));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(refreshCount, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('non-iOS layouts do not enable pull to refresh', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final platform = PlatformDetector.platform;
    final originalType = platform.type;
    final originalName = platform.name;
    final originalCompany = platform.company;
    platform
      ..type = PlatformType.mobile
      ..name = PlatformName.android
      ..company = PlatformCompany.google;
    addTearDown(() {
      platform
        ..type = originalType
        ..name = originalName
        ..company = originalCompany;
    });

    await tester.pumpWidget(
      GetMaterialApp(
        home: Layout(
          onRefresh: () async {},
          child: const SizedBox(height: 100),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CupertinoSliverRefreshControl), findsNothing);
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
