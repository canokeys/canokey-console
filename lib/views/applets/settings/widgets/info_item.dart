import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InfoItem extends StatelessWidget {
  final IconData? iconData;
  final String title;
  final String value;
  final GestureTapCallback? onTap;

  const InfoItem({
    super.key,
    this.iconData,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = CustomizedText.bodyMedium(title, fontSize: 14);
    final detail = CustomizedText.bodyMedium(value, fontSize: 14, muted: true);
    return InkWell(
      onTap:
          onTap ??
          (value.isEmpty
              ? null
              : () {
                  Clipboard.setData(ClipboardData(text: value));
                  Prompts.showPrompt(
                    S.of(context).copied,
                    ContentThemeColor.success,
                  );
                }),
      borderRadius: BorderRadius.circular(5),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            if (iconData != null) ...[
              Icon(iconData, size: 20),
              const SizedBox(width: 18),
            ],
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Stack long values on narrow screens and with larger text sizes.
                  final stacked =
                      constraints.maxWidth < 340 ||
                      MediaQuery.textScalerOf(context).scale(14) > 20;
                  if (stacked && value.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [label, const SizedBox(height: 4), detail],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(flex: 5, child: label),
                      if (value.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 6,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: detail,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 16),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
