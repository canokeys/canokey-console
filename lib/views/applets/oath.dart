import 'package:canokey_console/controller/applets/oath.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/my_shadow.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/my_button.dart';
import 'package:canokey_console/helper/widgets/my_card.dart';
import 'package:canokey_console/helper/widgets/my_container.dart';
import 'package:canokey_console/helper/widgets/my_spacing.dart';
import 'package:canokey_console/helper/widgets/my_text.dart';
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
                child: Icon(LucideIcons.refreshCw, size: 18, color: topBarTheme.onBackground),
              )
            ];
            if (controller.polled) {
              widgets.insertAll(0, [
                InkWell(
                  onTap: _showAddAccountDialog,
                  child: Icon(LucideIcons.plus, size: 18, color: topBarTheme.onBackground),
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
                  child: Icon(LucideIcons.lock, size: 18, color: topBarTheme.onBackground),
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
          if (controller.oathItems.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MySpacing.height(MediaQuery.of(context).size.height / 2 - 100),
                Center(child: MyText.bodyMedium(S.of(context).oathNoCredential, fontSize: 24)),
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
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      itemCount: controller.oathItems.length,
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
    OathItem item = controller.oathItems[index];
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
                    PopupMenuItem(padding: MySpacing.xy(16, 8), height: 10, child: MyText.bodySmall("Delete")),
                    PopupMenuItem(padding: MySpacing.xy(16, 8), height: 10, child: MyText.bodySmall("Add Member")),
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
                  Prompts.showSnackbar('Copied', ContentThemeColor.success);
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
    Get.dialog(Dialog(
      child: SizedBox(
        width: 400,
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
                    key: controller.validators.formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          autofocus: true,
                          controller: controller.validators.getController('issuer'),
                          validator: controller.validators.getValidator('issuer'),
                          decoration: InputDecoration(
                            labelText: S.of(context).oathIssuer,
                            border: outlineInputBorder,
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                        ),
                        MySpacing.height(16),
                        TextFormField(
                          controller: controller.validators.getController('account'),
                          validator: controller.validators.getValidator('account'),
                          decoration: InputDecoration(
                            labelText: S.of(context).oathAccount,
                            border: outlineInputBorder,
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                        ),
                        MySpacing.height(16),
                        TextFormField(
                          controller: controller.validators.getController('secret'),
                          validator: controller.validators.getValidator('secret'),
                          decoration: InputDecoration(
                            labelText: S.of(context).oathSecret,
                            border: outlineInputBorder,
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                        ),
                        MySpacing.height(16),
                        Row(
                          children: [
                            Obx(() => Checkbox(
                                  onChanged: (value) => controller.requireTouch.value = value!,
                                  value: controller.requireTouch.value,
                                  activeColor: contentTheme.primary,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: getCompactDensity,
                                )),
                            MySpacing.width(16),
                            MyText.bodyMedium(S.of(context).oathRequireTouch),
                          ],
                        ),
                        MySpacing.height(16),
                        MyText.bodyMedium("以下为高级设置，请谨慎选择"),
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
                                                Obx(() => Radio<OathType>(
                                                      value: type,
                                                      activeColor: contentTheme.primary,
                                                      groupValue: controller.type.value,
                                                      onChanged: (type) => controller.type.value = type!,
                                                      visualDensity: getCompactDensity,
                                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    )),
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
                                                Obx(() => Radio<OathAlgorithm>(
                                                      value: algo,
                                                      activeColor: contentTheme.primary,
                                                      groupValue: controller.algo.value,
                                                      onChanged: (algo) => controller.algo.value = algo!,
                                                      visualDensity: getCompactDensity,
                                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    )),
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
                                                Obx(() => Radio<int>(
                                                      value: digits,
                                                      activeColor: contentTheme.primary,
                                                      groupValue: controller.digits.value,
                                                      onChanged: (digits) => controller.digits.value = digits!,
                                                      visualDensity: getCompactDensity,
                                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    )),
                                                MySpacing.width(8),
                                                MyText.labelMedium(digits.toString())
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList()))
                          ],
                        ),
                        Obx(() {
                          if (controller.type.value == OathType.hotp) {
                            return Column(children: [
                              MySpacing.height(16),
                              TextFormField(
                                controller: controller.validators.getController('counter'),
                                validator: controller.validators.getValidator('counter'),
                                decoration: InputDecoration(
                                  labelText: S.of(context).oathCounter,
                                  border: outlineInputBorder,
                                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                                ),
                              ),
                            ]);
                          } else {
                            return Container();
                          }
                        }),
                      ],
                    ))),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: MySpacing.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MyButton.rounded(
                    onPressed: () {
                      controller.resetForms();
                      Navigator.pop(context);
                    },
                    elevation: 0,
                    padding: MySpacing.xy(20, 16),
                    backgroundColor: contentTheme.secondary,
                    child: MyText.labelMedium(S.of(context).close, color: contentTheme.onSecondary),
                  ),
                  MySpacing.width(16),
                  MyButton.rounded(
                    onPressed: controller.addAccount,
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
}
