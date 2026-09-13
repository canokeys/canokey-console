import 'package:canokey_console/generated/l10n.dart';
import 'package:flutter/material.dart';

/// Management authentication is separate from PIN requirements of the operation.
class PivManagementKeyAuthentication extends StatelessWidget {
  const PivManagementKeyAuthentication({
    super.key,
    required this.pinProtected,
    required this.usePinOnly,
    required this.onChanged,
    required this.pinField,
    required this.managementKeyField,
    this.requiresPin = false,
  });

  final bool pinProtected;
  final bool usePinOnly;
  final ValueChanged<bool> onChanged;
  final Widget pinField;
  final Widget managementKeyField;
  final bool requiresPin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context).pivManagementKeyAuthentication),
        if (pinProtected)
          RadioGroup<bool>(
            groupValue: usePinOnly,
            onChanged: (value) => onChanged(value ?? usePinOnly),
            child: Column(
              children: [
                for (final value in [true, false]) ...[
                  RadioListTile<bool>(
                    value: value,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      value
                          ? S.of(context).pivPinProtectedKeyOnCard
                          : S.of(context).pivManualManagementKey,
                    ),
                    subtitle: Text(
                      value
                          ? S
                                .of(context)
                                .pivPinProtectedManagementKeyDescription
                          : S.of(context).pivManualManagementKeyDescription,
                    ),
                  ),
                  if (usePinOnly == value)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 12),
                      child: value ? pinField : managementKeyField,
                    ),
                ],
              ],
            ),
          )
        else ...[
          const SizedBox(height: 12),
          managementKeyField,
        ],
        if (requiresPin && !usePinOnly) ...[
          const Divider(height: 24),
          Text(S.of(context).pivOperationRequiresPin),
          const SizedBox(height: 12),
          pinField,
        ],
      ],
    );
  }
}
