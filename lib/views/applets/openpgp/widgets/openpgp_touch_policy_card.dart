import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:canokey_console/helper/widgets/applet_section_card.dart';
import 'package:flutter/material.dart';

class OpenPgpTouchPolicyCard extends StatelessWidget {
  final OpenPgpCardInfo info;
  final void Function(OpenPgpKeySlotInfo slot) onChange;
  final VoidCallback onChangeCacheTime;

  const OpenPgpTouchPolicyCard({
    super.key,
    required this.info,
    required this.onChange,
    required this.onChangeCacheTime,
  });

  @override
  Widget build(BuildContext context) {
    return AppletSectionCard(
      clipBehavior: Clip.none,
      titleColor: Theme.of(context).colorScheme.onSurface,
      icon: LucideIcons.shieldCheck,
      title: S.of(context).openpgpUIF,
      child: Column(
        children: [
          for (final type in OpenPgpKeyType.values) ...[
            _policyRow(context, info.keySlots[type]!),
            Divider(height: 1, color: AppletStyle.border(context)),
          ],
          _row(
            context,
            icon: LucideIcons.timer,
            title: S.of(context).openpgpUifCacheTime,
            value: _cacheTimeLabel(context),
            onTap: onChangeCacheTime,
            enabled: info.touchCacheTime != null,
          ),
        ],
      ),
    );
  }

  Widget _policyRow(BuildContext context, OpenPgpKeySlotInfo slot) {
    return _row(
      context,
      icon: LucideIcons.keyRound,
      title: slot.type.label,
      value: _touchPolicyLabel(context, slot.touchPolicy),
      onTap: () => onChange(slot),
      enabled:
          !slot.touchFixed &&
          OpenPgpTouchPolicy.writableValues.contains(slot.touchPolicy),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    final color = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 18),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final label = CustomizedText.bodyMedium(
                    title,
                    fontSize: 14,
                    color: color,
                  );
                  final detail = CustomizedText.bodyMedium(
                    value,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  );
                  if (constraints.maxWidth < 380 ||
                      MediaQuery.textScalerOf(context).scale(14) > 20) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [label, const SizedBox(height: 5), detail],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: label),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: detail,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (enabled) ...[
              const SizedBox(width: 14),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  String _cacheTimeLabel(BuildContext context) {
    final seconds = info.touchCacheTime;
    if (seconds == null) {
      return S.of(context).notSupported;
    }
    if (seconds == 0) {
      return S.of(context).openpgpTouchCacheOff;
    }
    return S.of(context).openpgpTouchCacheSeconds(seconds);
  }

  String _touchPolicyLabel(BuildContext context, OpenPgpTouchPolicy policy) {
    switch (policy) {
      case OpenPgpTouchPolicy.off:
        return S.of(context).openpgpTouchNone;
      case OpenPgpTouchPolicy.on:
        return S.of(context).openpgpTouchRequired;
      case OpenPgpTouchPolicy.permanent:
        return S.of(context).openpgpTouchPermanent;
      case OpenPgpTouchPolicy.cached:
        return S.of(context).openpgpTouchCached;
      case OpenPgpTouchPolicy.cachedPermanent:
        return S.of(context).openpgpTouchPermanentCached;
    }
  }
}
