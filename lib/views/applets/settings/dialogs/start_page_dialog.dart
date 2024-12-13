import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StartPageDialog extends StatelessWidget with UIMixin {
  const StartPageDialog({super.key});

  static Future<void> show() {
    return Get.dialog(const StartPageDialog());
  }

  static String pageName(BuildContext context, String path) {
    switch (path) {
      case '/':
        return S.of(context).home;
      case '/applets/oath':
        return 'HOTP/TOTP';
      case '/applets/piv':
        return 'PIV';
      case '/applets/openpgp':
        return 'OpenPGP';
      case '/applets/ndef':
        return 'NDEF';
      case '/applets/webauthn':
        return 'WebAuthn';
      case '/applets/pass':
        return 'Pass';
      default:
        return 'Unknown';
    }
  }

  Widget _buildStartPageItem(BuildContext context, RxString startPage, String path) {
    return RadioListTile(
      dense: true,
      contentPadding: Spacing.x(16),
      title: CustomizedText.bodyMedium(pageName(context, path)),
      value: path,
      groupValue: startPage.value,
      activeColor: contentTheme.primary,
      onChanged: (value) => startPage.value = value!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final startPage = (LocalStorage.getStartPage() ?? '/').obs;

    return Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.of(context).settingsStartPage),
            ),
            Divider(height: 0, thickness: 1),
            Obx(() => Column(
                  children: [
                    _buildStartPageItem(context, startPage, '/'),
                    _buildStartPageItem(context, startPage, '/applets/oath'),
                    _buildStartPageItem(context, startPage, '/applets/webauthn'),
                    _buildStartPageItem(context, startPage, '/applets/pass'),
                  ],
                )),
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
                      LocalStorage.setStartPage(startPage.value);
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
