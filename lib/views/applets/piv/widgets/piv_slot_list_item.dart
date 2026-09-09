import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:flutter/material.dart';

class PivSlotListItem extends StatelessWidget {
  final String title;
  final String slotNumber;
  final SlotInfo? slot;
  final bool hasCertificate;
  final VoidCallback onTap;

  const PivSlotListItem({
    super.key,
    required this.title,
    required this.slotNumber,
    required this.slot,
    required this.hasCertificate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final occupied = slot != null || hasCertificate;
    final status = slot != null
        ? (hasCertificate ? s.pivSlotKeyAndCertificate : s.pivSlotKeyOnly)
        : (hasCertificate ? s.pivSlotCertificateOnly : s.pivEmpty);
    final statusWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasCertificate
              ? Icons.description_outlined
              : slot != null
              ? Icons.key_outlined
              : Icons.radio_button_unchecked,
          size: 15,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            status,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 440;
            return Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: occupied
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    slotNumber,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: occupied
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (slot != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          slot!.algorithm.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (narrow) ...[const SizedBox(height: 6), statusWidget],
                    ],
                  ),
                ),
                if (!narrow) ...[
                  const SizedBox(width: 16),
                  SizedBox(width: 155, child: statusWidget),
                ],
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PivSlotPolicies extends StatelessWidget {
  const PivSlotPolicies({super.key, required this.slot});
  final SlotInfo slot;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 20,
    runSpacing: 8,
    children: [
      Text(slot.algorithm.label),
      Text(_pinPolicyLabel(context, slot.pinPolicy)),
      Text(_touchPolicyLabel(context, slot.touchPolicy)),
    ],
  );

  String _pinPolicyLabel(BuildContext context, PinPolicy policy) {
    final value = switch (policy) {
      PinPolicy.defaultPolicy => S.of(context).pivPinPolicyDefault,
      PinPolicy.never => S.of(context).pivPinPolicyNever,
      PinPolicy.once => S.of(context).pivPinPolicyOnce,
      PinPolicy.always => S.of(context).pivPinPolicyAlways,
    };
    return S.of(context).pivPinPolicyChip(value);
  }

  String _touchPolicyLabel(BuildContext context, TouchPolicy policy) {
    final value = switch (policy) {
      TouchPolicy.defaultPolicy => S.of(context).pivTouchPolicyDefault,
      TouchPolicy.never => S.of(context).pivTouchPolicyNever,
      TouchPolicy.always => S.of(context).pivTouchPolicyAlways,
      TouchPolicy.cached => S.of(context).pivTouchPolicyCached,
    };
    return S.of(context).pivTouchPolicyChip(value);
  }
}
