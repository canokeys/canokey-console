import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/customized_container.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:canokey_console/views/applets/openpgp/widgets/openpgp_section_card.dart';
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
    return OpenPgpSectionCard(
      icon: LucideIcons.shieldCheck,
      title: S.of(context).openpgpUIF,
      child: Column(
        children: [
          for (final type in OpenPgpKeyType.values) ...[
            _policyRow(context, info.keySlots[type]!),
            Spacing.height(12),
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
      enabled: !slot.touchFixed &&
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
      child: Padding(
        padding: Spacing.y(4),
        child: Row(
          children: [
            CustomizedContainer(
              paddingAll: 4,
              height: 32,
              width: 32,
              child: Icon(icon, size: 20),
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
                      title,
                      fontSize: 15,
                      fontWeight: 600,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  CustomizedText.bodySmall(
                    value,
                    color: color.withValues(alpha: 0.72),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (enabled) Icon(Icons.arrow_forward_ios, size: 16),
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
