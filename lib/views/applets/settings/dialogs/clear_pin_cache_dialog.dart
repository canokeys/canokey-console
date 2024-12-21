import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClearPinCacheDialog extends StatelessWidget {
  const ClearPinCacheDialog({super.key});

  static Future<void> show() {
    return Get.dialog(
      const ClearPinCacheDialog(),
      barrierDismissible: false,
    );
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
              child: CustomizedText.labelLarge(S.of(context).settingsClearPinCache),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.bodyMedium(S.of(context).settingsClearPinCachePrompt),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Row(
                children: [
                  CustomizedButton.rounded(
                    onPressed: () => Navigator.pop(Get.context!),
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: ContentThemeColor.secondary.color,
                    child: CustomizedText.labelMedium(S.of(context).cancel, color: ContentThemeColor.secondary.onColor),
                  ),
                  Spacing.width(16),
                  CustomizedButton.rounded(
                    onPressed: () async {
                      await LocalStorage.clearPinCache();
                      Navigator.pop(Get.context!);
                    },
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: ContentThemeColor.danger.color,
                    child: CustomizedText.labelMedium(S.of(context).confirm, color: ContentThemeColor.danger.onColor),
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
