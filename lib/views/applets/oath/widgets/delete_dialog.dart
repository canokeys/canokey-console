import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';

class DeleteDialog extends StatelessWidget with UIMixin {
  final String name;
  final VoidCallback onDelete;

  DeleteDialog({
    super.key,
    required this.name,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
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
              child: CustomizedText.labelLarge(S.of(context).oathDelete(name)),
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
                    onPressed: onDelete,
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.danger,
                    child: CustomizedText.labelMedium(S.of(context).delete, color: contentTheme.onDanger),
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
