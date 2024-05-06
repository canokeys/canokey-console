import 'package:canokey_console/controller/layout/layout_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';
import 'package:canokey_console/helper/widgets/my_responsiv.dart';
import 'package:canokey_console/helper/widgets/my_spacing.dart';
import 'package:canokey_console/helper/widgets/my_text.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/views/layout/left_bar.dart';
import 'package:canokey_console/views/layout/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Layout extends StatelessWidget {
  static bool notSupported = false;

  final Widget? child;
  final String title;
  final Widget? topActions;

  final LayoutController controller = LayoutController();
  final topBarTheme = AdminTheme.theme.topBarTheme;
  final contentTheme = AdminTheme.theme.contentTheme;

  Layout({super.key, this.child, this.topActions, this.title = ""});

  @override
  Widget build(BuildContext context) {
    return MyResponsive(builder: (BuildContext context, _, screenMT) {
      return GetBuilder(
          init: controller,
          builder: (_) {
            if (notSupported) return notSupportedScreen();
            return screenMT.isMobile ? mobileScreen() : largeScreen();
          });
    });
  }

  Widget mobileScreen() {
    return Scaffold(
      key: controller.scaffoldKey,
      appBar: AppBar(elevation: 0, centerTitle: true, title: MyText.titleMedium(title), actions: [topActions!, MySpacing.width(20)]),
      drawer: LeftBar(),
      body: SingleChildScrollView(key: controller.scrollKey, child: child),
    );
  }

  Widget notSupportedScreen() {
    return Scaffold(
      key: controller.scaffoldKey,
      appBar: AppBar(elevation: 0, centerTitle: true, title: MyText.titleMedium('CanoKey Console')),
      body: SingleChildScrollView(
          key: controller.scrollKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MySpacing.height(MediaQuery.of(Get.context!).size.height / 2 - 100),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(S.of(Get.context!).browserNotSupported, style: TextStyle(fontSize: 18.0)),
                ],
              ),
            ],
          )),
    );
  }

  Widget largeScreen() {
    return Scaffold(
      key: controller.scaffoldKey,
      body: Row(
        children: [
          LeftBar(isCondensed: ThemeCustomizer.instance.leftBarCondensed),
          Expanded(
              child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                left: 0,
                bottom: 0,
                child: SingleChildScrollView(padding: MySpacing.fromLTRB(0, 58 + flexSpacing, 0, flexSpacing), key: controller.scrollKey, child: child),
              ),
              Positioned(top: 0, left: 0, right: 0, child: TopBar(actions: topActions)),
            ],
          )),
        ],
      ),
    );
  }

  static bool hasSidebar() {
    return MyScreenMedia.getTypeFromWidth(MediaQuery.of(Get.context!).size.width).isMobile;
  }
}
