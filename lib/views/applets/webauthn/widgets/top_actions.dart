import 'package:canokey_console/controller/applets/webauthn.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TopActions extends StatelessWidget with UIMixin {
  final WebAuthnController controller;

  const TopActions({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: controller,
      builder: (_) {
        List<Widget> widgets = [
          InkWell(
            onTap: controller.refreshData,
            child: Icon(LucideIcons.refreshCw, size: 20, color: topBarTheme.onBackground),
          )
        ];
        if (controller.polled) {
          widgets.insertAll(0, [
            InkWell(
              onTap: () {
                Prompts.showInputPinDialog(
                  title: S.of(context).changePin,
                  label: 'PIN',
                  prompt: S.of(context).changePinPrompt(4, 63),
                  validators: [LengthValidator(min: 4, max: 63)],
                ).then((value) => controller.changePin(value)).onError((error, stackTrace) => null); // Canceled
              },
              child: Icon(LucideIcons.lock, size: 20, color: topBarTheme.onBackground),
            ),
            Spacing.width(12),
          ]);
        }
        return Row(children: widgets);
      },
    );
  }
}
