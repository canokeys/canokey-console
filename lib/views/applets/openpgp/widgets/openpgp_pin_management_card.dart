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
  final bool supportsPinRetryConfig;

  const OpenPgpPinManagementCard({
    super.key,
    required this.pinState,
    required this.onChangeUserPin,
    required this.onChangeAdminPin,
    required this.onUnblockPin,
    required this.onSetResetCode,
    required this.onSetPinRetries,
    required this.onSetSignaturePinPolicy,
    required this.supportsPinRetryConfig,
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
            title: S.of(context).openpgpUserPin,
            value: _retryValue(context, pinState.userRetries),
          ),
          Spacing.height(16),
          InfoItem(
            iconData: LucideIcons.shieldCheck,
            title: S.of(context).openpgpAdminPin,
            value: _retryValue(context, pinState.adminRetries),
          ),
          Spacing.height(16),
          InfoItem(
            iconData: LucideIcons.keyRound,
            title: S.of(context).openpgpResetCode,
            value: _retryValue(context, pinState.resetRetries),
          ),
          Spacing.height(16),
          InfoItem(
            iconData: LucideIcons.fileLock,
            title: S.of(context).openpgpSignaturePin,
            value: pinState.signaturePinForced
                ? S.of(context).openpgpVerifyEverySignature
                : S.of(context).openpgpVerifyOnceAfterInsertion,
          ),
          Spacing.height(16),
          _actions(context),
        ],
      ),
    );
  }

  String _retryValue(BuildContext context, int? remaining) {
    if (remaining == null) {
      return S.of(context).openpgpRetriesUnknown;
    }
    return S.of(context).openpgpRetries(remaining);
  }

  Widget _actions(BuildContext context) {
    final actions = [
      _Action(S.of(context).changePin, onChangeUserPin),
      _Action(S.of(context).openpgpChangeAdminPin, onChangeAdminPin),
      _Action(S.of(context).openpgpUnblockUserPin, onUnblockPin,
          enabled: pinState.userRetries == 0),
      _Action(S.of(context).openpgpSetResetCode, onSetResetCode),
      if (supportsPinRetryConfig)
        _Action(S.of(context).openpgpSetPinRetries, onSetPinRetries),
      _Action(S.of(context).openpgpSignaturePinPolicy, onSetSignaturePinPolicy),
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
