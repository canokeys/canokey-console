import 'package:canokey_console/controller/applets/settings.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResetDialog extends StatelessWidget with UIMixin {
  final Applet? applet;
  final SettingsController controller;

  const ResetDialog({
    super.key,
    this.applet,
    required this.controller,
  });

  static Future<void> show({
    Applet? applet,
    required SettingsController controller,
  }) {
    return Get.dialog(ResetDialog(applet: applet, controller: controller));
  }

  @override
  Widget build(BuildContext context) {
    final title = applet == null ? S.of(context).settingsResetAll : S.of(context).reset;
    final prompt = applet == null ? S.of(context).settingsResetAllPrompt : S.of(context).settingsResetApplet(applet!.name);

    return Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(title),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(prompt),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomizedButton.rounded(
                    onPressed: () => Navigator.pop(context),
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.secondary,
                    child: CustomizedText.labelMedium(S.of(context).cancel, color: contentTheme.onSecondary),
                  ),
                  Spacing.width(16),
                  CustomizedButton.rounded(
                    onPressed: () => applet == null ? controller.resetCanokey() : controller.resetApplet(applet!),
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium(S.of(context).confirm, color: contentTheme.onPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
