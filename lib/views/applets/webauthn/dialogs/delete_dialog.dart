import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/webauthn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebAuthnDeleteDialog extends BaseDialog with UIMixin {
  final WebAuthnItem item;
  final Function onDelete;

  const WebAuthnDeleteDialog({
    super.key,
    required this.item,
    required this.onDelete,
  });

  static Future<void> show(WebAuthnItem item, Function onDelete) {
    return Get.dialog(WebAuthnDeleteDialog(item: item, onDelete: onDelete), barrierDismissible: false);
  }

  @override
  State<WebAuthnDeleteDialog> createState() => _WebAuthnDeleteDialogState();
}

class _WebAuthnDeleteDialogState extends BaseDialogState<WebAuthnDeleteDialog> with UIMixin {
  @override
  Widget buildDialogContent() {
    return SingleChildScrollView(
      child: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.of(context).delete),
            ),
            const Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.of(context).webauthnDelete('${widget.item.userDisplayName} (${widget.item.userName})')),
            ),
            if (errorMessage.value.isNotEmpty)
              Padding(
                padding: Spacing.all(16),
                child: CustomizedText.bodyMedium(errorMessage.value,
                    color: errorLevel.value == 'E' ? ContentThemeColor.danger.color : ContentThemeColor.warning.color),
              ),
            const Divider(height: 0, thickness: 1),
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
                    child: CustomizedText.labelMedium(
                      S.of(context).cancel,
                      color: contentTheme.onSecondary,
                    ),
                  ),
                  Spacing.width(16),
                  CustomizedButton.rounded(
                    onPressed: () => widget.onDelete(),
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
