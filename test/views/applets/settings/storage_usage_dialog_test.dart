import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/views/applets/settings/dialogs/storage_usage_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('uses natural height when storage usage content is short', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _app(
        StorageUsage(
          usedKiB: 1,
          totalKiB: 8,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final content = find.byWidgetPredicate(
      (widget) => widget is SizedBox && widget.width == AppDialogWidth.medium,
    );
    expect(content, findsOneWidget);
    expect(tester.getSize(content).height, lessThan(800));
    expect(find.text('Close'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(StorageUsage storageUsage) {
  return GetMaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: StorageUsageDialog(storageUsage: storageUsage),
  );
}
