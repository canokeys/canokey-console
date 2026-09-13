import 'package:canokey_console/helper/widgets/applet_section_card.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/views/applets/settings/dialogs/storage_usage_dialog.dart';
import 'package:canokey_console/views/applets/settings/widgets/info_item.dart';
import 'package:canokey_console/views/applets/settings/widgets/settings_surface.dart';
import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final CanoKey canokey;
  const InfoCard({super.key, required this.canokey});

  @override
  Widget build(BuildContext context) {
    final storage = canokey.storageUsage;
    final ratio = storage == null || storage.totalKiB <= 0
        ? null
        : (storage.usedKiB / storage.totalKiB).clamp(0.0, 1.0);
    return AppletSectionCard(
      icon: LucideIcons.info,
      title: S.of(context).settingsInfo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomizedText.titleLarge(
            canokey.model,
            fontSize: 22,
            fontWeight: 600,
          ),
          const SizedBox(height: 12),
          SettingsRows(
            children: [
              InfoItem(
                title: S.of(context).settingsFirmwareVersion,
                value: canokey.firmwareVersion,
              ),
              if (canokey.coreCommit != null)
                InfoItem(
                  title: S.of(context).settingsCoreCommit,
                  value: canokey.coreCommit!,
                ),
              InfoItem(title: S.of(context).settingsSN, value: canokey.sn),
              InfoItem(
                title: S.of(context).settingsChipId,
                value: canokey.chipId,
              ),
              if (storage != null)
                InfoItem(
                  title: S.of(context).settingsStorageUsage,
                  value:
                      '${storage.usedKiB} / ${storage.totalKiB} KiB${ratio == null ? '' : ' (${(ratio * 100).round()}%)'}',
                  onTap: () => StorageUsageDialog.show(storage),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
