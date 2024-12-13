import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/localization/language.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LanguageDialog extends StatelessWidget with UIMixin {
  const LanguageDialog({super.key});

  static Future<void> show() {
    return Get.dialog(const LanguageDialog());
  }

  @override
  Widget build(BuildContext context) {
    final newLanguageCode = ThemeCustomizer.instance.currentLanguage.locale.toString().obs;
    return Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.of(context).settingsChangeLanguage),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
                padding: Spacing.all(16),
                child: Obx(
                  () => Column(
                    children: Language.languages
                        .map((lang) => CustomizedButton.text(
                            padding: Spacing.xy(8, 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            splashColor: contentTheme.onBackground.withAlpha(20),
                            onPressed: () => newLanguageCode.value = lang.locale.toString(),
                            child: Row(
                              children: [
                                if (newLanguageCode.value == lang.locale.toString())
                                  Icon(Icons.check, color: contentTheme.primary, size: 16)
                                else
                                  Spacing.width(16),
                                Spacing.width(20),
                                Text(lang.languageName),
                              ],
                            )))
                        .toList(),
                  ),
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
                    onPressed: () async {
                      Language language = Language.getLanguageFromCode(newLanguageCode.value);
                      ThemeCustomizer.instance.currentLanguage = language;
                      await LocalStorage.setLanguage(language);
                      Get.updateLocale(language.locale);
                      Navigator.pop(Get.context!);
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
