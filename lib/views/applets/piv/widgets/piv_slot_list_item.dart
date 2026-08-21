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
    final certificateLabel = hasCertificate
        ? S.of(context).pivCertificate
        : S.of(context).pivNoCertificate;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: Spacing.y(4),
        child: Row(
          children: [
            CustomizedContainer(
              paddingAll: 4,
              height: 32,
              width: 32,
              child: Icon(LucideIcons.fileLock, size: 20),
            ),
            Spacing.width(12),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CustomizedText.bodyMedium(
                    '$title - $slotNumber',
                    fontSize: 15,
                    fontWeight: 600,
                    softWrap: true,
                  ),
                  if (slot == null) ...[
                    _chip(context, S.of(context).pivEmpty, muted: true),
                    if (hasCertificate) _chip(context, certificateLabel),
                  ] else ...[
                    _chip(context, slot!.algorithm.label),
                    _chip(context, certificateLabel, muted: !hasCertificate),
                    _chip(context, _pinPolicyLabel(context, slot!.pinPolicy),
                        muted: true),
                    _chip(
                        context, _touchPolicyLabel(context, slot!.touchPolicy),
                        muted: true),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String text, {bool muted = false}) {
    final theme = Theme.of(context);
    final background = muted
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.primaryContainer;
    final foreground = muted
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onPrimaryContainer;
    final border = muted
        ? theme.dividerColor
        : theme.colorScheme.primary.withValues(alpha: 0.45);

    return CustomizedContainer.bordered(
      padding: Spacing.xy(8, 4),
      borderRadiusAll: 6,
      color: background,
      borderColor: border,
      child: CustomizedText.bodySmall(
        text,
        color: foreground,
        fontSize: 12,
        fontWeight: 600,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

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
