import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_style.dart';
import 'package:canokey_console/helper/utils/shadow.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_card.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:canokey_console/views/applets/settings/widgets/info_item.dart';
import 'package:flutter/material.dart';

class PivPinManagementCard extends StatelessWidget {
  final SlotInfo? pinInfo;
  final SlotInfo? pukInfo;
  final bool pinOnlyMode;
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
  final String Function({required String en, required String zh}) t;

  const PivPinManagementCard({
    super.key,
    required this.pinInfo,
    required this.pukInfo,
    required this.pinOnlyMode,
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
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return CustomizedCard(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shadow: Shadow(elevation: 0.5, position: ShadowPosition.bottom),
      paddingAll: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: contentTheme.primary.withValues(alpha: 0.2),
            padding: Spacing.xy(16, 12),
            child: Row(
              children: [
                Icon(LucideIcons.keyboard,
                    color: contentTheme.primary, size: 16),
                Spacing.width(12),
                CustomizedText.titleMedium(
                  S.of(context).pivPinManagement,
                  fontWeight: 600,
                  color: contentTheme.primary,
                )
              ],
            ),
          ),
          Padding(
            padding: Spacing.xy(flexSpacing, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoItem(
                  iconData: LucideIcons.lock,
                  title: 'PIN',
                  value: credentialRetryValue(pinInfo),
                ),
                Spacing.height(16),
                InfoItem(
                  iconData: LucideIcons.keyRound,
                  title: 'PUK',
                  value: credentialRetryValue(pukInfo),
                ),
                Spacing.height(16),
                InfoItem(
                  iconData: LucideIcons.shieldCheck,
                  title: 'PIN-only mode',
                  value: pinOnlyMode ? S.of(context).on : S.of(context).off,
                  onTap: onTogglePinOnlyMode,
                ),
                Spacing.height(16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _actionButton(
                        context, S.of(context).changePin, onChangePin),
                    _actionButton(
                        context, S.of(context).pivChangePUK, onChangePuk),
                    _actionButton(context, t(en: 'Unblock PIN', zh: '解锁 PIN'),
                        onUnblockPin,
                        enabled: canUnblockPin),
                    _actionButton(context, S.of(context).pivChangeManagementKey,
                        onChangeManagementKey),
                    _actionButton(
                        context,
                        t(en: 'Set PIN/PUK Retries', zh: '设置 PIN/PUK 重试次数'),
                        onSetPinRetries),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    String text,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    return CustomizedButton(
      onPressed: enabled ? onTap : null,
      elevation: 0,
      padding: Spacing.xy(20, 16),
      backgroundColor: contentTheme.primary,
      borderRadiusAll: AppStyle.buttonRadius.medium,
      child: CustomizedText.bodySmall(text, color: contentTheme.onPrimary),
    );
  }
}
