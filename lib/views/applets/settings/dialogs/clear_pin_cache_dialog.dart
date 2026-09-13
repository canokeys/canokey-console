import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClearPinCacheDialog extends StatelessWidget {
  const ClearPinCacheDialog({super.key});

  static Future<void> show() {
    return AppDialog.show(const ClearPinCacheDialog());
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogSurface(
      child: SizedBox(
        width: AppDialogWidth.compact,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppDialogHeader(title: S.of(context).settingsClearPinCache),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.bodyMedium(
                S.of(context).settingsClearPinCachePrompt,
              ),
            ),
            Divider(height: 0, thickness: 1),
            AppDialogActions(
              children: [
                AppDialogAction(
                  label: S.of(context).cancel,
                  onPressed: () => Navigator.pop(Get.context!),
                  secondary: true,
                  destructive: false,
                ),
                AppDialogAction(
                  label: S.of(context).confirm,
                  onPressed: () async {
                    await LocalStorage.clearPinCache();
                    Navigator.pop(Get.context!);
                  },
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
