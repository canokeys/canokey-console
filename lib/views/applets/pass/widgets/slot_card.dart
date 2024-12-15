import 'package:canokey_console/controller/applets/pass.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/shadow.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_card.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:canokey_console/views/applets/pass/dialogs/slot_config_dialog.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SlotCard extends StatelessWidget with UIMixin {
  final String title;
  final PassSlot slot;
  final int slotIndex;
  final PassController controller;

  const SlotCard({super.key, required this.title, required this.slot, required this.slotIndex, required this.controller});

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
                Icon(LucideIcons.keyboard, color: contentTheme.primary, size: 16),
                Spacing.width(12),
                CustomizedText.titleMedium(title, fontWeight: 600, color: contentTheme.primary)
              ],
            ),
          ),
          Padding(
            padding: Spacing.xy(20, 16),
            child: _buildInfo(
              LucideIcons.shieldCheck,
              S.of(context).passStatus,
              _slotStatus(slot, context),
              () => SlotConfigDialog.show(index: slotIndex, slot: slot, onSetSlot: controller.setSlot),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(IconData iconData, String title, String value, GestureTapCallback handler) {
    return InkWell(
      onTap: handler,
      child: Row(
        children: [
          Container(padding: Spacing.all(4), height: 32, width: 32, child: Icon(iconData, size: 20)),
          Spacing.width(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomizedText.bodyMedium(title, fontSize: 16),
                CustomizedText.bodySmall(value),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios)
        ],
      ),
    );
  }

  String _slotStatus(PassSlot slot, BuildContext context) {
    switch (slot.type) {
      case PassSlotType.none:
        return S.of(context).passSlotOff;
      case PassSlotType.oath:
        return '${S.of(context).passSlotHotp} (${slot.name})';
      case PassSlotType.static:
        return S.of(context).passSlotStatic;
    }
  }
}
