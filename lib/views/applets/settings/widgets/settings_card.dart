import 'package:canokey_console/controller/applets/settings_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/shadow.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_card.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/views/applets/settings/dialogs/switch_dialog.dart';
import 'package:canokey_console/views/applets/settings/widgets/info_item.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SettingsCard extends StatelessWidget with UIMixin {
  final SettingsController controller;

  const SettingsCard({super.key, required this.controller});

  _showChangeSwitchDialog(String title, Func func, bool currentState) {
    SwitchDialog.show(
      title: title,
      initialValue: currentState,
      onConfirm: (value) => controller.changeSwitch(func, value),
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
                Icon(LucideIcons.settings, color: contentTheme.primary, size: 16),
                Spacing.width(12),
                CustomizedText.titleMedium(S.of(context).settings, fontWeight: 600, color: contentTheme.primary)
              ],
            ),
          ),
          Padding(
            padding: Spacing.xy(flexSpacing, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.key.getFunctionSet().contains(Func.led)) ...{
                  InfoItem(
                    iconData: LucideIcons.lightbulb,
                    title: 'LED',
                    value: controller.key.ledOn ? S.of(context).on : S.of(context).off,
                    onTap: () => _showChangeSwitchDialog('LED', Func.led, controller.key.ledOn),
                  ),
                  Spacing.height(16),
                },
                if (controller.key.getFunctionSet().contains(Func.hotp)) ...{
                  InfoItem(
                    iconData: LucideIcons.keyboard,
                    title: S.of(context).settingsHotp,
                    value: controller.key.hotpOn ? S.of(context).on : S.of(context).off,
                    onTap: () => _showChangeSwitchDialog(S.of(context).settingsHotp, Func.hotp, controller.key.hotpOn),
                  ),
                  Spacing.height(16),
                },
                if (controller.key.getFunctionSet().contains(Func.keyboardWithReturn)) ...{
                  InfoItem(
                    iconData: LucideIcons.cornerDownLeft,
                    title: S.of(context).settingsKeyboardWithReturn,
                    value: controller.key.keyboardWithReturn ? S.of(context).on : S.of(context).off,
                    onTap: () => _showChangeSwitchDialog(S.of(context).settingsKeyboardWithReturn, Func.keyboardWithReturn, controller.key.keyboardWithReturn),
                  ),
                  Spacing.height(16),
                },
                if (controller.key.getFunctionSet().contains(Func.webusbLandingPage)) ...{
                  InfoItem(
                    iconData: LucideIcons.globe,
                    title: S.of(context).settingsWebUSB,
                    value: controller.key.webusbLandingEnabled ? S.of(context).on : S.of(context).off,
                    onTap: () => _showChangeSwitchDialog(S.of(context).settingsWebUSB, Func.webusbLandingPage, controller.key.webusbLandingEnabled),
                  ),
                  Spacing.height(16),
                },
                if (controller.key.getFunctionSet().contains(Func.ndefEnabled)) ...{
                  InfoItem(
                    iconData: LucideIcons.tag,
                    title: S.of(context).settingsNDEF,
                    value: controller.key.ndefEnabled ? S.of(context).on : S.of(context).off,
                    onTap: () => _showChangeSwitchDialog(S.of(context).settingsNDEF, Func.ndefEnabled, controller.key.ndefEnabled),
                  ),
                  Spacing.height(16),
                },
                if (controller.key.getFunctionSet().contains(Func.ndefReadonly)) ...{
                  InfoItem(
                    iconData: LucideIcons.shieldAlert,
                    title: S.of(context).settingsNDEFReadonly,
                    value: controller.key.ndefReadonly ? S.of(context).on : S.of(context).off,
                    onTap: () => _showChangeSwitchDialog(S.of(context).settingsNDEFReadonly, Func.ndefReadonly, controller.key.ndefReadonly),
                  ),
                  Spacing.height(16),
                },
                if (controller.key.getFunctionSet().contains(Func.nfcSwitch)) ...{
                  InfoItem(
                    iconData: LucideIcons.nfc,
                    title: 'NFC',
                    value: controller.key.nfcEnabled ? S.of(context).on : S.of(context).off,
                    onTap: () => _showChangeSwitchDialog('NFC', Func.nfcSwitch, controller.key.nfcEnabled),
                  ),
                  Spacing.height(16),
                },
              ],
            ),
          ),
        ],
      ),
    );
  }
}
