import 'package:canokey_console/controller/applets/piv.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_style.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/shadow.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_card.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/field_validator.dart';
import 'package:canokey_console/helper/widgets/form_validator.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:lucide_icons/lucide_icons.dart';

final log = Logger('Console:PIV:View');

class PivPage extends StatefulWidget {
  const PivPage({Key? key}) : super(key: key);

  @override
  State<PivPage> createState() => _PivPageState();
}

class _PivPageState extends State<PivPage> with SingleTickerProviderStateMixin, UIMixin {
  late PivController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(PivController());
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      title: 'PIV',
      topActions: InkWell(
        onTap: () {
          if (controller.polled) {
          } else {
            Prompts.showInputPinDialog(
              title: S.of(context).settingsInputPin,
              label: "PIN",
              prompt: S.of(context).passInputPinPrompt,
            ).then((value) {
              controller.refreshData(value);
            }).onError((error, stackTrace) => null); // User canceled
          }
        },
        child: Icon(LucideIcons.refreshCw, size: 20, color: topBarTheme.onBackground),
      ),
      child: GetBuilder(
        init: controller,
        builder: (_) {
          if (!controller.polled) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Spacing.height(MediaQuery.of(context).size.height / 2 - 120),
                Center(
                    child: Padding(
                  padding: Spacing.horizontal(36),
                  child: CustomizedText.bodyMedium(S.of(context).pollCanoKey, fontSize: 24),
                )),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.x(flexSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Spacing.height(20),
                    CustomizedCard(
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      shadow: Shadow(elevation: 0.5, position: ShadowPosition.bottom),
                      paddingAll: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            color: contentTheme.primary.withOpacity(0.08),
                            padding: Spacing.xy(16, 12),
                            child: Row(
                              children: [
                                Icon(LucideIcons.keyboard, color: contentTheme.primary, size: 16),
                                Spacing.width(12),
                                CustomizedText.titleMedium(S.of(context).pivPinManagement, fontWeight: 600, color: contentTheme.primary)
                              ],
                            ),
                          ),
                          Padding(
                            padding: Spacing.xy(flexSpacing, 16),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                CustomizedButton(
                                  onPressed: () {
                                    showChangePinDialog(
                                      title: S.of(context).changePin,
                                      oldValueLabel: S.of(context).oldPin,
                                      newValueLabel: S.of(context).newPin,
                                      prompt: S.of(context).changePinPrompt(6, 8),
                                      validators: [LengthValidator(min: 6, max: 8)],
                                      handler: controller.changePin,
                                    );
                                  },
                                  elevation: 0,
                                  padding: Spacing.xy(20, 16),
                                  backgroundColor: contentTheme.primary,
                                  borderRadiusAll: AppStyle.buttonRadius.medium,
                                  child: CustomizedText.bodySmall(S.of(context).changePin, color: contentTheme.onPrimary),
                                ),
                                CustomizedButton(
                                  onPressed: () {
                                    showChangePinDialog(
                                      title: S.of(context).pivChangePUK,
                                      oldValueLabel: S.of(context).pivOldPUK,
                                      newValueLabel: S.of(context).pivNewPUK,
                                      prompt: S.of(context).pivChangePUKPrompt(6, 8),
                                      validators: [LengthValidator(min: 6, max: 8)],
                                      handler: controller.changePUK,
                                    );
                                  },
                                  elevation: 0,
                                  padding: Spacing.xy(20, 16),
                                  backgroundColor: contentTheme.primary,
                                  borderRadiusAll: AppStyle.buttonRadius.medium,
                                  child: CustomizedText.bodySmall(S.of(context).pivChangePUK, color: contentTheme.onPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  showChangePinDialog({
    required String title,
    required String oldValueLabel,
    required String newValueLabel,
    required String prompt,
    List<FieldValidatorRule> validators = const [],
    required Function(String, String) handler,
  }) {
    RxBool showOldPin = false.obs;
    RxBool showNewPin = false.obs;
    FormValidator validator = FormValidator();
    validator.addField('oldPin', required: true, controller: TextEditingController(), validators: validators);
    validator.addField('newPin', required: true, controller: TextEditingController(), validators: validators);

    Get.dialog(
        Dialog(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: Spacing.all(16),
                  child: CustomizedText.labelLarge(title),
                ),
                Divider(height: 0, thickness: 1),
                Padding(
                    padding: Spacing.all(16),
                    child: Form(
                        key: validator.formKey,
                        child: Column(
                          children: [
                            CustomizedText.bodyMedium(prompt),
                            Spacing.height(16),
                            Obx(() => TextFormField(
                                  autofocus: true,
                                  onTap: () => SmartCard.eject(),
                                  obscureText: !showOldPin.value,
                                  controller: validator.getController('oldPin'),
                                  validator: validator.getValidator('oldPin'),
                                  decoration: InputDecoration(
                                    labelText: oldValueLabel,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(4)),
                                      borderSide: BorderSide(width: 1, strokeAlign: 0, color: AppTheme.theme.colorScheme.onBackground.withAlpha(80)),
                                    ),
                                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                                    suffixIcon: IconButton(
                                      onPressed: () => showOldPin.value = !showOldPin.value,
                                      icon: Icon(showOldPin.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                    ),
                                  ),
                                )),
                            Spacing.height(16),
                            Obx(() => TextFormField(
                                  onTap: () => SmartCard.eject(),
                                  obscureText: !showNewPin.value,
                                  controller: validator.getController('newPin'),
                                  validator: validator.getValidator('newPin'),
                                  decoration: InputDecoration(
                                    labelText: newValueLabel,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(4)),
                                      borderSide: BorderSide(width: 1, strokeAlign: 0, color: AppTheme.theme.colorScheme.onBackground.withAlpha(80)),
                                    ),
                                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                                    suffixIcon: IconButton(
                                      onPressed: () => showNewPin.value = !showNewPin.value,
                                      icon: Icon(showNewPin.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                    ),
                                  ),
                                )),
                          ],
                        ))),
                Divider(height: 0, thickness: 1),
                Padding(
                  padding: Spacing.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CustomizedButton.rounded(
                        onPressed: () {
                          Navigator.pop(Get.context!);
                        },
                        elevation: 0,
                        padding: Spacing.xy(20, 16),
                        backgroundColor: ContentThemeColor.secondary.color,
                        child: CustomizedText.labelMedium(S.of(Get.context!).cancel, color: ContentThemeColor.secondary.onColor),
                      ),
                      Spacing.width(16),
                      CustomizedButton.rounded(
                        onPressed: () {
                          if (validator.validateForm()) {
                            handler(validator.getController('oldPin')!.text, validator.getController('newPin')!.text);
                          }
                        },
                        elevation: 0,
                        padding: Spacing.xy(20, 16),
                        backgroundColor: ContentThemeColor.primary.color,
                        child: CustomizedText.labelMedium(S.of(Get.context!).confirm, color: ContentThemeColor.primary.onColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
