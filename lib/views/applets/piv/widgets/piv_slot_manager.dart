import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:canokey_console/views/applets/piv/widgets/piv_slot_list_item.dart';
import 'package:flutter/material.dart';

class PivSlotManager extends StatelessWidget {
  const PivSlotManager({
    super.key,
    required this.slots,
    required this.retiredSlots,
    required this.hasCertificate,
    required this.onOpenSlot,
    this.onSetupMac,
  });

  final VoidCallback? onSetupMac;
  final Map<int, SlotInfo> slots;
  final List<int> retiredSlots;
  final bool Function(int) hasCertificate;
  final void Function(String, String, SlotInfo?) onOpenSlot;

  Widget _buildInfo(String title, String slotNumber, SlotInfo? slot) {
    final slotId = int.parse(slotNumber, radix: 16);
    return PivSlotListItem(
      title: title,
      slotNumber: slotNumber,
      slot: slot,
      hasCertificate: hasCertificate(slotId),
      onTap: () => onOpenSlot(title, slotNumber, slot),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainSlots = [
      (title: S.of(context).pivAuthentication, number: '9A'),
      (title: S.of(context).pivSignature, number: '9C'),
      (title: S.of(context).pivKeyManagement, number: '9D'),
      (title: S.of(context).pivCardAuthentication, number: '9E'),
    ];
    final occupied = retiredSlots
        .where((slot) => slots.containsKey(slot) || hasCertificate(slot))
        .length;
    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              S.of(context).pivMainSlots,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (var i = 0; i < mainSlots.length; i++) ...[
            _buildInfo(
              mainSlots[i].title,
              mainSlots[i].number,
              slots[int.parse(mainSlots[i].number, radix: 16)],
            ),
            if (i < mainSlots.length - 1)
              const Divider(height: 1, indent: 70, endIndent: 12),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          ExpansionTile(
            key: const PageStorageKey('piv-retired-slots'),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            title: Text(S.of(context).pivRetiredSlots),
            subtitle: Text(S.of(context).pivOccupiedSlots(occupied)),
            children: [
              for (final slot in retiredSlots)
                _buildInfo(
                  S.of(context).pivRetiredSlot(slot - 0x81),
                  slot.toRadixString(16).toUpperCase(),
                  slots[slot],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onSetupMac,
              icon: const Icon(Icons.laptop_mac),
              label: Text(S.of(context).pivMacSetupTitle),
            ),
          ),
        ],
      ),
    );
  }
}
