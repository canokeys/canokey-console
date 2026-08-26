import 'package:canokey_console/controller/applets/webauthn/webauthn_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/input_pin_dialog.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/views/applets/webauthn/dialogs/sm2_config_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:platform_detector/platform_detector.dart';

class TopActions extends StatelessWidget with UIMixin {
  final WebAuthnController controller;

  const TopActions({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: controller,
      builder: (_) {
        List<Widget> widgets = [];

        if (isWeb() || isIOSApp()) {
          widgets.add(IconButton(
            onPressed: controller.refreshData,
            icon: Icon(LucideIcons.refreshCw, color: topBarTheme.onBackground),
          ));
        }

        if (controller.polled) {
          widgets.insert(
            0,
            IconButton(
              onPressed: () {
                InputPinDialog.show(
                  title: S.of(context).changePin,
                  label: 'PIN',
                  prompt: S.of(context).changePinPrompt(4, 63),
                  validators: [LengthValidator(min: 4, max: 63)],
                  showSaveOption: true,
                  onSubmit: (pin, savePin) async {
                    await controller.changePin(pin, savePin);
                  },
                );
              },
              icon: Icon(LucideIcons.lock, color: topBarTheme.onBackground),
            ),
          );
          if (controller.supportsSm2Settings) {
            widgets.insert(
              0,
              IconButton(
                tooltip: S.of(context).settingsWebAuthnSm2Support,
                onPressed: () async {
                  final config = await controller.readSm2Config();
                  if (config == null) {
                    return;
                  }
                  await Sm2ConfigDialog.show(
                    config: config,
                    canChangeEnabled: true,
                    onConfirm: controller.changeSm2Config,
                  );
                },
                icon:
                    Icon(LucideIcons.settings, color: topBarTheme.onBackground),
              ),
            );
          }
        }
        return Row(mainAxisSize: MainAxisSize.min, children: widgets);
      },
    );
  }
}
