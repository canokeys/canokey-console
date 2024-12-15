import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SwitchDialog extends StatelessWidget with UIMixin {
  final String title;
  final bool initialValue;
  final Function(bool) onConfirm;

  const SwitchDialog({
    super.key,
    required this.title,
    required this.initialValue,
    required this.onConfirm,
  });

  static Future<void> show({
    required String title,
    required bool initialValue,
    required Function(bool) onConfirm,
  }) {
    return Get.dialog(SwitchDialog(
      title: title,
      initialValue: initialValue,
      onConfirm: onConfirm,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final newState = initialValue.obs;

    return Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.of(context).settings),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Row(
                children: [
                  Obx(() => Checkbox(
                        onChanged: (value) => newState.value = value!,
                        value: newState.value,
                        activeColor: contentTheme.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: getCompactDensity,
                      )),
                  Spacing.width(16),
                  CustomizedText.bodyMedium(title),
                ],
              ),
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
                    onPressed: () {
                      onConfirm(newState.value);
                      Navigator.pop(context);
                    },
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