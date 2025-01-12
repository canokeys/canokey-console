import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SwitchDialog extends BaseDialog with UIMixin {
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
    return Get.dialog(
      SwitchDialog(
        title: title,
        initialValue: initialValue,
        onConfirm: onConfirm,
      ),
      barrierDismissible: false,
    );
  }

  @override
  State<SwitchDialog> createState() => _SwitchDialogState();
}

class _SwitchDialogState extends BaseDialogState<SwitchDialog> with UIMixin {
  late final RxBool newState;

  @override
  void initState() {
    super.initState();
    newState = widget.initialValue.obs;
  }

  @override
  Widget buildDialogContent() {
    return Obx(
      () => Column(
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
                Checkbox(
                  onChanged: (value) => newState.value = value!,
                  value: newState.value,
                  activeColor: contentTheme.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: getCompactDensity,
                ),
                Spacing.width(16),
                CustomizedText.bodyMedium(widget.title),
              ],
            ),
          ),
          if (errorMessage.value.isNotEmpty)
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.bodyMedium(errorMessage.value,
                  color: errorLevel.value == 'E' ? ContentThemeColor.danger.color : ContentThemeColor.warning.color),
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
                  onPressed: () => widget.onConfirm(newState.value),
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
    );
  }
}
