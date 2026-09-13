import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/models/piv_self_sign_options.dart';
import 'package:flutter/material.dart';
import 'piv_surface.dart';

class PivCertificateExtensions extends StatelessWidget {
  const PivCertificateExtensions({
    super.key,
    required this.options,
    required this.onChanged,
  });
  final PivSelfSignOptions options;
  final void Function(VoidCallback) onChanged;

  Widget _field(BuildContext context, String title, Widget child) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final label = Text(title, style: PivStyle.text(context, 12));
        if (constraints.maxWidth < 470) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [label, const SizedBox(height: 8), child],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: label,
              ),
            ),
            Expanded(child: child),
          ],
        );
      },
    ),
  );

  Widget _chip(
    BuildContext context,
    String label,
    bool selected,
    ValueChanged<bool> onSelected,
  ) => FilterChip(
    label: Text(
      label,
      style: PivStyle.text(
        context,
        11,
      ).copyWith(color: selected ? PivStyle.primary : null),
    ),
    selected: selected,
    onSelected: onSelected,
    showCheckmark: false,
    visualDensity: VisualDensity.compact,
    backgroundColor: PivStyle.soft(context),
    selectedColor: PivStyle.primary.withValues(alpha: .10),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    side: BorderSide(color: selected ? PivStyle.primary : Colors.transparent),
    shape: const StadiumBorder(),
  );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PivSectionHeader(
          icon: Icons.verified_user_outlined,
          title: s.pivCertificateExtensions,
          description: s.pivExtensionsDescription,
        ),
        const SizedBox(height: 8),
        _field(
          context,
          s.pivBasicConstraints,
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            visualDensity: VisualDensity.compact,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              s.pivEndEntityConstraint,
              style: PivStyle.text(context, 12),
            ),
            value: options.includeBasicConstraints,
            activeColor: PivStyle.primary,
            onChanged: (value) =>
                onChanged(() => options.includeBasicConstraints = value!),
          ),
        ),
        _field(
          context,
          s.pivKeyUsage,
          LayoutBuilder(
            builder: (context, constraints) {
              final chips = Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final entry in <int, String>{
                    1: s.pivUsageDigitalSignature,
                    2: s.pivUsageContentCommitment,
                    4: s.pivUsageKeyEncipherment,
                    8: s.pivUsageDataEncipherment,
                    16: s.pivUsageKeyAgreement,
                  }.entries)
                    _chip(
                      context,
                      entry.value,
                      options.keyUsage & entry.key != 0,
                      (selected) => onChanged(() {
                        options.keyUsage = selected
                            ? options.keyUsage | entry.key
                            : options.keyUsage & ~entry.key;
                      }),
                    ),
                ],
              );
              final critical = CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: VisualDensity.compact,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  s.pivKeyUsageCritical,
                  style: PivStyle.text(context, 11),
                ),
                value: options.keyUsageCritical,
                activeColor: PivStyle.primary,
                onChanged: (value) =>
                    onChanged(() => options.keyUsageCritical = value!),
              );
              if (constraints.maxWidth >= 450) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: chips),
                    const SizedBox(width: 8),
                    SizedBox(width: 160, child: critical),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [chips, const SizedBox(height: 4), critical],
              );
            },
          ),
        ),
        _field(
          context,
          s.pivExtendedKeyUsage,
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final entry in <String, String>{
                PivSelfSignOptions.clientAuth: s.pivUsageClientAuth,
                '1.3.6.1.5.5.7.3.1': s.pivUsageServerAuth,
                '1.3.6.1.5.5.7.3.3': s.pivUsageCodeSigning,
                '1.3.6.1.5.5.7.3.4': s.pivUsageEmailProtection,
                '1.3.6.1.4.1.311.20.2.2': s.pivUsageSmartCardLogon,
              }.entries)
                _chip(
                  context,
                  entry.value,
                  options.extendedKeyUsage.contains(entry.key),
                  (selected) => onChanged(() {
                    if (selected) {
                      options.extendedKeyUsage.add(entry.key);
                    } else {
                      options.extendedKeyUsage.remove(entry.key);
                    }
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.pivUsageOmitted,
          style: PivStyle.text(context, 11, secondary: true),
        ),
        const SizedBox(height: 18),
        Divider(height: 1, color: PivStyle.border(context)),
      ],
    );
  }
}
