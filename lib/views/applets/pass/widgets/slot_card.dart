import 'package:canokey_console/controller/applets/pass/pass_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:canokey_console/views/applets/pass/dialogs/slot_config_dialog.dart';
import 'package:flutter/material.dart';

class SlotCard extends StatelessWidget {
  final String title;
  final PassSlot slot;
  final int slotIndex;
  final PassController controller;

  const SlotCard({
    super.key,
    required this.title,
    required this.slot,
    required this.slotIndex,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xff009b83);
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final border = dark ? const Color(0xff35414c) : const Color(0xffe5edf2);
    return Material(
      color: dark ? const Color(0xff202b34) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: accent.withValues(alpha: .10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.keyboard, color: accent, size: 22),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomizedText.titleMedium(
                        title,
                        fontSize: 18,
                        fontWeight: 600,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => SlotConfigDialog.show(
                  index: slotIndex,
                  slot: slot,
                  hmacSha1Supported: controller.hmacSha1Supported,
                  onSetSlot: controller.setSlot,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 22,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.shieldCheck,
                        size: 28,
                        color: colors.onSurface,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomizedText.bodyLarge(
                              S.of(context).passStatus,
                              fontSize: 17,
                              color: colors.onSurface,
                            ),
                            const SizedBox(height: 5),
                            CustomizedText.bodyMedium(
                              _slotStatus(context),
                              color: colors.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.chevron_right,
                        size: 28,
                        color: colors.onSurface,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _slotStatus(BuildContext context) => switch (slot.type) {
    PassSlotType.none => S.of(context).passSlotOff,
    PassSlotType.oath => '${S.of(context).passSlotHotp} (${slot.name})',
    PassSlotType.static => S.of(context).passSlotStatic,
    PassSlotType.hmacSha1 => S.of(context).passSlotHmacSha1,
  };
}
