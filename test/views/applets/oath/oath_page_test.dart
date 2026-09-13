import 'package:canokey_console/controller/applets/oath/oath_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:canokey_console/views/applets/oath/oath_page.dart';
import 'package:canokey_console/views/applets/oath/widgets/oath_account_grid.dart';
import 'package:canokey_console/views/applets/oath/widgets/oath_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timer_controller/timer_controller.dart';

class _Controller extends OathController {
  final calculations = <(String, OathType)>[];
  @override
  void onReady() {}
  @override
  Future<String> calculate(String name, OathType type) async {
    calculations.add((name, type));
    return '';
  }
}

void main() {
  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });
  tearDown(Get.reset);

  testWidgets('account cards change width and column count', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final controller = _Controller();
    addTearDown(controller.timerController.dispose);
    final accounts = {
      for (var i = 0; i < 7; i++)
        'Account $i': OathItem(
          'Service $i',
          'jdoe@example.com',
          code: '721026',
        ),
    };
    for (final (width, columns) in [
      (390.0, 1),
      (780.0, 2),
      (1000.0, 2),
      (1200.0, 3),
      (1600.0, 4),
    ]) {
      tester.view.physicalSize = Size(width, 1600);
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SingleChildScrollView(
              child: OathAccountGrid(
                accounts: accounts,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cards = find.byType(OathItemCard);
      final first = tester.getRect(cards.first);
      expect(first.width, closeTo((width - 16 * (columns - 1)) / columns, .01));
      expect(tester.getRect(cards.at(columns - 1)).top, first.top);
      expect(tester.getRect(cards.at(columns)).top, greaterThan(first.bottom));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('code formatting, copy and countdown preserve the raw OTP', (
    tester,
  ) async {
    final controller = _Controller();
    addTearDown(controller.timerController.dispose);
    controller.timerController.value = TimerValue(
      remaining: 23,
      unit: TimerUnit.second,
    );
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: OathItemCard(
            controller: controller,
            name: 'Google:account',
            item: OathItem('Google', 'account', code: '721026'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('721 026'), findsOneWidget);
    expect(find.text('23'), findsOneWidget);
    await tester.tap(find.byTooltip(S.current.copy));
    await tester.pump();
    expect(copied, '721026');
    controller.timerController.value = TimerValue(
      remaining: 22,
      unit: TimerUnit.second,
    );
    await tester.pump();
    expect(find.text('22'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HOTP and touch-required credentials retain calculate actions', (
    tester,
  ) async {
    final controller = _Controller();
    addTearDown(controller.timerController.dispose);
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: OathAccountGrid(
            controller: controller,
            accounts: {
              'hotp': OathItem('HOTP', 'account', type: OathType.hotp),
              'touch': OathItem('TOTP', 'account', requireTouch: true),
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<IconButton>(
            find
                .byWidgetPredicate(
                  (widget) =>
                      widget is IconButton && widget.tooltip == S.current.copy,
                )
                .first,
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip(S.current.refresh));
    await tester.tap(find.byTooltip(S.current.oathRequireTouch));
    expect(controller.calculations, [
      ('hotp', OathType.hotp),
      ('touch', OathType.totp),
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'long names, eight-digit and Steam codes fit mobile and large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 1400);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final controller = _Controller();
      addTearDown(controller.timerController.dispose);
      for (final dark in [false, true]) {
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: SingleChildScrollView(
                child: OathAccountGrid(
                  controller: controller,
                  accounts: {
                    'long': OathItem(
                      'Very long issuer ' * 10,
                      'long-email-address' * 10,
                      code: '12345678',
                    ),
                    'steam': OathItem('Steam', 'account', code: 'ABCDE'),
                  },
                ),
              ),
            ),
            dark: dark,
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('1234 5678'), findsOneWidget);
        expect(find.text('ABCDE'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('empty page retains add methods and filters accounts', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final controller = _Controller()..polled = true;
    Get.put<OathController>(controller);
    await tester.pumpWidget(_app(const OathPage(), route: '/applets/oath'));
    await tester.pumpAndSettle();
    expect(find.text(S.current.oathDescription), findsNothing);
    expect(find.byTooltip(S.current.oathAddAccount), findsOneWidget);
    expect(find.text(S.current.noCredential), findsOneWidget);
    await tester.tap(find.byTooltip(S.current.oathAddAccount));
    await tester.pumpAndSettle();
    expect(find.text(S.current.oathAddManually), findsOneWidget);
    Get.back();
    controller.oathMap['Google:account'] = OathItem(
      'Google',
      'account',
      code: '123456',
    );
    controller.update();
    await tester.pumpAndSettle();
    expect(find.byType(OathItemCard), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'missing');
    await tester.pumpAndSettle();
    expect(find.text(S.current.noMatchingCredential), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(
  Widget child, {
  bool dark = false,
  double scale = 1,
  String? route,
}) => GetMaterialApp(
  theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
  locale: const Locale('en'),
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.delegate.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: route == null ? child : null,
  initialRoute: route,
  getPages: route == null ? null : [GetPage(name: route, page: () => child)],
);
