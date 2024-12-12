import 'package:canokey_console/controller/applets/oath/oath_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/shadow.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_card.dart';
import 'package:canokey_console/helper/widgets/customized_container.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:timer_controller/timer_controller.dart';

class OathItemCard extends StatelessWidget with UIMixin {
  final String name;
  final OathItem item;
  final OathController controller;
  final Function(String) onDelete;
  final Function(String) onSetDefault;

  OathItemCard({
    super.key,
    required this.name,
    required this.item,
    required this.controller,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return CustomizedCard(
      shadow: Shadow(elevation: 0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomizedText.bodyMedium(item.issuer, fontSize: 16, fontWeight: 600),
              CustomizedContainer.none(
                paddingAll: 8,
                borderRadiusAll: 5,
                child: PopupMenuButton(
                  offset: const Offset(0, 10),
                  position: PopupMenuPosition.under,
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      padding: Spacing.xy(16, 8),
                      height: 10,
                      child: CustomizedText.bodySmall(S.of(context).delete),
                      onTap: () => onDelete(name),
                    ),
                    if (item.type == OathType.hotp)
                      PopupMenuItem(
                        padding: Spacing.xy(16, 8),
                        height: 10,
                        child: CustomizedText.bodySmall(S.of(context).oathSetDefault),
                        onTap: () => onSetDefault(name),
                      ),
                  ],
                  child: const Icon(LucideIcons.moreHorizontal, size: 18),
                ),
              ),
            ],
          ),
          Row(
            children: [
              CustomizedContainer.rounded(
                color: contentTheme.primary.withAlpha(30),
                paddingAll: 2,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: Icon(LucideIcons.user, size: 16, color: contentTheme.primary),
              ),
              Spacing.width(12),
              CustomizedText.bodyMedium(item.account),
            ],
          ),
          Row(
            children: [
              if (item.type == OathType.hotp)
                IconButton(
                  onPressed: () => controller.calculate(name, item.type),
                  icon: Icon(LucideIcons.refreshCw, size: 20, color: contentTheme.primary),
                ),
              if (item.type == OathType.totp && item.code.isNotEmpty)
                TimerControllerBuilder(
                  controller: controller.timerController,
                  builder: (_, value, __) => CircularPercentIndicator(
                    radius: 20,
                    lineWidth: 5,
                    percent: 1 - value.remaining / 30,
                    center: Text(value.remaining.toString()),
                    progressColor: contentTheme.primary,
                    backgroundColor: contentTheme.primary.withAlpha(30),
                  ),
                ),
              if (item.type == OathType.totp && item.code.isEmpty && item.requireTouch)
                IconButton(
                  onPressed: () => controller.calculate(name, item.type),
                  icon: Icon(Icons.touch_app, size: 20, color: contentTheme.primary),
                ),
              if (item.type == OathType.totp && item.code.isEmpty && !item.requireTouch)
                CircularPercentIndicator(
                  radius: 20,
                  lineWidth: 5,
                  percent: 0,
                  center: Text("0"),
                  progressColor: contentTheme.primary,
                  backgroundColor: contentTheme.primary.withAlpha(30),
                ),
              Spacing.width(16),
              CustomizedText.bodyMedium(
                item.code.isEmpty ? '******' : item.code,
                style: GoogleFonts.robotoMono(fontSize: 28),
              ),
              Spacing.width(16),
              IconButton(
                color: item.code.isEmpty ? contentTheme.cardTextMuted : contentTheme.primary,
                onPressed: () {
                  if (item.code.isEmpty) return;
                  Clipboard.setData(ClipboardData(text: item.code));
                  Prompts.showPrompt('Copied', ContentThemeColor.success);
                },
                icon: Icon(LucideIcons.copy, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
