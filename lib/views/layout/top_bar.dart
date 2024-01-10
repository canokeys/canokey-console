import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';
import 'package:canokey_console/helper/utils/my_shadow.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/my_card.dart';
import 'package:canokey_console/helper/widgets/my_spacing.dart';
import 'package:canokey_console/helper/widgets/my_text_style.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TopBar extends StatefulWidget {
  final Widget? actions;

  TopBar({super.key, this.actions});

  @override
  _TopBarState createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> with SingleTickerProviderStateMixin, UIMixin {
  @override
  Widget build(BuildContext context) {
    return MyCard(
      shadow: MyShadow(position: MyShadowPosition.bottomRight, elevation: 0.5),
      height: 60,
      borderRadiusAll: 0,
      padding: MySpacing.x(24),
      color: topBarTheme.background.withAlpha(246),
      child: Row(
        children: [
          Row(
            children: [
              InkWell(
                  splashColor: theme.colorScheme.onBackground,
                  highlightColor: theme.colorScheme.onBackground,
                  onTap: () {
                    ThemeCustomizer.toggleLeftBarCondensed();
                  },
                  child: Icon(LucideIcons.menu, color: topBarTheme.onBackground)),
              MySpacing.width(24),
              SizedBox(
                width: 200,
                child: TextFormField(
                  maxLines: 1,
                  style: MyTextStyle.bodyMedium(),
                  decoration: InputDecoration(
                      hintText: "search",
                      hintStyle: MyTextStyle.bodySmall(xMuted: true),
                      border: outlineInputBorder,
                      enabledBorder: outlineInputBorder,
                      focusedBorder: focusedInputBorder,
                      prefixIcon: const Align(alignment: Alignment.center, child: Icon(LucideIcons.search, size: 14)),
                      prefixIconConstraints: const BoxConstraints(minWidth: 36, maxWidth: 36, minHeight: 32, maxHeight: 32),
                      contentPadding: MySpacing.xy(16, 12),
                      isCollapsed: true,
                      floatingLabelBehavior: FloatingLabelBehavior.never),
                ),
              ),
            ],
          ),
          Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [widget.actions ?? Container()]))
        ],
      ),
    );
  }
}
