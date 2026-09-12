import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:canokey_console/views/applets/piv/widgets/piv_slot_list_item.dart';
import 'package:flutter/material.dart';
import 'piv_surface.dart';

class PivSlotManager extends StatelessWidget {
  const PivSlotManager({
    super.key,
    required this.slots,
    required this.retiredSlots,
    required this.hasCertificate,
    required this.onOpenSlot,
    this.onSetupMac,
    this.credentialSettings,
    this.onImportSlot,
    this.onExportSlot,
    this.onGenerateSlot,
  });
  final VoidCallback? onSetupMac;
  final Widget? credentialSettings;
  final void Function(String)? onImportSlot, onExportSlot, onGenerateSlot;
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
      onImport: onImportSlot == null ? null : () => onImportSlot!(slotNumber),
      onExport: onExportSlot == null ? null : () => onExportSlot!(slotNumber),
      onGenerate:
          onGenerateSlot == null ||
              slot?.algorithm == AlgorithmType.x25519 ||
              slot?.algorithm == AlgorithmType.mlkem768
          ? null
          : () => onGenerateSlot!(slotNumber),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final mainSlots = [
      (title: s.pivAuthentication, number: '9A'),
      (title: s.pivSignature, number: '9C'),
      (title: s.pivKeyManagement, number: '9D'),
      (title: s.pivCardAuthentication, number: '9E'),
    ];
    final occupied = retiredSlots
        .where((slot) => slots.containsKey(slot) || hasCertificate(slot))
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PivSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) => PivSectionHeader(
                  icon: Icons.description_outlined,
                  title: s.pivSlotsTitle,
                  description: s.pivSlotsDescription,
                  trailing: constraints.maxWidth < 1000
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: PivStyle.muted(context),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              s.pivSlotsHint,
                              style: PivStyle.text(
                                context,
                                12,
                                secondary: true,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 952) {
                    return const SizedBox.shrink();
                  }
                  Widget label(String text) => Text(
                    text,
                    style: PivStyle.text(
                      context,
                      11,
                      bold: true,
                      secondary: true,
                    ),
                  );
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: PivStyle.soft(context),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: PivSlotColumns(
                      number: label(s.pivSlotColumn),
                      name: label(s.pivNameColumn),
                      algorithm: label(s.pivAlgorithmColumn),
                      status: label(s.passStatus),
                      actions: label(s.actions),
                      trailing: const SizedBox.shrink(),
                    ),
                  );
                },
              ),
              for (var i = 0; i < mainSlots.length; i++) ...[
                _buildInfo(
                  mainSlots[i].title,
                  mainSlots[i].number,
                  slots[int.parse(mainSlots[i].number, radix: 16)],
                ),
                if (i < mainSlots.length - 1)
                  Divider(height: 1, color: PivStyle.border(context)),
              ],
              const SizedBox(height: 8),
              Divider(height: 1, color: PivStyle.border(context)),
              ExpansionTile(
                key: const PageStorageKey('piv-retired-slots'),
                tilePadding: const EdgeInsets.only(top: 10, bottom: 0),
                shape: const Border(),
                collapsedShape: const Border(),
                leading: const PivIcon(Icons.history, size: 38, neutral: true),
                title: Text(
                  s.pivRetiredSlots,
                  style: PivStyle.text(context, 15, bold: true),
                ),
                subtitle: Text(
                  s.pivOccupiedSlots(occupied),
                  style: PivStyle.text(context, 13, secondary: true),
                ),
                children: [
                  for (final slot in retiredSlots)
                    _buildInfo(
                      s.pivRetiredSlot(slot - 0x81),
                      slot.toRadixString(16).toUpperCase(),
                      slots[slot],
                    ),
                ],
              ),
            ],
          ),
        ),
        if (credentialSettings != null) ...[
          const SizedBox(height: 20),
          credentialSettings!,
        ],
        const SizedBox(height: 20),
        PivSurface(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final button = PivButton(
                label: s.pivMacSetupTitle,
                width: null,
                icon: Icons.chevron_right,
                onPressed: onSetupMac,
                primary: true,
              );
              final header = PivSectionHeader(
                icon: Icons.desktop_mac_outlined,
                title: s.pivMacLogin,
                description: s.pivMacLoginDescription,
              );
              if (constraints.maxWidth < 550) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [header, const SizedBox(height: 14), button],
                );
              }
              return Row(
                children: [
                  Expanded(child: header),
                  const SizedBox(width: 16),
                  button,
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
