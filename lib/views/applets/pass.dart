import 'package:canokey_console/controller/applets/pass.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/shadow.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/form_validator.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_card.dart';
import 'package:canokey_console/helper/widgets/customized_container.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:lucide_icons/lucide_icons.dart';

final log = Logger('Console:Pass:View');

class PassPage extends StatefulWidget {
  const PassPage({super.key});

  @override
  State<PassPage> createState() => _PassPageState();
}

class _PassPageState extends State<PassPage> with SingleTickerProviderStateMixin, UIMixin {
  late PassController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(PassController());
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      title: 'Pass',
      topActions: InkWell(
        onTap: () {
          if (controller.polled) {
            controller.refreshData(controller.pinCache);
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
                                CustomizedText.titleMedium(S.of(context).passSlotShort, fontWeight: 600, color: contentTheme.primary)
                              ],
                            ),
                          ),
                          Padding(
                            padding: Spacing.xy(flexSpacing, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfo(LucideIcons.shieldCheck, S.of(context).passStatus, _slotStatus(controller.slotShort),
                                    () => _showSlotConfigDialog(PassController.short, controller.slotShort)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
                                CustomizedText.titleMedium(S.of(context).passSlotLong, fontWeight: 600, color: contentTheme.primary)
                              ],
                            ),
                          ),
                          Padding(
                            padding: Spacing.xy(flexSpacing, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfo(LucideIcons.shieldCheck, S.of(context).passStatus, _slotStatus(controller.slotLong),
                                    () => _showSlotConfigDialog(PassController.short, controller.slotShort)),
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

  Widget _buildInfo(IconData iconData, String title, String value, [GestureTapCallback? handler]) {
    return InkWell(
      onTap: handler,
      child: Row(
        children: [
          CustomizedContainer(
            paddingAll: 4,
            height: 32,
            width: 32,
            child: Icon(iconData, size: 20),
          ),
          Spacing.width(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomizedText.bodyMedium(title, fontSize: 16),
                InkWell(
                    child: CustomizedText.bodySmall(value),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      Prompts.showPrompt(S.of(context).copied, ContentThemeColor.success);
                    }),
              ],
            ),
          ),
          if (handler != null) Icon(Icons.arrow_forward_ios)
        ],
      ),
    );
  }

  void _showSlotConfigDialog(int index, PassSlot slot) {
    RxBool showPassword = false.obs;
    RxBool withEnter = slot.withEnter.obs;
    Rx<PassSlotType> slotType = Rx<PassSlotType>(slot.type);

    FormValidator validator = FormValidator();
    validator.addField('password', required: true, controller: TextEditingController(), validators: [LengthValidator(min: 1, max: 32)]);

    Get.dialog(Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.of(context).passSlotConfigTitle),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
                padding: Spacing.all(16),
                child: Form(
                    key: validator.formKey,
                    child: Obx(
                      () => Column(
                        children: [
                          CustomizedText.labelLarge(S.of(context).passSlotConfigPrompt),
                          Spacing.height(16),
                          Row(
                            children: [
                              SizedBox(width: 90, child: CustomizedText.labelLarge(S.of(context).oathType)),
                              Expanded(
                                child: Wrap(spacing: 16, children: [
                                  InkWell(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Radio<PassSlotType>(
                                          value: PassSlotType.none,
                                          activeColor: contentTheme.primary,
                                          groupValue: slotType.value,
                                          onChanged: (type) => slotType.value = type!,
                                          visualDensity: getCompactDensity,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        Spacing.width(8),
                                        CustomizedText.labelMedium(_slotTypeName(PassSlotType.none))
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Radio<PassSlotType>(
                                          value: PassSlotType.static,
                                          activeColor: contentTheme.primary,
                                          groupValue: slotType.value,
                                          onChanged: (type) => slotType.value = type!,
                                          visualDensity: getCompactDensity,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        Spacing.width(8),
                                        CustomizedText.labelMedium(_slotTypeName(PassSlotType.static))
                                      ],
                                    ),
                                  ),
                                ]),
                              )
                            ],
                          ),
                          if (slotType.value == PassSlotType.static) ...{
                            Spacing.height(16),
                            TextFormField(
                              onTap: () => SmartCard.eject(),
                              obscureText: !showPassword.value,
                              controller: validator.getController('password'),
                              validator: validator.getValidator('password'),
                              decoration: InputDecoration(
                                labelText: S.of(context).passSlotStatic,
                                border: outlineInputBorder,
                                floatingLabelBehavior: FloatingLabelBehavior.auto,
                                suffixIcon: IconButton(
                                  onPressed: () => showPassword.value = !showPassword.value,
                                  icon: Icon(showPassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                ),
                              ),
                            ),
                          },
                          if (slotType.value != PassSlotType.none) ...{
                            Spacing.height(16),
                            Row(
                              children: [
                                Obx(() => Checkbox(
                                      onChanged: (value) => withEnter.value = value!,
                                      value: withEnter.value,
                                      activeColor: contentTheme.primary,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: getCompactDensity,
                                    )),
                                Spacing.width(16),
                                CustomizedText.bodyMedium(S.of(context).passSlotWithEnter),
                              ],
                            ),
                          }
                        ],
                      ),
                    ))),
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
                    child: CustomizedText.labelMedium(S.of(context).close, color: contentTheme.onSecondary),
                  ),
                  Spacing.width(16),
                  CustomizedButton.rounded(
                    onPressed: () {
                      if (slotType.value == PassSlotType.static && !validator.validateForm()) {
                        return;
                      }
                      controller.setSlot(index, slotType.value, validator.getController('password')!.text, withEnter.value);
                    },
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium(S.of(context).save, color: contentTheme.onPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  String _slotStatus(PassSlot slot) {
    switch (slot.type) {
      case PassSlotType.none:
        return S.of(context).passSlotOff;
      case PassSlotType.oath:
        return '${S.of(context).passSlotHotp} (${slot.name})';
      case PassSlotType.static:
        return S.of(context).passSlotStatic;
    }
  }

  String _slotTypeName(PassSlotType type) {
    switch (type) {
      case PassSlotType.none:
        return S.of(context).passSlotOff;
      case PassSlotType.oath:
        return S.of(context).passSlotHotp;
      case PassSlotType.static:
        return S.of(context).passSlotStatic;
    }
  }
}
