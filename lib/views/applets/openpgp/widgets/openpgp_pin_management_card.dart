import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_style.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:canokey_console/views/applets/openpgp/widgets/openpgp_section_card.dart';
import 'package:canokey_console/views/applets/settings/widgets/info_item.dart';
import 'package:flutter/material.dart';

class OpenPgpPinManagementCard extends StatelessWidget {
  final OpenPgpPinState pinState;
  final VoidCallback onChangeUserPin;
  final VoidCallback onChangeAdminPin;
  final VoidCallback onUnblockPin;
  final VoidCallback onSetResetCode;
  final VoidCallback onSetPinRetries;
  final VoidCallback onSetSignaturePinPolicy;
  final String Function({required String en, required String zh}) t;

  const OpenPgpPinManagementCard({
    super.key,
    required this.pinState,
    required this.onChangeUserPin,
    required this.onChangeAdminPin,
    required this.onUnblockPin,
    required this.onSetResetCode,
    required this.onSetPinRetries,
    required this.onSetSignaturePinPolicy,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return OpenPgpSectionCard(
      icon: LucideIcons.lock,
      title: S.of(context).pivPinManagement,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoItem(
            iconData: LucideIcons.user,
            title: 'User PIN',
            value: _retryValue(pinState.userRetries),
          ),
          Spacing.height(16),
          InfoItem(
            iconData: LucideIcons.shieldCheck,
            title: 'Admin PIN',
            value: _retryValue(pinState.adminRetries),
          ),
          Spacing.height(16),
          InfoItem(
            iconData: LucideIcons.keyRound,
            title: t(en: 'Reset Code', zh: 'Reset Code'),
            value: _retryValue(pinState.resetRetries),
          ),
          Spacing.height(16),
          InfoItem(
            iconData: LucideIcons.fileLock,
            title: t(en: 'Signature PIN', zh: '签名 PIN'),
            value: pinState.signaturePinForced
                ? t(en: 'Verify every signature', zh: '每次签名都验证')
                : t(en: 'Verify once after insertion', zh: '插入后验证一次'),
          ),
          Spacing.height(16),
          _actions(context),
        ],
      ),
    );
  }

  String _retryValue(int? remaining) {
    if (remaining == null) {
      return '-';
    }
    return t(en: 'Retries left: $remaining', zh: '剩余尝试次数：$remaining');
  }

  Widget _actions(BuildContext context) {
    final actions = [
      _Action(S.of(context).changePin, onChangeUserPin),
      _Action(S.of(context).openpgpChangeAdminPin, onChangeAdminPin),
      _Action(t(en: 'Unblock User PIN', zh: '解锁 User PIN'), onUnblockPin,
          enabled: pinState.userRetries == 0),
      _Action(t(en: 'Set Reset Code', zh: '设置 Reset Code'), onSetResetCode),
      _Action(t(en: 'Set PIN Retries', zh: '设置 PIN 重试次数'), onSetPinRetries),
      _Action(t(en: 'Signature PIN Policy', zh: '签名 PIN 策略'),
          onSetSignaturePinPolicy),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final action in actions)
          _button(
            context,
            action.text,
            action.onTap,
            enabled: action.enabled,
          ),
      ],
    );
  }

  Widget _button(BuildContext context, String text, VoidCallback onTap,
      {bool enabled = true}) {
    final contentTheme = AdminTheme.theme.contentTheme;
    return CustomizedButton(
      onPressed: enabled ? onTap : null,
      elevation: 0,
      padding: Spacing.xy(20, 16),
      backgroundColor: contentTheme.primary,
      borderRadiusAll: AppStyle.buttonRadius.medium,
      child: CustomizedText.bodySmall(
        text,
        color: contentTheme.onPrimary,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _Action {
  final String text;
  final VoidCallback onTap;
  final bool enabled;

  const _Action(this.text, this.onTap, {this.enabled = true});
}
