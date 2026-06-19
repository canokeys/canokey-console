import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/shadow.dart';
import 'package:canokey_console/helper/widgets/customized_card.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';

class OpenPgpSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const OpenPgpSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final contentTheme = AdminTheme.theme.contentTheme;
    return CustomizedCard(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shadow: Shadow(elevation: 0.5, position: ShadowPosition.bottom),
      paddingAll: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: contentTheme.primary.withValues(alpha: 0.2),
            padding: Spacing.xy(16, 12),
            child: Row(
              children: [
                Icon(icon, color: contentTheme.primary, size: 16),
                Spacing.width(12),
                CustomizedText.titleMedium(
                  title,
                  fontWeight: 600,
                  color: contentTheme.primary,
                ),
              ],
            ),
          ),
          Padding(
            padding: Spacing.xy(flexSpacing, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}
