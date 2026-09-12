import 'dart:math' as math;
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/customized_container.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:canokey_console/views/applets/openpgp/widgets/openpgp_section_card.dart';
import 'package:flutter/material.dart';

class OpenPgpKeySlotsCard extends StatelessWidget {
  final OpenPgpCardInfo info;

  const OpenPgpKeySlotsCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return OpenPgpSectionCard(
      icon: LucideIcons.keyRound,
      title: S.of(context).openpgpKeys,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 14.0;
          final minWidth =
              260 *
              (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 1.6);
          final columns = math.min(
            3,
            math.max(
              1,
              ((constraints.maxWidth + gap) / (minWidth + gap)).floor(),
            ),
          );
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final type in OpenPgpKeyType.values)
                SizedBox(
                  width: width,
                  child: _slot(context, info.keySlots[type]!),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _slot(BuildContext context, OpenPgpKeySlotInfo slot) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: OpenPgpStyle.soft(context),
      border: Border.all(color: OpenPgpStyle.border(context)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.fileLock,
              size: 22,
              color: OpenPgpStyle.accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomizedText.bodyLarge(
                slot.type.label,
                fontSize: 16,
                fontWeight: 600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(
              context,
              slot.hasKey
                  ? S.of(context).openpgpKeyImported
                  : S.of(context).openpgpKeyEmpty,
              muted: !slot.hasKey,
            ),
            _chip(
              context,
              _touchPolicyLabel(context, slot.touchPolicy),
              muted: true,
            ),
            if (slot.fingerprint != null)
              Tooltip(
                message: slot.fingerprint!,
                child: _chip(
                  context,
                  _shortFingerprint(slot.fingerprint!),
                  muted: true,
                ),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _chip(BuildContext context, String text, {bool muted = false}) {
    final theme = Theme.of(context);
    final background = muted
        ? theme.colorScheme.surfaceContainerHighest
        : OpenPgpStyle.accent.withValues(alpha: .10);
    final foreground = muted
        ? theme.colorScheme.onSurface
        : OpenPgpStyle.accent;
    final border = muted
        ? OpenPgpStyle.border(context)
        : OpenPgpStyle.accent.withValues(alpha: .2);

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

  String _shortFingerprint(String fingerprint) {
    if (fingerprint.length <= 16) {
      return fingerprint;
    }
    return '${fingerprint.substring(0, 8)}...${fingerprint.substring(fingerprint.length - 8)}';
  }

  String _touchPolicyLabel(BuildContext context, OpenPgpTouchPolicy policy) {
    switch (policy) {
      case OpenPgpTouchPolicy.off:
        return S.of(context).openpgpTouchOffLabel;
      case OpenPgpTouchPolicy.on:
        return S.of(context).openpgpTouchOnLabel;
      case OpenPgpTouchPolicy.permanent:
        return S.of(context).openpgpTouchPermanentLabel;
      case OpenPgpTouchPolicy.cached:
        return S.of(context).openpgpTouchCachedLabel;
      case OpenPgpTouchPolicy.cachedPermanent:
        return S.of(context).openpgpTouchPermanentCachedLabel;
    }
  }
}
