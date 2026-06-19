import 'package:canokey_console/controller/applets/webauthn/webauthn_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/input_pin_dialog.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
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
          widgets.insertAll(0, [
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
            Spacing.width(12),
          ]);
        }
        return Row(children: widgets);
      },
    );
  }
}
