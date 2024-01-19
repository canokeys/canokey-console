import 'package:canokey_console/controller/applets/pass.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/my_shadow.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/my_button.dart';
import 'package:canokey_console/helper/widgets/my_card.dart';
import 'package:canokey_console/helper/widgets/my_container.dart';
import 'package:canokey_console/helper/widgets/my_form_validator.dart';
import 'package:canokey_console/helper/widgets/my_spacing.dart';
import 'package:canokey_console/helper/widgets/my_text.dart';
import 'package:canokey_console/helper/widgets/my_validators.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:lucide_icons/lucide_icons.dart';

final log = Logger('Console:Pass:View');

class PassPage extends StatefulWidget {
  const PassPage({Key? key}) : super(key: key);

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
        child: Icon(LucideIcons.refreshCw, size: 18, color: topBarTheme.onBackground),
      ),
      child: GetBuilder(
        init: controller,
        builder: (_) {
          if (!controller.polled) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MySpacing.height(MediaQuery.of(context).size.height / 2 - 120),
                Center(
                    child: Padding(
                  padding: MySpacing.horizontal(36),
                  child: MyText.bodyMedium(S.of(context).pollCanoKey, fontSize: 24),
                )),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MySpacing.height(20),
                    MyCard(
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      shadow: MyShadow(elevation: 0.5, position: MyShadowPosition.bottom),
                      paddingAll: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            color: contentTheme.primary.withOpacity(0.08),
                            padding: MySpacing.xy(16, 12),
                            child: Row(
                              children: [
                                Icon(LucideIcons.keyboard, color: contentTheme.primary, size: 16),
                                MySpacing.width(12),
                                MyText.titleMedium(S.of(context).passSlotShort, fontWeight: 600, color: contentTheme.primary)
                              ],
                            ),
                          ),
                          Padding(
                            padding: MySpacing.xy(flexSpacing, 16),
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
                    MySpacing.height(20),
                    MyCard(
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      shadow: MyShadow(elevation: 0.5, position: MyShadowPosition.bottom),
                      paddingAll: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            color: contentTheme.primary.withOpacity(0.08),
                            padding: MySpacing.xy(16, 12),
                            child: Row(
                              children: [
                                Icon(LucideIcons.keyboard, color: contentTheme.primary, size: 16),
                                MySpacing.width(12),
                                MyText.titleMedium(S.of(context).passSlotLong, fontWeight: 600, color: contentTheme.primary)
                              ],
                            ),
                          ),
                          Padding(
                            padding: MySpacing.xy(flexSpacing, 16),
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
          MyContainer(
            paddingAll: 4,
            height: 32,
            width: 32,
            child: Icon(iconData, size: 20),
          ),
          MySpacing.width(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText.bodyMedium(title, fontSize: 16),
                InkWell(
                    child: MyText.bodySmall(value),
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

    MyFormValidator validator = MyFormValidator();
    validator.addField('password', required: true, controller: TextEditingController(), validators: [MyLengthValidator(min: 1, max: 32)]);

    Get.dialog(Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: MySpacing.all(16),
              child: MyText.labelLarge(S.of(context).passSlotConfigTitle),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
                padding: MySpacing.all(16),
                child: Form(
                    key: validator.formKey,
                    child: Obx(
                      () => Column(
                        children: [
                          MyText.labelLarge(S.of(context).passSlotConfigPrompt),
                          MySpacing.height(16),
                          Row(
                            children: [
                              SizedBox(width: 90, child: MyText.labelLarge(S.of(context).oathType)),
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
                                        MySpacing.width(8),
                                        MyText.labelMedium(_slotTypeName(PassSlotType.none))
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
                                        MySpacing.width(8),
                                        MyText.labelMedium(_slotTypeName(PassSlotType.static))
                                      ],
                                    ),
                                  ),
                                ]),
                              )
                            ],
                          ),
                          if (slotType.value == PassSlotType.static) ...{
                            MySpacing.height(16),
                            TextFormField(
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
                            MySpacing.height(16),
                            Row(
                              children: [
                                Obx(() => Checkbox(
                                      onChanged: (value) => withEnter.value = value!,
                                      value: withEnter.value,
                                      activeColor: contentTheme.primary,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: getCompactDensity,
                                    )),
                                MySpacing.width(16),
                                MyText.bodyMedium(S.of(context).passSlotWithEnter),
                              ],
                            ),
                          }
                        ],
                      ),
                    ))),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: MySpacing.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MyButton.rounded(
                    onPressed: () => Navigator.pop(context),
                    elevation: 0,
                    padding: MySpacing.xy(20, 16),
                    backgroundColor: contentTheme.secondary,
                    child: MyText.labelMedium(S.of(context).close, color: contentTheme.onSecondary),
                  ),
                  MySpacing.width(16),
                  MyButton.rounded(
                    onPressed: () {
                      if (slotType.value == PassSlotType.static && !validator.validateForm()) {
                        return;
                      }
                      controller.setSlot(index, slotType.value, validator.getController('password')!.text, withEnter.value);
                    },
                    elevation: 0,
                    padding: MySpacing.xy(20, 16),
                    backgroundColor: contentTheme.primary,
                    child: MyText.labelMedium(S.of(context).save, color: contentTheme.onPrimary),
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
