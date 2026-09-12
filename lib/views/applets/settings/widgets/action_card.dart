import 'package:canokey_console/views/applets/settings/widgets/settings_surface.dart';
import 'package:canokey_console/controller/applets/settings/settings_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/input_pin_dialog.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/views/applets/settings/dialogs/reset_dialog.dart';
import 'package:flutter/material.dart';
import 'package:platform_detector/platform_detector.dart';

bool shouldBlockFactoryReset({
  required bool mobile,
  required ConnectionType connectionType,
}) {
  return mobile && connectionType != ConnectionType.ccid;
}

class ActionCard extends StatelessWidget with UIMixin {
  final SettingsController controller;

  const ActionCard({super.key, required this.controller});

  Widget _action(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool primary = false,
    bool danger = false,
  }) {
    final foreground = primary
        ? Colors.white
        : danger
        ? contentTheme.danger
        : Theme.of(context).colorScheme.onSurface;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: primary
            ? SettingsStyle.accent
            : danger
            ? contentTheme.danger.withValues(alpha: .05)
            : SettingsStyle.soft(context),
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: BorderSide(
            color: primary
                ? SettingsStyle.accent
                : danger
                ? contentTheme.danger.withValues(alpha: .25)
                : SettingsStyle.border(context),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 18),
          Expanded(
            child: CustomizedText.bodyMedium(
              label,
              color: foreground,
              fontSize: 14,
            ),
          ),
          if (!danger) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final functions = controller.polled
        ? controller.key.getFunctionSet()
        : <Func>{};
    final resets = [
      (Func.resetOath, Applet.oath, s.settingsResetOATH, LucideIcons.clock),
      (Func.resetPiv, Applet.piv, s.settingsResetPIV, LucideIcons.creditCard),
      (
        Func.resetOpenPgp,
        Applet.openpgp,
        s.settingsResetOpenPGP,
        LucideIcons.lock,
      ),
      (Func.resetNdef, Applet.ndef, s.settingsResetNDEF, LucideIcons.nfc),
      (
        Func.resetWebAuthn,
        Applet.webauthn,
        s.settingsResetWebAuthn,
        LucideIcons.keyRound,
      ),
      (Func.resetPass, Applet.pass, s.settingsResetPass, LucideIcons.keyboard),
    ];
    final actions = <Widget>[
      if (functions.contains(Func.changeAdminPin))
        _action(
          context,
          label: s.changePin,
          icon: LucideIcons.pencil,
          primary: true,
          onPressed: () => InputPinDialog.show(
            title: s.changePin,
            label: 'PIN',
            prompt: s.changePinPrompt(6, 64),
            validators: [LengthValidator(min: 6, max: 64)],
            showSaveOption: true,
            onSubmit: (pin, savePin) async {
              await controller.changePin(pin, savePin);
            },
          ),
        ),
      for (final (function, applet, label, icon) in resets)
        if (functions.contains(function))
          _action(
            context,
            label: label,
            icon: icon,
            onPressed: () => ResetDialog.show(
              applet: applet,
              resetCanokey: controller.resetCanokey,
              resetApplet: controller.resetApplet,
            ),
          ),
      if (!controller.polled || functions.contains(Func.factoryReset))
        _action(
          context,
          label: s.settingsResetAll,
          icon: LucideIcons.trash2,
          danger: true,
          onPressed: () {
            if (shouldBlockFactoryReset(
              mobile: isMobile(),
              connectionType: SmartCard.connectionType,
            )) {
              Prompts.showPrompt(s.notSupportedInNFC, ContentThemeColor.info);
            } else {
              ResetDialog.show(
                resetCanokey: controller.resetCanokey,
                resetApplet: controller.resetApplet,
              );
            }
          },
        ),
    ];
    return SettingsSection(
      icon: LucideIcons.refreshCw,
      title: s.settingsDeviceActions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            actions[i],
          ],
        ],
      ),
    );
  }
}
