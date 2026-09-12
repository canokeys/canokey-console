import 'package:canokey_console/helper/widgets/responsive_grid.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:flutter/material.dart';
import 'piv_surface.dart';

String pivSlotEnglishName(String slot) => switch (slot) {
  '9A' => 'Authentication',
  '9C' => 'Digital Signature',
  '9D' => 'Key Management',
  '9E' => 'Card Authentication',
  _ => 'Retired Key Management',
};

String pivSlotDisplayName(String title) =>
    title.replaceFirst(RegExp(r'\s*[（(][^（）()]*[）)]$'), '');

/// One column definition shared by the table header and slot rows.
class PivSlotColumns extends StatelessWidget {
  const PivSlotColumns({
    super.key,
    required this.number,
    required this.name,
    required this.algorithm,
    required this.status,
    required this.actions,
    required this.trailing,
  });
  final Widget number, name, algorithm, status, actions, trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 76, child: number),
      Expanded(flex: 4, child: name),
      const SizedBox(width: 16),
      Expanded(flex: 3, child: algorithm),
      Expanded(flex: 3, child: status),
      SizedBox(width: 360, child: actions),
      const SizedBox(width: 14),
      SizedBox(width: 20, child: trailing),
    ],
  );
}

class PivSlotListItem extends StatelessWidget {
  final String title, slotNumber;
  final SlotInfo? slot;
  final bool hasCertificate;
  final VoidCallback onTap;
  final VoidCallback? onImport, onExport, onGenerate;
  const PivSlotListItem({
    super.key,
    required this.title,
    required this.slotNumber,
    required this.slot,
    required this.hasCertificate,
    required this.onTap,
    this.onImport,
    this.onExport,
    this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final occupied = slot != null || hasCertificate;
    final status = slot != null
        ? (hasCertificate ? s.pivSlotKeyAndCertificate : s.pivSlotKeyOnly)
        : (hasCertificate ? s.pivSlotCertificateOnly : s.pivEmpty);
    final statusWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        PivStatus(
          occupied ? s.pivStatusConfigured : s.pivStatusEmpty,
          active: occupied,
          pill: false,
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Text(
            status,
            style: PivStyle.text(context, 12, secondary: true),
          ),
        ),
      ],
    );
    final badge = Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 42,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: occupied
              ? (PivStyle.dark(context)
                    ? const Color(0xff185c50)
                    : const Color(0xffa9efde))
              : (PivStyle.dark(context)
                    ? const Color(0xff3a4549)
                    : const Color(0xffdce4e1)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(slotNumber, style: PivStyle.text(context, 15, bold: true)),
      ),
    );
    final name = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          pivSlotDisplayName(title),
          style: PivStyle.text(context, 14, bold: true),
        ),
        if (Localizations.localeOf(context).languageCode != 'en') ...[
          const SizedBox(height: 2),
          Text(
            pivSlotEnglishName(slotNumber),
            style: PivStyle.text(context, 12, secondary: true),
          ),
        ],
      ],
    );
    final chevron = Icon(
      Icons.chevron_right,
      size: 20,
      color: PivStyle.muted(context),
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 920) {
              return PivSlotColumns(
                number: badge,
                name: name,
                algorithm: Text(
                  slot?.algorithm.label ?? '—',
                  style: PivStyle.text(context, 12),
                ),
                status: statusWidget,
                actions: Row(
                  children: [
                    Expanded(
                      child: PivButton(
                        label: hasCertificate
                            ? s.pivViewCertificate
                            : s.pivImport,
                        icon: hasCertificate
                            ? Icons.description_outlined
                            : Icons.file_upload_outlined,
                        onPressed: hasCertificate ? onTap : onImport ?? onTap,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: hasCertificate
                          ? PopupMenuButton<String>(
                              tooltip: s.pivTransfer,
                              onSelected: (value) => value == 'import'
                                  ? (onImport ?? onTap)()
                                  : (onExport ?? onTap)(),
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'import',
                                  child: Text(s.pivImport),
                                ),
                                PopupMenuItem(
                                  value: 'export',
                                  child: Text(s.pivExportCertificate),
                                ),
                              ],
                              child: IgnorePointer(
                                child: PivButton(
                                  label: s.pivTransfer,
                                  icon: Icons.sync_alt,
                                  onPressed: () {},
                                  compact: true,
                                ),
                              ),
                            )
                          : PivButton(
                              label: s.pivCreateCertificate,
                              icon: Icons.add,
                              onPressed: onGenerate,
                              compact: true,
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PivButton(
                        label: s.pivManage,
                        icon: Icons.more_horiz,
                        onPressed: onTap,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                trailing: chevron,
              );
            }
            return Row(
              children: [
                SizedBox(width: 56, child: badge),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      name,
                      if (slot != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          slot!.algorithm.label,
                          style: PivStyle.text(context, 12, secondary: true),
                        ),
                      ],
                      if (constraints.maxWidth < 540) ...[
                        const SizedBox(height: 6),
                        Text(
                          status,
                          style: PivStyle.text(context, 12, secondary: true),
                        ),
                      ],
                    ],
                  ),
                ),
                if (constraints.maxWidth >= 540)
                  SizedBox(width: 165, child: statusWidget),
                const SizedBox(width: 8),
                chevron,
              ],
            );
          },
        ),
      ),
    );
  }
}

class PivSlotPolicies extends StatelessWidget {
  const PivSlotPolicies({
    super.key,
    required this.slot,
    this.hasCertificate = false,
  });
  final bool hasCertificate;
  final SlotInfo slot;

  @override
  Widget build(BuildContext context) => ResponsiveGrid(
    maxColumns: 4,
    minWidth: 190,
    children: [
      _policy(
        context,
        Icons.key_outlined,
        S.of(context).pivAlgorithm,
        slot.algorithm.label,
      ),
      _policy(
        context,
        Icons.shield_outlined,
        S.of(context).pivPinPolicy,
        _pinPolicyLabel(context, slot.pinPolicy),
      ),
      _policy(
        context,
        Icons.touch_app_outlined,
        S.of(context).pivTouchPolicy,
        _touchPolicyLabel(context, slot.touchPolicy),
      ),
      _policy(
        context,
        Icons.description_outlined,
        S.of(context).pivCertificateStatus,
        hasCertificate
            ? S.of(context).pivCertificatePresent
            : S.of(context).pivNoCertificate,
      ),
    ],
  );

  Widget _policy(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) => PivSurface(
    child: Row(
      children: [
        PivIcon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: PivStyle.text(context, 12, secondary: true)),
              const SizedBox(height: 6),
              Text(value, style: PivStyle.text(context, 14, bold: true)),
            ],
          ),
        ),
      ],
    ),
  );

  String _pinPolicyLabel(BuildContext context, PinPolicy policy) {
    final value = switch (policy) {
      PinPolicy.defaultPolicy => S.of(context).pivPinPolicyDefault,
      PinPolicy.never => S.of(context).pivPinPolicyNever,
      PinPolicy.once => S.of(context).pivPinPolicyOnce,
      PinPolicy.always => S.of(context).pivPinPolicyAlways,
    };
    return value;
  }

  String _touchPolicyLabel(BuildContext context, TouchPolicy policy) {
    final value = switch (policy) {
      TouchPolicy.defaultPolicy => S.of(context).pivTouchPolicyDefault,
      TouchPolicy.never => S.of(context).pivTouchPolicyNever,
      TouchPolicy.always => S.of(context).pivTouchPolicyAlways,
      TouchPolicy.cached => S.of(context).pivTouchPolicyCached,
    };
    return value;
  }
}
