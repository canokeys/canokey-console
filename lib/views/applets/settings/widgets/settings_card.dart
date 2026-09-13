import 'package:canokey_console/helper/widgets/applet_section_card.dart';
import 'package:canokey_console/views/applets/settings/widgets/settings_surface.dart';
import 'package:canokey_console/controller/applets/settings/settings_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/views/applets/settings/dialogs/applet_switches_dialog.dart';
import 'package:canokey_console/views/applets/settings/dialogs/keymap_dialog.dart';
import 'package:canokey_console/views/applets/settings/dialogs/switch_dialog.dart';
import 'package:canokey_console/views/applets/settings/widgets/info_item.dart';
import 'package:flutter/material.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';

class SettingsCard extends StatelessWidget {
  final SettingsController controller;

  const SettingsCard({super.key, required this.controller});

  void _showChangeSwitchDialog(String title, Func func, bool currentState) {
    SwitchDialog.show(
      title: title,
      initialValue: currentState,
      onConfirm: (value) => controller.changeSwitch(func, value),
    );
  }

  void _showKeymapDialog(BuildContext context) {
    KeymapDialog.show(
      currentState: controller.key.keyboardKeymap,
      onConfirm: controller.changeKeyboardKeymap,
    );
  }

  void _showAppletSwitchesDialog(Set<Func> functionSet) {
    AppletSwitchesDialog.show(
      canokey: controller.key,
      functionSet: functionSet,
      onConfirm: controller.changeSwitches,
    );
  }

  bool _hasAppletSwitches(Set<Func> functionSet) {
    return (functionSet.contains(Func.nfcSwitch) &&
            functionSet.contains(Func.ndefEnabled)) ||
        (controller.key.featureSwitchesSupported &&
            (functionSet.contains(Func.passSwitch) ||
                functionSet.contains(Func.webAuthnSwitch) ||
                functionSet.contains(Func.pivCcIdSwitch) ||
                functionSet.contains(Func.pivNfcSwitch) ||
                functionSet.contains(Func.openPgpCcIdSwitch) ||
                functionSet.contains(Func.openPgpNfcSwitch)));
  }

  @override
  Widget build(BuildContext context) {
    final functionSet = controller.key.getFunctionSet();

    return AppletSectionCard(
      icon: LucideIcons.settings,
      title: S.of(context).settingsDeviceSettings,
      child: SettingsRows(
        children: [
          if (functionSet.contains(Func.led)) ...{
            InfoItem(
              iconData: LucideIcons.lightbulb,
              title: 'LED',
              value: controller.key.ledOn
                  ? S.of(context).on
                  : S.of(context).off,
              onTap: () => _showChangeSwitchDialog(
                'LED',
                Func.led,
                controller.key.ledOn,
              ),
            ),
          },
          if (functionSet.contains(Func.hotp)) ...{
            InfoItem(
              iconData: LucideIcons.keyboard,
              title: S.of(context).settingsHotp,
              value: controller.key.hotpOn
                  ? S.of(context).on
                  : S.of(context).off,
              onTap: () => _showChangeSwitchDialog(
                S.of(context).settingsHotp,
                Func.hotp,
                controller.key.hotpOn,
              ),
            ),
          },
          if (functionSet.contains(Func.keyboardWithReturn)) ...{
            InfoItem(
              iconData: LucideIcons.cornerDownLeft,
              title: S.of(context).settingsKeyboardWithReturn,
              value: controller.key.keyboardWithReturn
                  ? S.of(context).on
                  : S.of(context).off,
              onTap: () => _showChangeSwitchDialog(
                S.of(context).settingsKeyboardWithReturn,
                Func.keyboardWithReturn,
                controller.key.keyboardWithReturn,
              ),
            ),
          },
          if (functionSet.contains(Func.keyboardKeymap)) ...{
            InfoItem(
              iconData: LucideIcons.keyboard,
              title: S.of(context).settingsKeyboardLayout,
              value:
                  controller.key.keyboardKeymap?.displayName(
                    S.of(context).settingsKeyboardLayoutDefault,
                    S.of(context).settingsKeyboardLayoutCustom,
                  ) ??
                  S.of(context).settingsKeyboardLayoutUnknown,
              onTap: () => _showKeymapDialog(context),
            ),
          },
          if (functionSet.contains(Func.webusbLandingPage)) ...{
            InfoItem(
              iconData: LucideIcons.globe,
              title: S.of(context).settingsWebUSB,
              value: controller.key.webusbLandingEnabled
                  ? S.of(context).on
                  : S.of(context).off,
              onTap: () => _showChangeSwitchDialog(
                S.of(context).settingsWebUSB,
                Func.webusbLandingPage,
                controller.key.webusbLandingEnabled,
              ),
            ),
          },
          if (_hasAppletSwitches(functionSet)) ...{
            InfoItem(
              iconData: LucideIcons.settings2,
              title: S.of(context).settingsAppletSwitches,
              value: '',
              onTap: () => _showAppletSwitchesDialog(functionSet),
            ),
          },
          if (functionSet.contains(Func.ndefReadonly)) ...{
            InfoItem(
              iconData: LucideIcons.shieldAlert,
              title: S.of(context).settingsNDEFReadonly,
              value: controller.key.ndefReadonly
                  ? S.of(context).on
                  : S.of(context).off,
              onTap: () => _showChangeSwitchDialog(
                S.of(context).settingsNDEFReadonly,
                Func.ndefReadonly,
                controller.key.ndefReadonly,
              ),
            ),
          },
          if (functionSet.contains(Func.nfcSwitch)) ...{
            InfoItem(
              iconData: LucideIcons.nfc,
              title: 'NFC',
              value: controller.key.nfcEnabled
                  ? S.of(context).on
                  : S.of(context).off,
              onTap: () => _showChangeSwitchDialog(
                'NFC',
                Func.nfcSwitch,
                controller.key.nfcEnabled,
              ),
            ),
          },
        ],
      ),
    );
  }
}
