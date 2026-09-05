import 'package:canokey_console/controller/base/layout_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/views/layout/left_bar.dart';
import 'package:canokey_console/views/layout/top_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:platform_detector/platform_detector.dart';

class Layout extends StatelessWidget {
  static bool notSupported = false;

  final Widget? child;
  final String title;
  final Widget? topActions;
  final Future<void> Function()? onRefresh;

  final LayoutController controller = LayoutController();
  final topBarTheme = AdminTheme.theme.topBarTheme;
  final contentTheme = AdminTheme.theme.contentTheme;

  Layout({
    super.key,
    this.child,
    this.topActions,
    this.onRefresh,
    this.title = "",
  });

  @override
  Widget build(BuildContext context) {
    return Responsive(builder: (BuildContext context, _, screenMT) {
      return _KeyboardStablePage(
        child: GetBuilder(
            init: controller,
            builder: (_) {
              if (notSupported) return notSupportedScreen();
              return screenMT.isMobile
                  ? mobileScreen(context)
                  : largeScreen(context);
            }),
      );
    });
  }

  Widget mobileScreen(BuildContext context) {
    final canPullToRefresh = isIOSApp() && onRefresh != null;

    return Scaffold(
      key: controller.scaffoldKey,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leadingWidth: 48,
        titleSpacing: 8,
        title: CustomizedText.titleMedium(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: topActions == null
            ? null
            : [
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: IconButtonTheme(
                      data: IconButtonThemeData(
                        style: IconButton.styleFrom(
                          minimumSize: const Size.square(48),
                          maximumSize: const Size.square(48),
                          padding: const EdgeInsets.all(8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      child: topActions!,
                    ),
                  ),
                ),
              ],
      ),
      drawer: LeftBar(),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          key: controller.scrollKey,
          physics: canPullToRefresh
              ? const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                )
              : null,
          slivers: [
            if (canPullToRefresh)
              CupertinoSliverRefreshControl(onRefresh: onRefresh!),
            SliverToBoxAdapter(child: child ?? const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget notSupportedScreen() {
    return Scaffold(
      key: controller.scaffoldKey,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: CustomizedText.titleMedium('CanoKey Console')),
      body: SingleChildScrollView(
          key: controller.scrollKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacing.height(MediaQuery.of(Get.context!).size.height / 2 - 150),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(S.of(Get.context!).browserNotSupported,
                      style: TextStyle(fontSize: 18.0)),
                ],
              ),
            ],
          )),
    );
  }

  Widget largeScreen(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Scaffold(
      key: controller.scaffoldKey,
      resizeToAvoidBottomInset: false,
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
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                      padding: Spacing.fromLTRB(
                          0, topInset + 58 + flexSpacing, 0, flexSpacing),
                      key: controller.scrollKey,
                      child: child),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  left: false,
                  right: false,
                  bottom: false,
                  child: TopBar(actions: topActions),
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  static bool hasSidebar() {
    return ScreenMedia.getTypeFromWidth(MediaQuery.sizeOf(Get.context!).width)
        .isMobile;
  }
}

class _KeyboardStablePage extends StatelessWidget {
  final Widget child;

  const _KeyboardStablePage({required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        padding: mediaQuery.viewPadding,
        viewInsets: EdgeInsets.zero,
      ),
      child: child,
    );
  }
}
