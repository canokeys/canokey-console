import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_container.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InfoItem extends StatelessWidget with UIMixin {
  final IconData iconData;
  final String title;
  final String value;
  final GestureTapCallback? onTap;

  const InfoItem({
    super.key,
    required this.iconData,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          CustomizedContainer(paddingAll: 4, height: 32, width: 32, child: Icon(iconData, size: 20)),
          Spacing.width(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomizedText.bodyMedium(title, fontSize: 16, fontWeight: 600),
                if (value.isNotEmpty) ...{
                  if (onTap == null) // Can be copied
                    InkWell(
                      child: CustomizedText.bodySmall(value),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: value));
                        Prompts.showPrompt(S.of(context).copied, ContentThemeColor.success);
                      },
                    )
                  else
                    CustomizedText.bodySmall(value)
                }
              ],
            ),
          ),
          if (onTap != null) const Icon(Icons.arrow_forward_ios),
        ],
      ),
    );
  }
}
