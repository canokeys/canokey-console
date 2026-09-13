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
    final pinBlocked = (pinInfo?.remainingCount ?? pinRetriesRemaining) == 0;
    final pukBlocked = pukInfo?.remainingCount == 0;
    return ResponsiveGrid(
      maxColumns: 4,
      minWidth: 250,
      equalRowHeight: true,
      children: [
        _credential(
          context,
          'PIN',
          LucideIcons.lock,
          s.pivPinDescription,
          info: pinInfo,
          remaining: pinRetriesRemaining,
          credential: true,
          actions: [
            if (!pinBlocked)
              _actionButton(
                context,
                s.changePin,
                onChangePin,
                primary: true,
                icon: LucideIcons.lock,
              ),
            if (canUnblockPin && !pukBlocked)
              _actionButton(
                context,
                s.pivUnblockPin,
                onUnblockPin,
                primary: true,
                icon: Icons.lock_open_outlined,
              ),
            if (supportsPinRetryConfig && !pinOnlyMode && !pinBlocked)
              _actionButton(
                context,
                s.pivSetPinPukRetries,
                onSetPinRetries,
                icon: Icons.settings_outlined,
              ),
          ],
        ),
        _credential(
          context,
          'PUK',
          LucideIcons.keyRound,
          s.pivPukDescription,
          info: pukInfo,
          credential: true,
          actions: [
            if (!pinOnlyMode && !pukBlocked)
              _actionButton(
                context,
                s.pivChangePUK,
                onChangePuk,
                primary: true,
                icon: LucideIcons.keyRound,
              ),
          ],
        ),
        _credential(
          context,
          s.pivManagementKey,
          LucideIcons.shieldCheck,
          '${managementKeyAlgorithm.label} · ${_touchPolicyLabel(context)}',
          actions: [
            _actionButton(
              context,
              s.pivChangeManagementKey,
              onChangeManagementKey,
              primary: true,
              icon: LucideIcons.shieldCheck,
            ),
          ],
        ),
        if (supportsPinOnlyMode)
          _credential(
            context,
            s.pivManagementKeyAuthentication,
            LucideIcons.shieldCheck,
            pinOnlyMode ? s.pivPinProtectedKeyOnCard : s.pivManualManagementKey,
            actions: [
              _actionButton(
                context,
                s.change,
                onTogglePinOnlyMode,
                primary: true,
                icon: LucideIcons.shieldCheck,
              ),
            ],
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
    List<Widget> actions = const [],
  }) {
    final s = S.of(context);
    final remainingCount = info?.remainingCount ?? remaining;
    final blocked = credential && remainingCount == 0;
    final unknown = credential && remainingCount == null;
    return PivSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
                  ],
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const Spacer(),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
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
    bool primary = false,
    required IconData icon,
  }) {
    return CustomizedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: Size(96, PivStyle.buttonHeight(context)),
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
            color: primary ? contentTheme.onPrimary : PivStyle.ink(context),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: CustomizedText.bodySmall(
              text,
              color: primary ? contentTheme.onPrimary : PivStyle.ink(context),
            ),
          ),
        ],
      ),
    );
  }
}
