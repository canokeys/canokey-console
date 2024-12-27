import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/shadow.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_card.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/views/applets/settings/widgets/info_item.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class InfoCard extends StatelessWidget with UIMixin {
  final CanoKey canokey;

  const InfoCard({super.key, required this.canokey});

  @override
  Widget build(BuildContext context) {
    return CustomizedCard(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shadow: Shadow(elevation: 0.5, position: ShadowPosition.bottom),
      paddingAll: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: contentTheme.primary.withOpacity(0.08),
            padding: Spacing.xy(16, 12),
            child: Row(
              children: [
                Icon(LucideIcons.keyRound, color: contentTheme.primary, size: 16),
                Spacing.width(12),
                CustomizedText.titleMedium(S.of(context).settingsInfo, fontWeight: 600, color: contentTheme.primary)
              ],
            ),
          ),
          Padding(
            padding: Spacing.xy(flexSpacing, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoItem(iconData: LucideIcons.shieldCheck, title: S.of(context).settingsModel, value: canokey.model),
                Spacing.height(16),
                InfoItem(iconData: LucideIcons.info, title: S.of(context).settingsFirmwareVersion, value: canokey.firmwareVersion),
                Spacing.height(16),
                InfoItem(iconData: LucideIcons.hash, title: S.of(context).settingsSN, value: canokey.sn),
                Spacing.height(16),
                InfoItem(iconData: LucideIcons.cpu, title: S.of(context).settingsChipId, value: canokey.chipId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
