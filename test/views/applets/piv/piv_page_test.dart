import 'package:canokey_console/controller/applets/piv/piv_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/poll_canokey_screen.dart';
import 'package:canokey_console/views/applets/piv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('waits for a card without polling on page open', (tester) async {
    final controller = _TestPivController();
    Get.put<PivController>(controller);

    await tester.pumpWidget(_app());
    await tester.pump();

    expect(controller.refreshCount, 0);
    expect(find.byType(PollCanoKeyScreen), findsOneWidget);
    expect(
      find.text('Please read your CanoKey by clicking the refresh button'),
      findsNothing,
    );
    expect(find.byTooltip('PIV Algorithm IDs'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await Get.delete<PivController>(force: true);
  });
}

class _TestPivController extends PivController {
  int refreshCount = 0;

  @override
  void onReady() {}

  @override
  Future<void> doRefreshData() async {
    refreshCount++;
  }
}

Widget _app() {
  return GetMaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: const PivPage(),
  );
}
