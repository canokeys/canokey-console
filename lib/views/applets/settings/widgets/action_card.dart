import 'package:canokey_console/controller/applets/settings_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_style.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/shadow.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_card.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/views/applets/settings/dialogs/reset_dialog.dart';
import 'package:canokey_console/views/applets/settings/dialogs/sm2_config_dialog.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:platform_detector/platform_detector.dart';

class ActionCard extends StatelessWidget with UIMixin {
  final SettingsController controller;

  const ActionCard({super.key, required this.controller});

  Widget _buildResetButton(Applet applet, String resetText) {
    return CustomizedButton(
      onPressed: () => ResetDialog.show(applet: applet, resetCanokey: controller.resetCanokey, resetApplet: controller.resetApplet),
      elevation: 0,
      padding: Spacing.xy(20, 16),
      backgroundColor: contentTheme.danger,
      borderRadiusAll: AppStyle.buttonRadius.medium,
      child: CustomizedText.bodySmall(resetText, color: contentTheme.onDanger),
    );
  }

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
            color: contentTheme.primary.withValues(alpha: 0.08),
            padding: Spacing.xy(16, 12),
            child: Row(
              children: [
                Icon(LucideIcons.arrowRightCircle, color: contentTheme.primary, size: 16),
                Spacing.width(12),
                CustomizedText.titleMedium(S.of(context).actions, fontWeight: 600, color: contentTheme.primary)
              ],
            ),
          ),
          Padding(
            padding: Spacing.only(top: 12, left: 16, bottom: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (controller.polled) ...[
                  // Change PIN
                  CustomizedButton(
                    onPressed: () {
                      Prompts.showInputPinDialog(
                        title: S.of(context).changePin,
                        label: 'PIN',
                        prompt: S.of(context).changePinPrompt(6, 64),
                        validators: [LengthValidator(min: 6, max: 64)],
                      ).then((value) => controller.changePin(value)).onError((error, stackTrace) => null); // Canceled
                    },
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.primary,
                    borderRadiusAll: AppStyle.buttonRadius.medium,
                    child: CustomizedText.bodySmall(S.of(context).changePin, color: contentTheme.onPrimary),
                  ),
                  // WebAuthn SM2
                  if (controller.key.webAuthnSm2Config != null) ...{
                    CustomizedButton(
                      onPressed: () => Sm2ConfigDialog.show(
                        config: controller.key.webAuthnSm2Config!,
                        onConfirm: (enabled, curveId, algoId) => controller.changeWebAuthnSm2Config(enabled, curveId, algoId),
                      ),
                      elevation: 0,
                      padding: Spacing.xy(20, 16),
                      backgroundColor: contentTheme.primary,
                      borderRadiusAll: AppStyle.buttonRadius.medium,
                      child: CustomizedText.bodySmall(S.of(context).settingsWebAuthnSm2Support, color: contentTheme.onPrimary),
                    ),
                  },
                  // Reset buttons
                  _buildResetButton(Applet.oath, S.of(context).settingsResetOATH),
                  _buildResetButton(Applet.piv, S.of(context).settingsResetPIV),
                  _buildResetButton(Applet.openpgp, S.of(context).settingsResetOpenPGP),
                  _buildResetButton(Applet.ndef, S.of(context).settingsResetNDEF),
                  if (controller.key.getFunctionSet().contains(Func.resetWebAuthn)) ...{
                    _buildResetButton(Applet.webauthn, S.of(context).settingsResetWebAuthn),
                  },
                  if (controller.key.getFunctionSet().contains(Func.resetPass)) ...{
                    _buildResetButton(Applet.pass, S.of(context).settingsResetPass),
                  },
                ],
                // Reset all
                CustomizedButton(
                  onPressed: () {
                    if (isMobile()) {
                      Prompts.showPrompt(S.of(context).notSupportedInNFC, ContentThemeColor.info);
                    } else {
                      ResetDialog.show(resetCanokey: controller.resetCanokey, resetApplet: controller.resetApplet);
                    }
                  },
                  elevation: 0,
                  padding: Spacing.xy(20, 16),
                  backgroundColor: contentTheme.danger,
                  borderRadiusAll: AppStyle.buttonRadius.medium,
                  child: CustomizedText.bodySmall(S.of(context).settingsResetAll, color: contentTheme.onDanger),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
