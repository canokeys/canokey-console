import 'package:canokey_console/controller/applets/webauthn/webauthn_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/models/webauthn.dart';
import 'package:canokey_console/views/applets/webauthn/dialogs/delete_dialog.dart';
import 'package:canokey_console/views/applets/webauthn/dialogs/view_user_id_dialog.dart';
import 'package:canokey_console/views/applets/webauthn/webauthn_page.dart';
import 'package:canokey_console/views/applets/webauthn/widgets/webauthn_credential_grid.dart';
import 'package:canokey_console/views/applets/webauthn/widgets/webauthn_item_card.dart';
import 'package:fido2/fido2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Controller extends WebAuthnController {
  int deletes = 0;
  @override
  void onReady() {}
  @override
  Future<void> delete(PublicKeyCredentialDescriptor credentialId) async {
    deletes++;
  }
}

WebAuthnItem _item(int id, {bool long = false}) => WebAuthnItem(
  rpId: long ? '${'long-subdomain-' * 8}.example.com' : 'site$id.example.com',
  userName: long ? 'long-account-name' * 8 : 'account$id',
  userDisplayName: long ? 'Long display name ' * 8 : 'Person $id',
  userId: [65, 66, id],
  credentialId: PublicKeyCredentialDescriptor(type: 'public-key', id: [id]),
);

void main() {
  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });
  tearDown(Get.reset);

  testWidgets('cards resize and change column count with available width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final controller = _Controller();
    final items = List.generate(7, _item);
    for (final (width, columns) in [
      (390.0, 1),
      (820.0, 2),
      (1000.0, 2),
      (1240.0, 3),
      (1700.0, 4),
    ]) {
      tester.view.physicalSize = Size(width, 1800);
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SingleChildScrollView(
              child: WebAuthnCredentialGrid(
                items: items,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cards = find.byType(WebAuthnItemCard);
      final first = tester.getRect(cards.first);
      expect(first.width, closeTo((width - 16 * (columns - 1)) / columns, .01));
      for (var i = 0; i < columns; i++) {
        expect(tester.getRect(cards.at(i)).top, first.top);
      }
      expect(tester.getRect(cards.at(columns)).top, greaterThan(first.bottom));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: WebAuthnCredentialGrid(
            items: [items.first],
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(WebAuthnItemCard)).width, 1700);
  });

  testWidgets(
    'long card content fits narrow screens and large text in both themes',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 1000);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final dark in [false, true]) {
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: SingleChildScrollView(
                child: WebAuthnCredentialGrid(
                  items: [_item(1, long: true)],
                  controller: _Controller(),
                ),
              ),
            ),
            dark: dark,
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find
              .byTooltip(
                MaterialLocalizations.of(
                  tester.element(find.byType(WebAuthnItemCard)),
                ).moreButtonTooltip,
              )
              .hitTestable(),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets('menu opens user ID and requires confirmation before deletion', (
    tester,
  ) async {
    final controller = _Controller();
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: WebAuthnCredentialGrid(
            items: [_item(1)],
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byTooltip(
        MaterialLocalizations.of(
          tester.element(find.byType(WebAuthnItemCard)),
        ).moreButtonTooltip,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.viewUserId));
    await tester.pumpAndSettle();
    expect(find.byType(WebAuthnViewUserIdDialog), findsOneWidget);
    Get.back();
    await tester.pumpAndSettle();
    await tester.tap(
      find.byTooltip(
        MaterialLocalizations.of(
          tester.element(find.byType(WebAuthnItemCard)),
        ).moreButtonTooltip,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.delete));
    await tester.pumpAndSettle();
    expect(find.byType(WebAuthnDeleteDialog), findsOneWidget);
    expect(controller.deletes, 0);
    await tester.tap(find.text(S.current.cancel));
    await tester.pumpAndSettle();
    expect(controller.deletes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('page searches usernames and retains header for empty results', (
    tester,
  ) async {
    final controller = _Controller()
      ..polled = true
      ..webAuthnItems.addAll([_item(1), _item(2)]);
    Get.put<WebAuthnController>(controller);
    await tester.pumpWidget(
      _app(const WebAuthnPage(), route: '/applets/webauthn'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WebAuthnItemCard), findsNWidgets(2));
    await tester.enterText(find.byType(TextFormField), 'ACCOUNT2');
    await tester.pumpAndSettle();
    expect(find.byType(WebAuthnItemCard), findsOneWidget);
    expect(find.text('Person 2'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'no-match');
    await tester.pumpAndSettle();
    expect(find.text(S.current.noMatchingCredential), findsOneWidget);
    expect(find.text(S.current.webAuthnCredentials), findsOneWidget);
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
