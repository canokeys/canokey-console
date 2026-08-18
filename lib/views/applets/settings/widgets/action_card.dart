import 'package:canokey_console/controller/applets/settings/settings_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_style.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/shadow.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_card.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/input_pin_dialog.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/views/applets/settings/dialogs/reset_dialog.dart';
import 'package:flutter/material.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:platform_detector/platform_detector.dart';

class ActionCard extends StatelessWidget with UIMixin {
  final SettingsController controller;

  const ActionCard({super.key, required this.controller});

  Widget _buildResetButton(Applet applet, String resetText) {
    return CustomizedButton(
      onPressed: () => ResetDialog.show(
          applet: applet,
          resetCanokey: controller.resetCanokey,
          resetApplet: controller.resetApplet),
      elevation: 0,
      padding: Spacing.xy(20, 16),
      backgroundColor: contentTheme.danger,
      borderRadiusAll: AppStyle.buttonRadius.medium,
      child: CustomizedText.bodySmall(resetText, color: contentTheme.onDanger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final functionSet =
        controller.polled ? controller.key.getFunctionSet() : <Func>{};

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
                Icon(LucideIcons.arrowRightCircle,
                    color: contentTheme.primary, size: 16),
                Spacing.width(12),
                CustomizedText.titleMedium(S.of(context).actions,
                    fontWeight: 600, color: contentTheme.primary)
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
                  if (functionSet.contains(Func.changeAdminPin)) ...{
                    CustomizedButton(
                      onPressed: () {
                        InputPinDialog.show(
                          title: S.of(context).changePin,
                          label: 'PIN',
                          prompt: S.of(context).changePinPrompt(6, 64),
                          validators: [LengthValidator(min: 6, max: 64)],
                          showSaveOption: true,
                          onSubmit: (pin, savePin) async {
                            await controller.changePin(pin, savePin);
                          },
                        );
                      },
                      elevation: 0,
                      padding: Spacing.xy(20, 16),
                      backgroundColor: contentTheme.primary,
                      borderRadiusAll: AppStyle.buttonRadius.medium,
                      child: CustomizedText.bodySmall(S.of(context).changePin,
                          color: contentTheme.onPrimary),
                    ),
                  },
                  // Reset buttons
                  if (functionSet.contains(Func.resetOath)) ...{
                    _buildResetButton(
                        Applet.oath, S.of(context).settingsResetOATH),
                  },
                  if (functionSet.contains(Func.resetPiv)) ...{
                    _buildResetButton(
                        Applet.piv, S.of(context).settingsResetPIV),
                  },
                  if (functionSet.contains(Func.resetOpenPgp)) ...{
                    _buildResetButton(
                        Applet.openpgp, S.of(context).settingsResetOpenPGP),
                  },
                  if (functionSet.contains(Func.resetNdef)) ...{
                    _buildResetButton(
                        Applet.ndef, S.of(context).settingsResetNDEF),
                  },
                  if (functionSet.contains(Func.resetWebAuthn)) ...{
                    _buildResetButton(
                        Applet.webauthn, S.of(context).settingsResetWebAuthn),
                  },
                  if (functionSet.contains(Func.resetPass)) ...{
                    _buildResetButton(
                        Applet.pass, S.of(context).settingsResetPass),
                  },
                ],
                // Reset all
                if (!controller.polled ||
                    functionSet.contains(Func.factoryReset)) ...{
                  CustomizedButton(
                    onPressed: () {
                      if (isMobile()) {
                        Prompts.showPrompt(S.of(context).notSupportedInNFC,
                            ContentThemeColor.info);
                      } else {
                        ResetDialog.show(
                            resetCanokey: controller.resetCanokey,
                            resetApplet: controller.resetApplet);
                      }
                    },
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.danger,
                    borderRadiusAll: AppStyle.buttonRadius.medium,
                    child: CustomizedText.bodySmall(
                        S.of(context).settingsResetAll,
                        color: contentTheme.onDanger),
                  ),
                },
              ],
            ),
          ),
        ],
      ),
    );
  }
}
