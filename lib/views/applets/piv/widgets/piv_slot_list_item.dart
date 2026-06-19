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
  final VoidCallback onTap;

  const PivSlotListItem({
    super.key,
    required this.title,
    required this.slotNumber,
    required this.slot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCertificate = slot?.certBytes != null;
    final certificateLabel = hasCertificate
        ? S.of(context).pivCertificate
        : S.of(context).pivNoCertificate;
    final locale = Localizations.localeOf(context).languageCode;

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
                  SizedBox(
                    width: 190,
                    child: CustomizedText.bodyMedium(
                      '$title - $slotNumber',
                      fontSize: 15,
                      fontWeight: 600,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (slot == null)
                    _chip(context, S.of(context).pivEmpty, muted: true)
                  else ...[
                    _chip(context, slot!.algorithm.name.toUpperCase()),
                    _chip(context, certificateLabel, muted: !hasCertificate),
                    _chip(context, _pinPolicyLabel(slot!.pinPolicy, locale),
                        muted: true),
                    _chip(context, _touchPolicyLabel(slot!.touchPolicy, locale),
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

  String _pinPolicyLabel(PinPolicy policy, String locale) {
    final prefix = 'PIN';
    final value = switch (policy) {
      PinPolicy.defaultPolicy => locale == 'zh' ? '默认' : 'Default',
      PinPolicy.never => locale == 'zh' ? '免验' : 'Never',
      PinPolicy.once => locale == 'zh' ? '一次' : 'Once',
      PinPolicy.always => locale == 'zh' ? '每次' : 'Always',
    };
    return '$prefix: $value';
  }

  String _touchPolicyLabel(TouchPolicy policy, String locale) {
    final prefix = locale == 'zh' ? '触摸' : 'Touch';
    final value = switch (policy) {
      TouchPolicy.defaultPolicy => locale == 'zh' ? '默认' : 'Default',
      TouchPolicy.never => locale == 'zh' ? '免触摸' : 'Never',
      TouchPolicy.always => locale == 'zh' ? '每次' : 'Always',
      TouchPolicy.cached => locale == 'zh' ? '缓存' : 'Cached',
    };
    return '$prefix: $value';
  }
}
