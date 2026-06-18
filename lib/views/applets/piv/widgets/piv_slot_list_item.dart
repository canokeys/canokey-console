import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/customized_container.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:flutter/material.dart';

class PivSlotListItem extends StatelessWidget {
  final String title;
  final String slotNumber;
  final SlotInfo? slot;
  final VoidCallback onTap;

  const PivSlotListItem({
    super.key,
    required this.title,
    required this.slotNumber,
    required this.slot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          CustomizedContainer(
            paddingAll: 4,
            height: 32,
            width: 32,
            child: Icon(LucideIcons.fileLock, size: 20),
          ),
          Spacing.width(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomizedText.bodyMedium('$title - $slotNumber', fontSize: 16),
                if (slot != null) ...[
                  CustomizedText.bodySmall(
                    '${S.of(context).pivAlgorithm}: ${slot!.algorithm.name.toUpperCase()}',
                  ),
                  CustomizedText.bodySmall(
                    '${S.of(context).pivCertificate}: ${slot!.cert?.subject.isNotEmpty == true ? slot!.cert!.subject : S.of(context).pivEmpty}',
                  ),
                ] else ...[
                  CustomizedText.bodySmall(S.of(context).pivEmpty),
                ],
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios),
        ],
      ),
    );
  }
}
