import 'package:canokey_console/controller/applets/oath/oath_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/utils/apple_device.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/widgets/poll_canokey_screen.dart';
import 'package:canokey_console/views/applets/oath/widgets/top_actions.dart'
    as oath;
import 'package:canokey_console/views/layout/layout.dart';
import 'package:canokey_console/views/layout/left_bar.dart';
import 'package:canokey_console/views/layout/top_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  for (final dark in [false, true]) {
    for (final size in [const Size(1366, 1024), const Size(1024, 1366)]) {
      testWidgets('iPad status area stays uniform ($size, dark: $dark)', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.view.viewPadding = const FakeViewPadding(top: 24);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetViewPadding);
        final previousTheme = ThemeCustomizer.instance.theme;
        final previousAdminTheme = AdminTheme.theme;
        final previousThemeType = AppTheme.themeType;
        ThemeCustomizer.instance.theme = dark
            ? ThemeMode.dark
            : ThemeMode.light;
        AdminTheme.setTheme();
        addTearDown(() {
          ThemeCustomizer.instance.theme = previousTheme;
          AdminTheme.theme = previousAdminTheme;
          AppTheme.themeType = previousThemeType;
        });

        await tester.pumpWidget(
          GetMaterialApp(
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            locale: const Locale('en'),
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            home: Layout(child: const SizedBox(height: 3000)),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.getTopLeft(find.byType(LeftBar)).dy, 24);
        expect(tester.getTopLeft(find.byType(TopBar)).dy, 24);
        final statusBackground = find.ancestor(
          of: find.byType(LeftBar),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is ColoredBox &&
                widget.color == AdminTheme.theme.topBarTheme.background,
          ),
        );
        expect(statusBackground, findsOneWidget);
        expect(tester.getRect(statusBackground), Offset.zero & size);

        final expectedBrightness = dark ? Brightness.dark : Brightness.light;
        expect(
          SystemChrome.latestStyle?.statusBarBrightness,
          expectedBrightness,
        );
        final contentScroll = find
            .descendant(
              of: find.byType(Layout),
              matching: find.byType(SingleChildScrollView),
            )
            .last;
        await tester.drag(contentScroll, const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(contentScroll).dy, 24);
        expect(tester.getTopLeft(find.byType(TopBar)).dy, 24);

        final dialogClosed = AppDialog.show(
          const AlertDialog(title: Text('Status bar test')),
        );
        await tester.pumpAndSettle();
        expect(
          SystemChrome.latestStyle?.statusBarBrightness,
          expectedBrightness,
        );
        Get.back();
        await tester.pumpAndSettle();
        await dialogClosed;
        expect(
          SystemChrome.latestStyle?.statusBarBrightness,
          expectedBrightness,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
    }
  }


  testWidgets('mobile top bar keeps actions compact and title visible',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

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
          title: 'OTP',
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
      matching: find.text('OTP'),
    );
    final titleBox = tester.renderObject<RenderBox>(title);
    expect(
      titleBox.size.width,
      greaterThanOrEqualTo(titleBox.getMaxIntrinsicWidth(double.infinity)),
    );
    expect(tester.takeException(), isNull);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.resizeToAvoidBottomInset, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('iOS can pull to refresh when content is shorter than the screen',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    AppleDevice.setIPadForTesting(false);
    addTearDown(() {
      AppleDevice.setIPadForTesting(false);
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
          title: 'NFC Tag',
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
    expect(tester.getCenter(target).dy, lessThan(scrollCenter.dy - 60));
    expect(tester.getTopLeft(target).dy,
        greaterThan(tester.getTopLeft(scrollView).dy));

    final initialTargetTop = tester.getTopLeft(target).dy;
    final gesture = await tester.startGesture(tester.getCenter(target));
    await gesture.moveBy(const Offset(0, 300));
    await tester.pump();
    expect(tester.getTopLeft(target).dy, greaterThan(initialTargetTop));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(refreshCount, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('iPad uses the macOS USB connection prompt', (tester) async {
    AppleDevice.setIPadForTesting(true);
    SmartCard.connectionError = null;
    addTearDown(() {
      AppleDevice.setIPadForTesting(false);
      SmartCard.connectionError = null;
    });

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
        home: const Scaffold(body: PollCanoKeyScreen()),
      ),
    );
    await tester.pump();

    expect(
      find.text('Insert your CanoKey into the USB port'),
      findsOneWidget,
    );
    expect(find.textContaining('iPhone'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('large top bar clears the status area and sizes refresh action',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1366, 1024);
    tester.view.viewPadding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewPadding);

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
          topActions: TopBarRefreshButton(onPressed: () async {}),
          child: const SizedBox(height: 100),
        ),
      ),
    );
    await tester.pump();

    expect(tester.getTopLeft(find.byType(TopBar)).dy, 24);
    expect(
      tester.getSize(
        find.descendant(
          of: find.byType(TopBarRefreshButton),
          matching: find.byType(IconButton),
        ),
      ),
      const Size.square(48),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('non-iOS layouts do not enable pull to refresh', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

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
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('keyboard insets do not rebuild page content', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);

    var buildCount = 0;
    await tester.pumpWidget(
      GetMaterialApp(
        home: Layout(
          child: Builder(
            builder: (context) {
              MediaQuery.of(context);
              buildCount++;
              return const SizedBox(height: 100);
            },
          ),
        ),
      ),
    );
    expect(buildCount, 1);

    tester.view.viewInsets = const FakeViewPadding(bottom: 360);
    await tester.pump();

    expect(buildCount, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('TOTP top actions use narrow horizontal slots', (tester) async {
    final controller = OathController()..polled = true;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.delegate.supportedLocales,
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
