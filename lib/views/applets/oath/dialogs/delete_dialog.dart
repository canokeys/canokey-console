import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';

class DeleteDialog extends BaseDialog with UIMixin {
  final String name;
  final VoidCallback onDelete;

  const DeleteDialog({super.key, required this.name, required this.onDelete});

  static Future<void> show({
    required String name,
    required VoidCallback onDelete,
  }) {
    return AppDialog.show(DeleteDialog(name: name, onDelete: onDelete));
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
        AppDialogHeader(title: S.of(context).delete),
        Divider(height: 0, thickness: 1),
        Padding(
          padding: const EdgeInsets.all(24),
          child: CustomizedText.bodyMedium(
            S.of(context).oathDelete(widget.name),
          ),
        ),
        if (errorMessage.value.isNotEmpty)
          Padding(
            padding: Spacing.all(16),
            child: CustomizedText.bodyMedium(
              errorMessage.value,
              color: errorLevel.value == 'E'
                  ? ContentThemeColor.danger.color
                  : ContentThemeColor.warning.color,
            ),
          ),
        Divider(height: 0, thickness: 1),
        AppDialogActions(
          children: [
            AppDialogAction(
              label: S.of(context).cancel,
              onPressed: () => Navigator.pop(context),
              secondary: true,
              destructive: false,
            ),
            AppDialogAction(
              label: S.of(context).delete,
              onPressed: widget.onDelete,
              secondary: false,
              destructive: true,
            ),
          ],
        ),
      ],
    );
  }
}
