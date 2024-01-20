import 'package:base32/base32.dart';
import 'package:canokey_console/controller/applets/oath.dart';
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
import 'package:canokey_console/models/oath.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:timer_controller/timer_controller.dart';

final log = Logger('Console:OATH:View');

class OathPage extends StatefulWidget {
  const OathPage({Key? key}) : super(key: key);

  @override
  State<OathPage> createState() => _OathPageState();
}

class _OathPageState extends State<OathPage> with SingleTickerProviderStateMixin, UIMixin {
  late OathController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(OathController());
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      title: "TOTP / HOTP",
      topActions: GetBuilder(
          init: controller,
          builder: (_) {
            List<Widget> widgets = [
              InkWell(
                onTap: controller.refreshData,
                child: Icon(LucideIcons.refreshCw, size: 20, color: topBarTheme.onBackground),
              )
            ];
            if (controller.polled) {
              widgets.insertAll(0, [
                InkWell(
                  onTap: _showAddAccountDialog,
                  child: Icon(LucideIcons.plus, size: 20, color: topBarTheme.onBackground),
                ),
                MySpacing.width(12),
                InkWell(
                  onTap: () {
                    Prompts.showInputPinDialog(
                      title: S.of(context).oathSetCode,
                      label: S.of(context).oathCode,
                      prompt: S.of(context).oathNewCodePrompt,
                      required: false,
                    ).then((value) => controller.setCode(value)).onError((error, stackTrace) => null); // Canceled
                  },
                  child: Icon(LucideIcons.lock, size: 20, color: topBarTheme.onBackground),
                ),
                MySpacing.width(12),
              ]);
            }
            return Row(children: widgets);
          }),
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
          if (controller.oathMap.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MySpacing.height(MediaQuery.of(context).size.height / 2 - 100),
                Center(child: MyText.bodyMedium(S.of(context).noCredential, fontSize: 24)),
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
                    GridView.builder(
                      physics: ScrollPhysics(),
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      itemCount: controller.oathMap.length,
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 500, crossAxisSpacing: 16, mainAxisSpacing: 16, mainAxisExtent: 150),
                      itemBuilder: (context, index) => buildOathItem(controller, index),
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  MyCard buildOathItem(OathController controller, int index) {
    String name = controller.oathMap.keys.toList()[index];
    OathItem item = controller.oathMap[name]!;
    return MyCard(
      shadow: MyShadow(elevation: 0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText.bodyMedium(item.issuer, fontSize: 16, fontWeight: 600),
              MyContainer.none(
                paddingAll: 8,
                borderRadiusAll: 5,
                child: PopupMenuButton(
                  offset: const Offset(0, 10),
                  position: PopupMenuPosition.under,
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      padding: MySpacing.xy(16, 8),
                      height: 10,
                      child: MyText.bodySmall(S.of(context).delete),
                      onTap: () => _showDeleteDialog(item.name),
                    ),
                    if (item.type == OathType.hotp)
                      PopupMenuItem(
                        padding: MySpacing.xy(16, 8),
                        height: 10,
                        child: MyText.bodySmall(S.of(context).oathSetDefault),
                        onTap: () => _showSetDefaultDialog(item.name),
                      ),
                  ],
                  child: const Icon(LucideIcons.moreHorizontal, size: 18),
                ),
              ),
            ],
          ),
          Row(
            children: [
              MyContainer.rounded(
                color: contentTheme.primary.withAlpha(30),
                paddingAll: 2,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: Icon(LucideIcons.user, size: 16, color: contentTheme.primary),
              ),
              MySpacing.width(12),
              MyText.bodyMedium(item.account),
            ],
          ),
          Row(
            children: [
              // For HOTP, no time indicator, only a refresh button
              if (item.type == OathType.hotp)
                IconButton(
                  onPressed: () {
                    controller.calculate(item.name, item.type);
                  },
                  icon: Icon(LucideIcons.refreshCw, size: 20, color: contentTheme.primary),
                ),
              // For TOTP, if no touch required (with a valid code), show the indicator
              if (item.type == OathType.totp && item.code.isNotEmpty)
                TimerControllerBuilder(
                    controller: controller.timerController,
                    builder: (_, value, __) => CircularPercentIndicator(
                          radius: 20,
                          lineWidth: 5,
                          percent: 1 - value.remaining / 30,
                          center: new Text(value.remaining.toString()),
                          progressColor: contentTheme.primary,
                          backgroundColor: contentTheme.primary.withAlpha(30),
                        )),
              if (item.type == OathType.totp && item.code.isEmpty && item.requireTouch)
                IconButton(
                  onPressed: () {
                    controller.calculate(item.name, item.type);
                  },
                  icon: Icon(Icons.touch_app, size: 20, color: contentTheme.primary),
                ),
              if (item.type == OathType.totp && item.code.isEmpty && !item.requireTouch)
                CircularPercentIndicator(
                  radius: 20,
                  lineWidth: 5,
                  percent: 0,
                  center: new Text("0"),
                  progressColor: contentTheme.primary,
                  backgroundColor: contentTheme.primary.withAlpha(30),
                ),
              MySpacing.width(16),
              MyText.bodyMedium(
                item.code.isEmpty ? '******' : item.code,
                style: GoogleFonts.robotoMono(fontSize: 28),
              ),
              MySpacing.width(16),
              IconButton(
                color: item.code.isEmpty ? contentTheme.cardTextMuted : contentTheme.primary,
                onPressed: () {
                  if (item.code.isEmpty) {
                    return;
                  }
                  Clipboard.setData(ClipboardData(text: item.code));
                  Prompts.showPrompt('Copied', ContentThemeColor.success);
                },
                icon: Icon(LucideIcons.copy, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddAccountDialog() {
    MyFormValidator validator = MyFormValidator();
    RxBool requireTouch = false.obs;
    Rx<OathType> oathType = OathType.totp.obs;
    Rx<OathAlgorithm> oathAlgo = OathAlgorithm.sha1.obs;
    RxInt oathDigits = 6.obs;

    validator.addField('issuer', required: true, controller: TextEditingController());
    validator.addField('account', required: true, controller: TextEditingController());
    validator.addField('secret', required: true, controller: TextEditingController(), validators: [MyLengthValidator(min: 8, max: 52)]);
    TextEditingController counterController = TextEditingController();
    counterController.text = '0';
    validator.addField('counter', required: true, controller: counterController, validators: [MyIntValidator(min: 0, max: 4294967295)]);

    Get.dialog(
        Dialog(
          child: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: MySpacing.all(16),
                    child: MyText.labelLarge(S.of(context).oathAddAccount),
                  ),
                  Divider(height: 0, thickness: 1),
                  Padding(
                      padding: MySpacing.all(16),
                      child: Form(
                          key: validator.formKey,
                          child: Obx(
                            () => Column(
                              children: [
                                TextFormField(
                                  autofocus: true,
                                  controller: validator.getController('issuer'),
                                  validator: validator.getValidator('issuer'),
                                  decoration: InputDecoration(
                                    labelText: S.of(context).oathIssuer,
                                    border: outlineInputBorder,
                                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                                  ),
                                ),
                                MySpacing.height(16),
                                TextFormField(
                                  controller: validator.getController('account'),
                                  validator: validator.getValidator('account'),
                                  decoration: InputDecoration(
                                    labelText: S.of(context).oathAccount,
                                    border: outlineInputBorder,
                                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                                  ),
                                ),
                                MySpacing.height(16),
                                TextFormField(
                                  controller: validator.getController('secret'),
                                  validator: validator.getValidator('secret'),
                                  decoration: InputDecoration(
                                    labelText: S.of(context).oathSecret,
                                    border: outlineInputBorder,
                                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                                  ),
                                ),
                                MySpacing.height(16),
                                Row(
                                  children: [
                                    Checkbox(
                                      onChanged: (value) => requireTouch.value = value!,
                                      value: requireTouch.value,
                                      activeColor: contentTheme.primary,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: getCompactDensity,
                                    ),
                                    MySpacing.width(16),
                                    MyText.bodyMedium(S.of(context).oathRequireTouch),
                                  ],
                                ),
                                MySpacing.height(16),
                                MyText.bodyMedium(S.of(context).oathAdvancedSettings),
                                MySpacing.height(12),
                                Row(
                                  children: [
                                    SizedBox(width: 90, child: MyText.labelLarge(S.of(context).oathType)),
                                    Expanded(
                                        child: Wrap(
                                            spacing: 16,
                                            children: OathType.values
                                                .map(
                                                  (type) => InkWell(
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Radio<OathType>(
                                                          value: type,
                                                          activeColor: contentTheme.primary,
                                                          groupValue: oathType.value,
                                                          onChanged: (type) => oathType.value = type!,
                                                          visualDensity: getCompactDensity,
                                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                        ),
                                                        MySpacing.width(8),
                                                        MyText.labelMedium(type.name.toUpperCase())
                                                      ],
                                                    ),
                                                  ),
                                                )
                                                .toList()))
                                  ],
                                ),
                                MySpacing.height(12),
                                Row(
                                  children: [
                                    SizedBox(width: 90, child: MyText.labelLarge(S.of(context).oathAlgorithm)),
                                    Expanded(
                                        child: Wrap(
                                            spacing: 16,
                                            children: OathAlgorithm.values
                                                .map(
                                                  (algo) => InkWell(
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Radio<OathAlgorithm>(
                                                          value: algo,
                                                          activeColor: contentTheme.primary,
                                                          groupValue: oathAlgo.value,
                                                          onChanged: (algo) => oathAlgo.value = algo!,
                                                          visualDensity: getCompactDensity,
                                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                        ),
                                                        MySpacing.width(8),
                                                        MyText.labelMedium(algo.name.toUpperCase())
                                                      ],
                                                    ),
                                                  ),
                                                )
                                                .toList()))
                                  ],
                                ),
                                MySpacing.height(12),
                                Row(
                                  children: [
                                    SizedBox(width: 90, child: MyText.labelLarge(S.of(context).oathDigits)),
                                    Expanded(
                                        child: Wrap(
                                            spacing: 16,
                                            children: [6, 7, 8]
                                                .map(
                                                  (digits) => InkWell(
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Radio<int>(
                                                          value: digits,
                                                          activeColor: contentTheme.primary,
                                                          groupValue: oathDigits.value,
                                                          onChanged: (digits) => oathDigits.value = digits!,
                                                          visualDensity: getCompactDensity,
                                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                        ),
                                                        MySpacing.width(8),
                                                        MyText.labelMedium(digits.toString())
                                                      ],
                                                    ),
                                                  ),
                                                )
                                                .toList()))
                                  ],
                                ),
                                if (oathType.value == OathType.hotp) ...{
                                  Column(children: [
                                    MySpacing.height(16),
                                    TextFormField(
                                      controller: validator.getController('counter'),
                                      validator: validator.getValidator('counter'),
                                      decoration: InputDecoration(
                                        labelText: S.of(context).oathCounter,
                                        border: outlineInputBorder,
                                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                                      ),
                                    ),
                                  ]),
                                },
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
                            if (!validator.validateForm(clear: true)) {
                              return;
                            }
                            String issuer = validator.getData()['issuer'];
                            String account = validator.getData()['account'];
                            String secret = validator.getData()['secret'];
                            int initValue = int.parse(validator.getData()['counter']);
                            String name = '$issuer:$account';
                            if (name.length > 63) {
                              validator.addError('account', S.of(context).oathTooLong);
                              validator.formKey.currentState!.validate();
                              return;
                            }
                            late String secretHex;
                            try {
                              secretHex = base32.decodeAsHexString(secret.toUpperCase());
                            } catch (e) {
                              validator.addError('secret', S.of(Get.context!).oathInvalidKey);
                              validator.formKey.currentState!.validate();
                              return;
                            }
                            controller.addAccount(name, secretHex, oathType.value, oathAlgo.value, oathDigits.value, requireTouch.value, initValue);
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
          ),
        ),
        barrierDismissible: false);
  }

  void _showDeleteDialog(String name) {
    Get.dialog(Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: MySpacing.all(16),
              child: MyText.labelLarge(S.of(context).delete),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: MySpacing.all(16),
              child: MyText.labelLarge(S.of(context).oathDelete(name)),
            ),
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
                    child: MyText.labelMedium(S.of(context).cancel, color: contentTheme.onSecondary),
                  ),
                  MySpacing.width(16),
                  MyButton.rounded(
                    onPressed: () => controller.delete(name),
                    elevation: 0,
                    padding: MySpacing.xy(20, 16),
                    backgroundColor: contentTheme.danger,
                    child: MyText.labelMedium(S.of(context).delete, color: contentTheme.onDanger),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  void _showSetDefaultDialog(String name) {
    RxInt slot = 1.obs;
    RxBool withEnter = false.obs;

    Get.dialog(Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: MySpacing.all(16),
              child: MyText.labelLarge(S.of(context).oathSetDefault),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: MySpacing.all(16),
              child: Obx(
                () => Column(
                  children: [
                    MyText.labelLarge(S.of(context).oathSetDefaultPrompt(name)),
                    MySpacing.height(16),
                    Row(
                      children: [
                        SizedBox(width: 80, child: MyText.labelLarge(S.of(context).oathSlot)),
                        PopupMenuButton(
                            itemBuilder: (BuildContext context) => [
                                  PopupMenuItem(
                                    padding: MySpacing.xy(16, 8),
                                    height: 10,
                                    child: MyText.bodySmall(S.of(context).passSlotShort),
                                    onTap: () => slot.value = 1,
                                  ),
                                  PopupMenuItem(
                                    padding: MySpacing.xy(16, 8),
                                    height: 10,
                                    child: MyText.bodySmall(S.of(context).passSlotLong),
                                    onTap: () => slot.value = 2,
                                  ),
                                ],
                            child: MyContainer.bordered(
                              padding: MySpacing.xy(12, 8),
                              child: Row(
                                children: <Widget>[
                                  MyText.labelMedium(
                                    slot.value == 1 ? S.of(context).passSlotShort : S.of(context).passSlotLong,
                                    color: contentTheme.onBackground,
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.expand_more_outlined, size: 22, color: contentTheme.onBackground),
                                  )
                                ],
                              ),
                            )),
                      ],
                    ),
                    MySpacing.height(16),
                    Row(
                      children: [
                        Checkbox(
                          onChanged: (value) => withEnter.value = value!,
                          value: withEnter.value,
                          activeColor: contentTheme.primary,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: getCompactDensity,
                        ),
                        MySpacing.width(16),
                        MyText.bodyMedium(S.of(context).passSlotWithEnter),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
                    child: MyText.labelMedium(S.of(context).cancel, color: contentTheme.onSecondary),
                  ),
                  MySpacing.width(16),
                  MyButton.rounded(
                    onPressed: () => controller.setDefault(name, slot.value, withEnter.value),
                    elevation: 0,
                    padding: MySpacing.xy(20, 16),
                    backgroundColor: contentTheme.success,
                    child: MyText.labelMedium(S.of(context).confirm, color: contentTheme.onSuccess),
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
