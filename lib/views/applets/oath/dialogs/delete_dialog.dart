import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeleteDialog extends BaseDialog with UIMixin {
  final String name;
  final VoidCallback onDelete;

  const DeleteDialog({super.key, required this.name, required this.onDelete});

  static Future<void> show({required String name, required VoidCallback onDelete}) {
    return Get.dialog(
      DeleteDialog(name: name, onDelete: onDelete),
      barrierDismissible: false,
    );
  }

  @override
  State<DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends BaseDialogState<DeleteDialog> with UIMixin {
  @override
  Widget buildDialogContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: Spacing.all(16),
          child: CustomizedText.labelLarge(S.of(context).delete),
        ),
        Divider(height: 0, thickness: 1),
        Padding(
          padding: Spacing.all(16),
          child: CustomizedText.labelLarge(S.of(context).oathDelete(widget.name)),
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
                onPressed: widget.onDelete,
                elevation: 0,
                padding: Spacing.xy(20, 16),
                backgroundColor: contentTheme.danger,
                child: CustomizedText.labelMedium(S.of(context).delete, color: contentTheme.onDanger),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
