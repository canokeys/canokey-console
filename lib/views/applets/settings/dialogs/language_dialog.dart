import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/localization/language.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LanguageDialog extends StatefulWidget {
  const LanguageDialog({super.key});

  static Future<void> show() {
    return AppDialog.show(const LanguageDialog());
  }

  @override
  State<LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<LanguageDialog> with UIMixin {
  late final newLanguageCode = ThemeCustomizer.instance.currentLanguage.locale
      .toString()
      .obs;

  @override
  Widget build(BuildContext context) {
    return AppDialogSurface(
      child: SizedBox(
        width: AppDialogWidth.compact,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppDialogHeader(
                title: S.of(context).settingsChangeLanguage,
                icon: Icons.language,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Obx(
                  () => Column(
                    children: [
                      for (final lang in Language.languages)
                        AppDialogChoice(
                          title: lang.languageName,
                          selected:
                              newLanguageCode.value == lang.locale.toString(),
                          onTap: () =>
                              newLanguageCode.value = lang.locale.toString(),
                        ),
                    ],
                  ),
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
                    label: S.of(context).confirm,
                    onPressed: () async {
                      Language language = Language.getLanguageFromCode(
                        newLanguageCode.value,
                      );
                      ThemeCustomizer.instance.currentLanguage = language;
                      await LocalStorage.setLanguage(language);
                      Get.updateLocale(language.locale);
                      Navigator.pop(Get.context!);
                    },
                    secondary: false,
                    destructive: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
