import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/controller/applets/webauthn/webauthn_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/views/applets/webauthn/dialogs/authenticator_config_dialog.dart';
import 'package:canokey_console/views/applets/webauthn/webauthn_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Controller extends WebAuthnController {
  _Controller({this.hasInfo = true});

  bool hasInfo;
  int toggles = 0;
  int longTouches = 0;
  final List<(int, bool)> minPinSubmissions = [];

  @override
  void onReady() {}

  @override
  bool get hasConfigInfo => hasInfo;

  @override
  bool? get alwaysUv => false;

  @override
  int? get minPinLength => 4;

  @override
  Future<bool> toggleAlwaysUv() async {
    toggles++;
    return true;
  }

  @override
  Future<bool> setMinPinLength(int newMinPinLength, bool forcePinChange) async {
    minPinSubmissions.add((newMinPinLength, forcePinChange));
    return true;
  }

  @override
  Future<bool> enableLongTouchForReset() async {
    longTouches++;
    return true;
  }
}

void main() {
  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });
  tearDown(Get.reset);

  for (final (version, hasInfo, visible) in [
    ('3.1.1', true, true),
    ('3.1.1', false, false),
    ('2.0.1', true, false),
  ]) {
    testWidgets('Authenticator settings entry visibility '
        '(firmware=$version hasInfo=$hasInfo)', (tester) async {
      final controller = _Controller(hasInfo: hasInfo)
        ..polled = true
        ..firmwareVersion = FirmwareVersion.parse(version)
        ..functionSetVersion = CanoKey.functionSetFromFirmwareVersion(version);
      Get.put<WebAuthnController>(controller);
      await tester.pumpWidget(
        _app(const WebAuthnPage(), route: '/applets/webauthn'),
      );
      await tester.pumpAndSettle();
      final entry = find.byTooltip(S.current.webauthnAuthenticatorSettings);
      expect(entry, visible ? findsOneWidget : findsNothing);
      if (visible) {
        await tester.tap(entry);
        await tester.pumpAndSettle();
        expect(find.byType(AuthenticatorConfigDialog), findsOneWidget);
        expect(controller.toggles, 0);
        Get.back();
        await tester.pumpAndSettle();
        expect(find.byType(AuthenticatorConfigDialog), findsNothing);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('dialog renders Always UV, min PIN and danger zone sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: AuthenticatorConfigDialog(
            alwaysUv: false,
            minPinLength: 6,
            onToggleAlwaysUv: () async => true,
            onSetMinPinLength: (min, force) async => true,
            onEnableLongTouch: () async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(S.current.webauthnAlwaysUv), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.byType(AppDialogCheckbox), findsOneWidget);
    expect(find.byType(AppDialogSwitch), findsOneWidget);
    expect(find.text(S.current.webauthnMinPinLength), findsNWidgets(2));
    expect(find.text(S.current.webauthnForcePinChange), findsOneWidget);
    expect(find.text(S.current.webauthnDangerZone), findsOneWidget);
    expect(find.text(S.current.webauthnLongTouchWarning), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('settings remain usable on narrow screens and in dark mode', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final dark in [false, true]) {
      for (final width in [320.0, 1280.0]) {
        tester.view.physicalSize = Size(width, 800);
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: AuthenticatorConfigDialog(
                alwaysUv: false,
                minPinLength: 4,
                onToggleAlwaysUv: () async => true,
                onSetMinPinLength: (min, force) async => true,
                onEnableLongTouch: () async => true,
              ),
            ),
            dark: dark,
            scale: 1.5,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(S.current.close).hitTestable(), findsOneWidget);
        await tester.ensureVisible(find.text(S.current.save));
        await tester.pumpAndSettle();
        expect(find.text(S.current.save).hitTestable(), findsOneWidget);
        await tester.ensureVisible(find.text(S.current.enable));
        await tester.pumpAndSettle();
        expect(find.text(S.current.enable).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });

  testWidgets('min PIN length can only be raised from the current value', (
    tester,
  ) async {
    final submissions = <(int, bool)>[];
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: AuthenticatorConfigDialog(
            alwaysUv: null,
            minPinLength: 6,
            onToggleAlwaysUv: () async => true,
            onSetMinPinLength: (min, force) async {
              submissions.add((min, force));
              return true;
            },
            onEnableLongTouch: () async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // alwaysUv not reported by firmware: the section is hidden
    expect(find.byType(Switch), findsNothing);

    final field = find.byType(TextFormField);
    await tester.enterText(field, '5');
    await tester.tap(find.text(S.current.save));
    await tester.pumpAndSettle();
    expect(submissions, isEmpty);
    expect(
      find.text(S.current.webauthnMinPinLengthHint(6)),
      findsNWidgets(2), // section hint plus the validation error
    );

    await tester.enterText(field, '8');
    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.text(S.current.save));
    await tester.pumpAndSettle();
    expect(submissions, [(8, true)]);

    // After a successful change the lower bound follows the new value.
    await tester.enterText(field, '7');
    await tester.tap(find.text(S.current.save));
    await tester.pumpAndSettle();
    expect(submissions, [(8, true)]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Always UV toggle asks for confirmation first', (tester) async {
    var toggles = 0;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: AuthenticatorConfigDialog(
            alwaysUv: false,
            minPinLength: null,
            onToggleAlwaysUv: () async {
              toggles++;
              return true;
            },
            onSetMinPinLength: (min, force) async => true,
            onEnableLongTouch: () async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(S.current.webauthnMinPinLength), findsNothing);

    await tester.tap(find.text(S.current.webauthnAlwaysUv));
    await tester.pumpAndSettle();
    expect(find.text(S.current.webauthnAlwaysUvTogglePrompt), findsOneWidget);
    await tester.tap(find.text(S.current.cancel));
    await tester.pumpAndSettle();
    expect(toggles, 0);

    await tester.tap(find.text(S.current.webauthnAlwaysUv));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.confirm));
    await tester.pumpAndSettle();
    expect(toggles, 1);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('UV failures retain state, report the error and allow retry', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: AuthenticatorConfigDialog(
            alwaysUv: false,
            minPinLength: null,
            onToggleAlwaysUv: () async {
              if (++attempts == 1) throw StateError('Transport failed');
              return true;
            },
            onSetMinPinLength: (_, _) async => true,
            onEnableLongTouch: () async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.webauthnAlwaysUv));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.confirm));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.text(S.current.operationFailed), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(S.current.webauthnAlwaysUv));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.confirm));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('long touch for reset requires a destructive confirmation', (
    tester,
  ) async {
    var longTouches = 0;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: AuthenticatorConfigDialog(
            alwaysUv: true,
            minPinLength: 4,
            onToggleAlwaysUv: () async => true,
            onSetMinPinLength: (min, force) async => true,
            onEnableLongTouch: () async {
              longTouches++;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final enableButton = find.text(S.current.enable);
    await tester.ensureVisible(enableButton);
    await tester.pumpAndSettle();
    await tester.tap(enableButton);
    await tester.pumpAndSettle();
    expect(find.text(S.current.webauthnLongTouchEnablePrompt), findsOneWidget);
    await tester.tap(find.text(S.current.cancel));
    await tester.pumpAndSettle();
    expect(longTouches, 0);

    await tester.ensureVisible(enableButton);
    await tester.pumpAndSettle();
    await tester.tap(enableButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.enable).hitTestable());
    await tester.pumpAndSettle();
    expect(longTouches, 1);
    // The button is replaced by a plain state label once enabled.
    expect(enableButton, findsNothing);
    final enabledLabel = find.text(S.current.enabled);
    await tester.ensureVisible(enabledLabel);
    await tester.pumpAndSettle();
    expect(enabledLabel, findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Widget _app(
  Widget child, {
  String? route,
  bool dark = false,
  double scale = 1,
}) => GetMaterialApp(
  theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  locale: const Locale('en'),
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: route == null ? child : null,
  initialRoute: route,
  getPages: route == null ? null : [GetPage(name: route, page: () => child)],
);
