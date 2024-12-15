import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/webauthn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebAuthnDeleteDialog extends StatelessWidget {
  final WebAuthnItem item;
  final Function onDelete;

  const WebAuthnDeleteDialog({
    super.key,
    required this.item,
    required this.onDelete,
  });

  static Future<void> show(WebAuthnItem item, Function onDelete) {
    return Get.dialog(WebAuthnDeleteDialog(item: item, onDelete: onDelete));
  }

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
              child: CustomizedText.labelLarge(S.of(context).webauthnDelete('${item.userDisplayName} (${item.userName})')),
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
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: CustomizedText.labelMedium(
                      S.of(context).cancel,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  Spacing.width(16),
                  CustomizedButton.rounded(
                    onPressed: () => onDelete(),
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    child: CustomizedText.labelMedium(
                      S.of(context).delete,
                      color: Theme.of(context).colorScheme.onError,
                    ),
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
