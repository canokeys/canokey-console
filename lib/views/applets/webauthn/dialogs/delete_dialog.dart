import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
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

  @override
  bool get managesOwnScrolling => true;

  static Future<void> show(WebAuthnItem item, Function onDelete) {
    return AppDialog.show(WebAuthnDeleteDialog(item: item, onDelete: onDelete));
  }

  @override
  State<WebAuthnDeleteDialog> createState() => _WebAuthnDeleteDialogState();
}

class _WebAuthnDeleteDialogState extends BaseDialogState<WebAuthnDeleteDialog>
    with UIMixin {
  @override
  Widget buildDialogContent() {
    return SingleChildScrollView(
      child: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppDialogHeader(title: S.of(context).delete),
            const Divider(height: 0, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: CustomizedText.bodyMedium(
                S
                    .of(context)
                    .webauthnDelete(
                      '${widget.item.userDisplayName} (${widget.item.userName})',
                    ),
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
            const Divider(height: 0, thickness: 1),
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
                  onPressed: () => widget.onDelete(),
                  secondary: false,
                  destructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
