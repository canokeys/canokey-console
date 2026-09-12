import 'package:canokey_console/helper/widgets/responsive_grid.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'piv_surface.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:flutter/material.dart';

class PivPinManagementCard extends StatelessWidget {
  final SlotInfo? pinInfo;
  final int? pinRetriesRemaining;
  final SlotInfo? pukInfo;
  final AlgorithmType managementKeyAlgorithm;
  final TouchPolicy managementKeyTouchPolicy;
  final bool pinOnlyMode;
  final bool supportsPinOnlyMode;
  final bool supportsPinRetryConfig;
  final bool canUnblockPin;
  final double flexSpacing;
  final ContentTheme contentTheme;
  final VoidCallback onChangePin;
  final VoidCallback onChangePuk;
  final VoidCallback onUnblockPin;
  final VoidCallback onChangeManagementKey;
  final VoidCallback onSetPinRetries;
  final VoidCallback onTogglePinOnlyMode;
  final String Function(SlotInfo? info) credentialRetryValue;

  const PivPinManagementCard({
    super.key,
    required this.pinInfo,
    this.pinRetriesRemaining,
    required this.pukInfo,
    required this.managementKeyAlgorithm,
    required this.managementKeyTouchPolicy,
    required this.pinOnlyMode,
    required this.supportsPinOnlyMode,
    required this.supportsPinRetryConfig,
    required this.canUnblockPin,
    required this.flexSpacing,
    required this.contentTheme,
    required this.onChangePin,
    required this.onChangePuk,
    required this.onUnblockPin,
    required this.onChangeManagementKey,
    required this.onSetPinRetries,
    required this.onTogglePinOnlyMode,
    required this.credentialRetryValue,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveGrid(
          maxColumns: 4,
          minWidth: 250,
          minChildHeight: MediaQuery.textScalerOf(context).scale(160),
          children: [
            _credential(
              context,
              'PIN',
              LucideIcons.lock,
              s.pivPinDescription,
              info: pinInfo,
              remaining: pinRetriesRemaining,
              credential: true,
            ),
            _credential(
              context,
              'PUK',
              LucideIcons.keyRound,
              s.pivPukDescription,
              info: pukInfo,
              credential: true,
            ),
            _credential(
              context,
              s.pivManagementKey,
              LucideIcons.shieldCheck,
              '${managementKeyAlgorithm.label} · ${_touchPolicyLabel(context)}',
            ),
            if (supportsPinOnlyMode)
              _credential(
                context,
                s.pivManagementKeyAuthentication,
                LucideIcons.shieldCheck,
                pinOnlyMode
                    ? s.pivPinProtectedKeyOnCard
                    : s.pivManualManagementKey,
                onTap: onTogglePinOnlyMode,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ResponsiveGrid(
              minWidth: 165,
              maxColumns: 5,
              children: [
                _actionButton(
                  context,
                  s.changePin,
                  onChangePin,
                  primary: true,
                  icon: LucideIcons.lock,
                ),
                _actionButton(
                  context,
                  s.pivChangePUK,
                  onChangePuk,
                  enabled: !pinOnlyMode && pukInfo?.remainingCount != 0,
                  icon: LucideIcons.keyRound,
                ),
                _actionButton(
                  context,
                  s.pivUnblockPin,
                  onUnblockPin,
                  enabled: canUnblockPin && pukInfo?.remainingCount != 0,
                  icon: Icons.lock_open_outlined,
                ),
                _actionButton(
                  context,
                  s.pivChangeManagementKey,
                  onChangeManagementKey,
                  icon: LucideIcons.shieldCheck,
                ),
                if (supportsPinRetryConfig)
                  _actionButton(
                    context,
                    s.pivSetPinPukRetries,
                    onSetPinRetries,
                    enabled: !pinOnlyMode,
                    icon: Icons.settings_outlined,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _credential(
    BuildContext context,
    String title,
    IconData icon,
    String description, {
    SlotInfo? info,
    int? remaining,
    bool credential = false,
    VoidCallback? onTap,
  }) {
    final s = S.of(context);
    final remainingCount = info?.remainingCount ?? remaining;
    final blocked = credential && remainingCount == 0;
    final unknown = credential && remainingCount == null;
    final content = PivSurface(
      padding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 100),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PivIcon(icon, size: 44),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: PivStyle.text(context, 15, bold: true),
                        ),
                      ),
                      const SizedBox(width: 6),
                      PivStatus(
                        unknown
                            ? s.pivStatusUnknown
                            : blocked
                            ? s.pivStatusBlocked
                            : s.pivStatusReady,
                        active: !unknown,
                        danger: blocked,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: PivStyle.text(context, 12, secondary: true),
                  ),
                  if (credential) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${remainingCount ?? '—'} / ${info?.retriesCount ?? '—'}',
                      style: PivStyle.text(context, 22, bold: true).copyWith(
                        color: blocked ? const Color(0xffe63652) : null,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.pivRetriesRemaining,
                      style: PivStyle.text(context, 12, secondary: true),
                    ),
                  ],
                  if (onTap != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.change,
                          style: PivStyle.text(
                            context,
                            12,
                          ).copyWith(color: PivStyle.primary),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: PivStyle.primary,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return onTap == null
        ? content
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: content,
          );
  }

  String _touchPolicyLabel(BuildContext context) {
    final value = switch (managementKeyTouchPolicy) {
      TouchPolicy.defaultPolicy => S.of(context).pivTouchPolicyDefault,
      TouchPolicy.never => S.of(context).pivTouchPolicyNever,
      TouchPolicy.always => S.of(context).pivTouchPolicyAlways,
      TouchPolicy.cached => S.of(context).pivTouchPolicyCached,
    };
    return '${S.of(context).pivTouchPolicy}: $value';
  }

  Widget _actionButton(
    BuildContext context,
    String text,
    VoidCallback onTap, {
    bool enabled = true,
    bool primary = false,
    required IconData icon,
  }) {
    return CustomizedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: Size(96, PivStyle.buttonHeight(context)),
        fixedSize: Size.fromHeight(PivStyle.buttonHeight(context)),
        visualDensity: VisualDensity.standard,
        backgroundColor: primary ? PivStyle.primary : PivStyle.soft(context),
        disabledBackgroundColor: PivStyle.soft(context),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: primary ? Colors.transparent : PivStyle.border(context),
          ),
        ),
      ),
      elevation: 0,
      padding: Spacing.xy(18, 13),
      side: BorderSide(
        color: primary ? Colors.transparent : PivStyle.border(context),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: primary ? contentTheme.primary : PivStyle.soft(context),
      borderRadiusAll: 6,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 17,
            color: primary
                ? contentTheme.onPrimary
                : enabled
                ? PivStyle.ink(context)
                : PivStyle.muted(context).withValues(alpha: .5),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: CustomizedText.bodySmall(
              text,
              color: primary
                  ? contentTheme.onPrimary
                  : enabled
                  ? PivStyle.ink(context)
                  : PivStyle.muted(context).withValues(alpha: .5),
            ),
          ),
        ],
      ),
    );
  }
}
