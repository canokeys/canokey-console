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
      child: Column(
        children: OpenPgpKeyType.values
            .map((type) => _slot(context, info.keySlots[type]!))
            .expand((widget) => [widget, Spacing.height(12)])
            .toList()
          ..removeLast(),
      ),
    );
  }

  Widget _slot(BuildContext context, OpenPgpKeySlotInfo slot) {
    return Padding(
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
                SizedBox(
                  width: 190,
                  child: CustomizedText.bodyMedium(
                    slot.type.label,
                    fontSize: 15,
                    fontWeight: 600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _chip(
                  context,
                  slot.hasKey
                      ? _t(context, en: 'Imported', zh: '已导入')
                      : _t(context, en: 'Empty', zh: '空'),
                  muted: !slot.hasKey,
                ),
                _chip(context, _touchPolicyLabel(context, slot.touchPolicy),
                    muted: true),
                if (slot.fingerprint != null)
                  _chip(context, _shortFingerprint(slot.fingerprint!),
                      muted: true),
              ],
            ),
          ),
        ],
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

  String _shortFingerprint(String fingerprint) {
    if (fingerprint.length <= 16) {
      return fingerprint;
    }
    return '${fingerprint.substring(0, 8)}...${fingerprint.substring(fingerprint.length - 8)}';
  }

  String _touchPolicyLabel(BuildContext context, OpenPgpTouchPolicy policy) {
    switch (policy) {
      case OpenPgpTouchPolicy.off:
        return _t(context, en: 'Touch: Off', zh: '触摸：关闭');
      case OpenPgpTouchPolicy.on:
        return _t(context, en: 'Touch: On', zh: '触摸：开启');
      case OpenPgpTouchPolicy.permanent:
        return _t(context, en: 'Touch: Permanent', zh: '触摸：永久开启');
      case OpenPgpTouchPolicy.cached:
        return _t(context, en: 'Touch: Cached', zh: '触摸：缓存');
      case OpenPgpTouchPolicy.cachedPermanent:
        return _t(context, en: 'Touch: Permanent cached', zh: '触摸：永久缓存');
    }
  }

  String _t(BuildContext context, {required String en, required String zh}) {
    return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  }
}
