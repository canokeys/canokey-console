import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';

class AppletDisabledScreen extends StatelessWidget {
  final String message;

  const AppletDisabledScreen({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final contentTheme = AdminTheme.theme.contentTheme;
    final iconColor = contentTheme.warning;
    final textColor = contentTheme.onBackground;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Spacing.height(MediaQuery.of(context).size.height / 2 - 150),
        Center(
          child: Padding(
            padding: Spacing.horizontal(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.shieldAlert, color: iconColor, size: 40),
                Spacing.height(16),
                CustomizedText.bodyMedium(
                  message,
                  color: textColor,
                  fontSize: 24,
                  fontWeight: 600,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
