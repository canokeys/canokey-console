import 'dart:io';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/services/url_service.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';
import 'package:canokey_console/helper/utils/my_shadow.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/my_card.dart';
import 'package:canokey_console/helper/widgets/my_container.dart';
import 'package:canokey_console/helper/widgets/my_spacing.dart';
import 'package:canokey_console/helper/widgets/my_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

typedef LeftbarMenuFunction = void Function(String key);

class LeftbarObserver {
  static Map<String, LeftbarMenuFunction> observers = {};

  static attachListener(String key, LeftbarMenuFunction fn) {
    observers[key] = fn;
  }

  static detachListener(String key) {
    observers.remove(key);
  }

  static notifyAll(String key) {
    for (var fn in observers.values) {
      fn(key);
    }
  }
}

class LeftBar extends StatefulWidget {
  final bool isCondensed;

  const LeftBar({Key? key, this.isCondensed = false}) : super(key: key);

  @override
  _LeftBarState createState() => _LeftBarState();
}

class _LeftBarState extends State<LeftBar> with SingleTickerProviderStateMixin, UIMixin {
  final ThemeCustomizer customizer = ThemeCustomizer.instance;

  bool isCondensed = false;
  String path = UrlService.getCurrentUrl();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    isCondensed = widget.isCondensed;
    return MyCard(
      paddingAll: 0,
      shadow: MyShadow(position: MyShadowPosition.centerRight, elevation: 0.2),
      child: AnimatedContainer(
        color: leftBarTheme.background,
        width: isCondensed ? 70 : 260,
        curve: Curves.easeInOut,
        duration: Duration(milliseconds: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!kIsWeb && Platform.isIOS) MySpacing.height(60),
            SizedBox(
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(child: Image.asset('assets/images/logo/logo_icon_dark.png', height: widget.isCondensed ? 24 : 32)),
                  if (!widget.isCondensed)
                    Flexible(
                      fit: FlexFit.loose,
                      child: MySpacing.width(16),
                    ),
                  if (!widget.isCondensed)
                    Flexible(
                      fit: FlexFit.loose,
                      child: MyText.labelLarge(
                        "CanoKey",
                        style: GoogleFonts.raleway(fontSize: 24, fontWeight: FontWeight.w800, color: contentTheme.primary, letterSpacing: 1),
                        maxLines: 1,
                      ),
                    )
                ],
              ),
            ),
            Expanded(
                child: SingleChildScrollView(
              physics: PageScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  labelWidget(S.of(context).applets),
                  // NavigationItem(
                  //   iconData: LucideIcons.key,
                  //   title: "WebAuthn",
                  //   isCondensed: isCondensed,
                  //   route: '/applets/webauthn',
                  // ),
                  NavigationItem(
                    iconData: LucideIcons.timer,
                    title: "TOTP / HOTP",
                    isCondensed: isCondensed,
                    route: '/applets/oath',
                  ),
                  NavigationItem(
                    iconData: LucideIcons.keyboard,
                    title: "Pass",
                    isCondensed: isCondensed,
                    route: '/applets/pass',
                  ),
                  // NavigationItem(
                  //   iconData: LucideIcons.creditCard,
                  //   title: "PIV",
                  //   isCondensed: isCondensed,
                  //   route: '/applets/piv',
                  // ),
                  // NavigationItem(
                  //   iconData: LucideIcons.lock,
                  //   title: "OpenPGP",
                  //   isCondensed: isCondensed,
                  //   route: '/applets/openpgp',
                  // ),
                  labelWidget(S.of(context).other),
                  NavigationItem(
                    iconData: LucideIcons.settings,
                    title: S.of(context).settings,
                    isCondensed: isCondensed,
                    route: '/settings',
                  ),
                  NavigationItem(
                    iconData: LucideIcons.info,
                    title: S.of(context).about,
                    isCondensed: isCondensed,
                    route: '/about',
                  ),
                ],
              ),
            ))
          ],
        ),
      ),
    );
  }

  Widget labelWidget(String label) {
    return isCondensed
        ? MySpacing.empty()
        : Container(
            padding: MySpacing.xy(24, 8),
            child: MyText.labelSmall(
              label.toUpperCase(),
              color: leftBarTheme.labelColor,
              muted: true,
              maxLines: 1,
              overflow: TextOverflow.clip,
              fontWeight: 700,
            ),
          );
  }
}

class NavigationItem extends StatefulWidget {
  final IconData? iconData;
  final String title;
  final bool isCondensed;
  final String? route;

  const NavigationItem({Key? key, this.iconData, required this.title, this.isCondensed = false, this.route}) : super(key: key);

  @override
  _NavigationItemState createState() => _NavigationItemState();
}

class _NavigationItemState extends State<NavigationItem> with UIMixin {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    bool isActive = UrlService.getCurrentUrl() == widget.route;
    return GestureDetector(
      onTap: () {
        if (widget.route != null) {
          Get.toNamed(widget.route!);
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onHover: (event) {
          setState(() => isHover = true);
        },
        onExit: (event) {
          setState(() => isHover = false);
        },
        child: MyContainer.transparent(
          margin: MySpacing.fromLTRB(16, 0, 16, 8),
          color: isActive || isHover ? leftBarTheme.activeItemBackground : Colors.transparent,
          padding: MySpacing.xy(8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.iconData != null)
                Center(
                  child: Icon(widget.iconData, color: (isHover || isActive) ? leftBarTheme.activeItemColor : leftBarTheme.onBackground, size: 20),
                ),
              if (!widget.isCondensed) Flexible(fit: FlexFit.loose, child: MySpacing.width(16)),
              if (!widget.isCondensed)
                Expanded(
                  flex: 3,
                  child: MyText.labelLarge(widget.title,
                      overflow: TextOverflow.clip, maxLines: 1, color: isActive || isHover ? leftBarTheme.activeItemColor : leftBarTheme.onBackground),
                )
            ],
          ),
        ),
      ),
    );
  }
}
