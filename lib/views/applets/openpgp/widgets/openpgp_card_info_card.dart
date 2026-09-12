import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:canokey_console/helper/widgets/applet_section_card.dart';
import 'package:canokey_console/views/applets/settings/widgets/info_item.dart';
import 'package:flutter/material.dart';

class OpenPgpCardInfoCard extends StatelessWidget {
  final OpenPgpCardInfo info;
  const OpenPgpCardInfoCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return AppletSectionCard(
      clipBehavior: Clip.none,
      titleColor: Theme.of(context).colorScheme.onSurface,
      icon: LucideIcons.info,
      title: S.of(context).openpgpCardInfo,
      child: Column(
        children: [
          InfoItem(
            iconData: LucideIcons.info,
            title: S.of(context).openpgpVersion,
            value: _value(info.version),
          ),
          Divider(height: 1, color: AppletStyle.border(context)),
          InfoItem(
            iconData: LucideIcons.cpu,
            title: S.of(context).openpgpManufacturer,
            value: _value(info.manufacturer),
          ),
          Divider(height: 1, color: AppletStyle.border(context)),
          InfoItem(
            iconData: LucideIcons.hash,
            title: S.of(context).openpgpSN,
            value: _value(info.serialNumber),
          ),
          Divider(height: 1, color: AppletStyle.border(context)),
          InfoItem(
            iconData: LucideIcons.user,
            title: S.of(context).openpgpCardHolder,
            value: _value(info.cardHolder),
          ),
          Divider(height: 1, color: AppletStyle.border(context)),
          InfoItem(
            iconData: LucideIcons.globe,
            title: S.of(context).openpgpPubkeyUrl,
            value: _value(info.publicKeyUrl),
          ),
        ],
      ),
    );
  }

  String _value(String value) => value.isEmpty ? '-' : value;
}
