import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/models/piv_self_sign_options.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:flutter/material.dart';

class PivCertificateExtensions extends StatelessWidget {
  const PivCertificateExtensions({
    super.key,
    required this.options,
    required this.onChanged,
  });

  final PivSelfSignOptions options;
  final void Function(VoidCallback) onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pinLabel = switch (options.pinPolicy) {
      PinPolicy.defaultPolicy => s.pivPinPolicyDefault,
      PinPolicy.never => s.pivPinPolicyNever,
      PinPolicy.once => s.pivPinPolicyOnce,
      PinPolicy.always => s.pivPinPolicyAlways,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (options.supportsMacOsLogin) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => onChanged(options.applyMacOsLogin),
              icon: const Icon(Icons.tune, size: 18),
              label: Text(s.pivMacOsApply),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            options.slotNumber == '9A'
                ? s.pivMacOsDescription
                : s.pivMacOsKeychainDescription,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            options.matchesMacOsLogin
                ? s.pivMacOsSlotApplied(options.slotNumber)
                : s.pivCertificateCustom,
          ),
        ] else
          Text(
            s.pivMacOsOtherSlot,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: 8),
        // Show changes to the previous step where the preset is applied.
        Text(
          '${s.pivAlgorithm}: ${options.algorithm.label} · '
          '${s.pivPinPolicy}: $pinLabel',
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 16),
          title: Text(s.pivCertificateExtensions),
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.pivEndEntityConstraint),
              value: options.includeBasicConstraints,
              onChanged: (value) =>
                  onChanged(() => options.includeBasicConstraints = value!),
            ),
            Align(alignment: Alignment.centerLeft, child: Text(s.pivKeyUsage)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in const <int, String>{
                    1: 'digitalSignature',
                    2: 'contentCommitment',
                    4: 'keyEncipherment',
                    8: 'dataEncipherment',
                    16: 'keyAgreement',
                  }.entries)
                    FilterChip(
                      label: Text(entry.value),
                      selected: options.keyUsage & entry.key != 0,
                      onSelected: (selected) => onChanged(() {
                        options.keyUsage = selected
                            ? options.keyUsage | entry.key
                            : options.keyUsage & ~entry.key;
                      }),
                    ),
                ],
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.pivKeyUsageCritical),
              value: options.keyUsageCritical,
              onChanged: options.keyUsage == 0
                  ? null
                  : (value) =>
                        onChanged(() => options.keyUsageCritical = value!),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(s.pivExtendedKeyUsage),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in const <String, String>{
                    PivSelfSignOptions.clientAuth: 'clientAuth',
                    '1.3.6.1.5.5.7.3.1': 'serverAuth',
                    '1.3.6.1.5.5.7.3.3': 'codeSigning',
                    '1.3.6.1.5.5.7.3.4': 'emailProtection',
                    '1.3.6.1.4.1.311.20.2.2': 'smartCardLogon',
                  }.entries)
                    FilterChip(
                      label: Text(entry.value),
                      selected: options.extendedKeyUsage.contains(entry.key),
                      onSelected: (selected) => onChanged(() {
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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                s.pivUsageOmitted,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
