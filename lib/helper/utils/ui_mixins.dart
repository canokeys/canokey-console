import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/widgets/dashed_divider.dart';
import 'package:canokey_console/helper/widgets/navigation_mixin.dart';
import 'package:flutter/material.dart';

mixin UIMixin {
  // ThemeData get theme => AppStyle.theme;
  LeftBarTheme get leftBarTheme => AdminTheme.theme.leftBarTheme;

  TopBarTheme get topBarTheme => AdminTheme.theme.topBarTheme;

  ContentTheme get contentTheme => AdminTheme.theme.contentTheme;

  VisualDensity get getCompactDensity => const VisualDensity(horizontal: -4, vertical: -4);

  // theme.colorScheme. get theme.colorScheme. => theme.theme.colorScheme.;

  OutlineInputBorder get outlineInputBorder => OutlineInputBorder(
        borderRadius: const BorderRadius.all(const Radius.circular(4)),
        borderSide: BorderSide(width: 1, strokeAlign: 0, color: theme.colorScheme.onSurface.withAlpha(80)),
      );

  OutlineInputBorder get focusedInputBorder => OutlineInputBorder(
        borderRadius: const BorderRadius.all(const Radius.circular(4)),
        borderSide: BorderSide(width: 1, color: theme.colorScheme.primary),
      );

  OutlineInputBorder generateOutlineInputBorder({double radius = 4}) => OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        borderSide: const BorderSide(
          color: Colors.transparent,
        ),
      );

  OutlineInputBorder generateFocusedInputBorder({double radius = 4}) => OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        borderSide: BorderSide(width: 1, color: theme.colorScheme.primary),
      );

  Widget getBackButton(NavigationMixin navigationMixin) {
    return InkWell(
      onTap: navigationMixin.goBack,
      child: Center(
        child: Icon(Icons.chevron_left_rounded, size: 26, color: theme.colorScheme.onSurface),
      ),
    );
  }

  Widget getDashedDivider() {
    return DashedDivider(dashWidth: 6, dashSpace: 4, color: theme.colorScheme.onSurface.withAlpha(64), height: 0.5);
  }
}
