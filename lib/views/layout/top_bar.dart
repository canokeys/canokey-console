import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';
import 'package:canokey_console/helper/utils/shadow.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_card.dart';
import 'package:canokey_console/helper/widgets/search_box.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TopBar extends StatefulWidget {
  final Widget? actions;

  TopBar({super.key, this.actions});

  @override
  _TopBarState createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> with SingleTickerProviderStateMixin, UIMixin {
  final GlobalKey<FormState> _searchFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return CustomizedCard(
      shadow: Shadow(position: ShadowPosition.bottomRight, elevation: 0.5),
      height: 60,
      borderRadiusAll: 0,
      padding: Spacing.x(24),
      color: topBarTheme.background.withAlpha(246),
      child: Row(
        children: [
          InkWell(
            splashColor: theme.colorScheme.onSurface,
            highlightColor: theme.colorScheme.onSurface,
            onTap: () => ThemeCustomizer.toggleLeftBarCondensed(),
            child: Icon(LucideIcons.menu, color: topBarTheme.onBackground),
          ),
          if (['/applets/oath', '/applets/webauthn'].contains(Get.currentRoute)) ...{
            Spacing.width(24),
            Expanded(
              child: SearchBox(formKey: _searchFormKey),
            )
          },
          if (widget.actions != null) Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [widget.actions!]))
        ],
      ),
    );
  }
}
