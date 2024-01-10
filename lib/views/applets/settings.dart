import 'package:canokey_console/controller/applets/settings.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/localization/language.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_style.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';
import 'package:canokey_console/helper/utils/my_shadow.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/my_button.dart';
import 'package:canokey_console/helper/widgets/my_card.dart';
import 'package:canokey_console/helper/widgets/my_container.dart';
import 'package:canokey_console/helper/widgets/my_spacing.dart';
import 'package:canokey_console/helper/widgets/my_text.dart';
import 'package:canokey_console/helper/widgets/my_validators.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:lucide_icons/lucide_icons.dart';

final log = Logger('Console:Settings:View');

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin, UIMixin {
  late SettingsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(SettingsController());
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      topActions: InkWell(
        onTap: () {
          if (controller.polled) {
            controller.refreshData(controller.pinCache);
          } else {
            Prompts.showInputPinDialog(S.of(context).settingsInputPin, "PIN", S.of(context).settingsInputPinPrompt).then((value) {
              controller.refreshData(value);
            }).onError((error, stackTrace) => null); // User canceled
          }
        },
        child: Icon(LucideIcons.refreshCw, size: 18, color: topBarTheme.onBackground),
      ),
      title: S.of(context).settings,
      child: GetBuilder(
        init: controller,
        builder: (controller) {
          MyCard actionsCard = MyCard(
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
                      Icon(LucideIcons.arrowRightCircle, color: contentTheme.primary, size: 16),
                      MySpacing.width(12),
                      MyText.titleMedium(S.of(context).actions, fontWeight: 600, color: contentTheme.primary)
                    ],
                  ),
                ),
                Padding(
                  padding: MySpacing.only(top: 12, left: 16, bottom: 12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (controller.polled) ...[
                        // Change PIN
                        MyButton(
                          onPressed: () {
                            Prompts.showInputPinDialog(S.of(context).changePin, 'PIN', S.of(context).changePinPrompt(6, 64),
                                    validators: [MyLengthValidator(min: 6, max: 64)])
                                .then((value) => controller.changePin(value))
                                .onError((error, stackTrace) => null); // Canceled
                          },
                          elevation: 0,
                          padding: MySpacing.xy(20, 16),
                          backgroundColor: contentTheme.secondary,
                          borderRadiusAll: AppStyle.buttonRadius.medium,
                          child: MyText.bodySmall(S.of(context).changePin, color: contentTheme.onSecondary),
                        ),
                        // Reset applets
                        buildResetButton(Applet.OATH, S.of(context).settingsResetOATH),
                        buildResetButton(Applet.PIV, S.of(context).settingsResetPIV),
                        buildResetButton(Applet.OpenPGP, S.of(context).settingsResetOpenPGP),
                        buildResetButton(Applet.NDEF, S.of(context).settingsResetNDEF),
                        if (controller.key.functionSet().contains(Func.resetWebAuthn)) ...{
                          buildResetButton(Applet.WebAuthn, S.of(context).settingsResetWebAuthn),
                        },
                        if (controller.key.functionSet().contains(Func.resetPass)) ...{
                          buildResetButton(Applet.PASS, S.of(context).settingsResetPass),
                        },
                        if (controller.key.model == CanoKey.pigeon)
                          MyButton(
                            onPressed: () {},
                            elevation: 0,
                            padding: MySpacing.xy(20, 16),
                            backgroundColor: contentTheme.danger,
                            borderRadiusAll: AppStyle.buttonRadius.medium,
                            child: MyText.bodySmall(S.of(context).settingsFixNFC, color: contentTheme.onDanger),
                          ),
                      ],
                      // Reset all
                      MyButton(
                        onPressed: _showResetDialog,
                        elevation: 0,
                        padding: MySpacing.xy(20, 16),
                        backgroundColor: contentTheme.danger,
                        borderRadiusAll: AppStyle.buttonRadius.medium,
                        child: MyText.bodySmall(S.of(context).settingsResetAll, color: contentTheme.onDanger),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );

          MyCard otherSettingsCard = MyCard(
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
                      Icon(LucideIcons.settings2, color: contentTheme.primary, size: 16),
                      MySpacing.width(12),
                      MyText.titleMedium(S.of(context).settingsOtherSettings, fontWeight: 600, color: contentTheme.primary)
                    ],
                  ),
                ),
                Padding(
                  padding: MySpacing.xy(flexSpacing, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildInfo(LucideIcons.languages, S.of(context).settingsLanguage, ThemeCustomizer.instance.currentLanguage.languageName,
                          () => _showLanguageDialog()),
                      buildInfo(
                          LucideIcons.languages,
                          S.of(context).settingsLanguage,
                          'Dark',
                          () => ThemeCustomizer.setTheme(
                                ThemeCustomizer.instance.theme == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
                              )),
                    ],
                  ),
                ),
              ],
            ),
          );

          if (!controller.polled) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: MySpacing.x(flexSpacing),
                  child: Column(
                    children: [
                      MySpacing.height(20),
                      Center(
                          child: Padding(
                        padding: MySpacing.horizontal(36),
                        child: MyText.bodyMedium(S.of(context).pollCanoKey, fontSize: 14),
                      )),
                      MySpacing.height(20),
                      actionsCard,
                      MySpacing.height(20),
                      otherSettingsCard,
                    ],
                  ),
                ),
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
                                Icon(LucideIcons.keyRound, color: contentTheme.primary, size: 16),
                                MySpacing.width(12),
                                MyText.titleMedium(S.of(context).settingsInfo, fontWeight: 600, color: contentTheme.primary)
                              ],
                            ),
                          ),
                          Padding(
                            padding: MySpacing.xy(flexSpacing, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildInfo(LucideIcons.shieldCheck, S.of(context).settingsModel, controller.key.model),
                                MySpacing.height(16),
                                buildInfo(LucideIcons.info, S.of(context).settingsFirmwareVersion, controller.key.firmwareVersion),
                                MySpacing.height(16),
                                buildInfo(LucideIcons.hash, S.of(context).settingsSN, controller.key.sn),
                                MySpacing.height(16),
                                buildInfo(LucideIcons.cpu, S.of(context).settingsChipId, controller.key.chipId),
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
                                Icon(LucideIcons.settings, color: contentTheme.primary, size: 16),
                                MySpacing.width(12),
                                MyText.titleMedium(S.of(context).settings, fontWeight: 600, color: contentTheme.primary)
                              ],
                            ),
                          ),
                          Padding(
                            padding: MySpacing.xy(flexSpacing, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // LED
                                if (controller.key.functionSet().contains(Func.led)) ...{
                                  buildInfo(LucideIcons.lightbulb, 'LED', controller.key.ledOn ? S.of(context).on : S.of(context).off,
                                      () => _showChangeSwitchDialog('LED', Func.led, controller.key.ledOn)),
                                  MySpacing.height(16),
                                },
                                // hotp
                                if (controller.key.functionSet().contains(Func.hotp)) ...{
                                  buildInfo(LucideIcons.keyboard, S.of(context).settingsHotp, controller.key.hotpOn ? S.of(context).on : S.of(context).off,
                                      () => _showChangeSwitchDialog(S.of(context).settingsHotp, Func.hotp, controller.key.hotpOn)),
                                  MySpacing.height(16),
                                },
                                // keyboard with return
                                if (controller.key.functionSet().contains(Func.keyboardWithReturn)) ...{
                                  buildInfo(
                                      LucideIcons.cornerDownLeft,
                                      S.of(context).settingsKeyboardWithReturn,
                                      controller.key.keyboardWithReturn ? S.of(context).on : S.of(context).off,
                                      () => _showChangeSwitchDialog(
                                          S.of(context).settingsKeyboardWithReturn, Func.keyboardWithReturn, controller.key.keyboardWithReturn)),
                                  MySpacing.height(16),
                                },
                                // webusb landing page
                                if (controller.key.functionSet().contains(Func.webusbLandingPage)) ...{
                                  buildInfo(
                                      LucideIcons.globe,
                                      S.of(context).settingsWebUSB,
                                      controller.key.webusbLandingEnabled ? S.of(context).on : S.of(context).off,
                                      () => _showChangeSwitchDialog(S.of(context).settingsWebUSB, Func.webusbLandingPage, controller.key.webusbLandingEnabled)),
                                  MySpacing.height(16),
                                },
                                // ndef enabled
                                if (controller.key.functionSet().contains(Func.ndefEnabled)) ...{
                                  buildInfo(LucideIcons.tag, S.of(context).settingsNDEF, controller.key.ndefEnabled ? S.of(context).on : S.of(context).off,
                                      () => _showChangeSwitchDialog(S.of(context).settingsNDEF, Func.ndefEnabled, controller.key.ndefEnabled)),
                                  MySpacing.height(16),
                                },
                                // ndef readonly
                                if (controller.key.functionSet().contains(Func.ndefReadonly)) ...{
                                  buildInfo(
                                      LucideIcons.shieldAlert,
                                      S.of(context).settingsNDEFReadonly,
                                      controller.key.ndefReadonly ? S.of(context).on : S.of(context).off,
                                      () => _showChangeSwitchDialog(S.of(context).settingsNDEFReadonly, Func.ndefReadonly, controller.key.ndefReadonly)),
                                  MySpacing.height(16),
                                },
                                // nfc
                                if (controller.key.functionSet().contains(Func.nfcSwitch)) ...{
                                  buildInfo(LucideIcons.nfc, 'NFC', controller.key.nfcEnabled ? S.of(context).on : S.of(context).off,
                                      () => _showChangeSwitchDialog('NFC', Func.nfcSwitch, controller.key.nfcEnabled)),
                                  MySpacing.height(16),
                                },
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    MySpacing.height(20),
                    actionsCard,
                    MySpacing.height(20),
                    otherSettingsCard,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildInfo(IconData iconData, String title, String value, [GestureTapCallback? handler]) {
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
                      Prompts.showSnackbar(S.of(context).copied, ContentThemeColor.success);
                    }),
              ],
            ),
          ),
          if (handler != null) Icon(Icons.arrow_forward_ios)
        ],
      ),
    );
  }

  MyButton buildResetButton(Applet applet, String resetText) {
    return MyButton(
      onPressed: () => _showResetDialog(applet: applet),
      elevation: 0,
      padding: MySpacing.xy(20, 16),
      backgroundColor: contentTheme.danger,
      borderRadiusAll: AppStyle.buttonRadius.medium,
      child: MyText.bodySmall(resetText, color: contentTheme.onDanger),
    );
  }

  void _showChangeSwitchDialog(String title, Func func, bool currentState) {
    RxBool newState = currentState.obs;
    Get.dialog(Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: MySpacing.all(16),
              child: MyText.labelLarge(S.of(context).settings),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
                padding: MySpacing.all(16),
                child: Row(
                  children: [
                    Obx(() => Checkbox(
                          onChanged: (value) => newState.value = value!,
                          value: newState.value,
                          activeColor: contentTheme.primary,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: getCompactDensity,
                        )),
                    MySpacing.width(16),
                    MyText.bodyMedium(title),
                  ],
                )),
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
                    onPressed: () => controller.changeSwitch(func, newState.value),
                    elevation: 0,
                    padding: MySpacing.xy(20, 16),
                    backgroundColor: contentTheme.primary,
                    child: MyText.labelMedium(S.of(context).confirm, color: contentTheme.onPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  void _showResetDialog({Applet? applet}) {
    String title = applet == null ? S.of(context).settingsResetAll : S.of(context).reset;
    String prompt = applet == null ? S.of(context).settingsResetAllPrompt : S.of(context).settingsResetApplet(applet.name);

    Get.dialog(Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: MySpacing.all(16),
              child: MyText.labelLarge(title),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: MySpacing.all(16),
              child: MyText.labelLarge(prompt),
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
                    onPressed: () => applet == null ? controller.resetCanokey() : controller.resetApplet(applet),
                    elevation: 0,
                    padding: MySpacing.xy(20, 16),
                    backgroundColor: contentTheme.danger,
                    child: MyText.labelMedium(S.of(context).reset, color: contentTheme.onDanger),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  void _showLanguageDialog() {
    RxString newLanguageCode = ThemeCustomizer.instance.currentLanguage.locale.toString().obs;

    Get.dialog(Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: MySpacing.all(16),
              child: MyText.labelLarge(S.of(context).settingsChangeLanguage),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
                padding: MySpacing.all(16),
                child: Obx(
                  () => Column(
                    children: Language.languages
                        .map((lang) => MyButton.text(
                            padding: MySpacing.xy(8, 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            splashColor: contentTheme.onBackground.withAlpha(20),
                            onPressed: () => newLanguageCode.value = lang.locale.toString(),
                            child: Row(
                              children: [
                                if (newLanguageCode.value == lang.locale.toString())
                                  Icon(Icons.check, color: contentTheme.primary, size: 16)
                                else
                                  MySpacing.width(16),
                                MySpacing.width(20),
                                Text(lang.languageName),
                              ],
                            )))
                        .toList(),
                  ),
                )),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: MySpacing.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MyButton.rounded(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    elevation: 0,
                    padding: MySpacing.xy(20, 16),
                    backgroundColor: contentTheme.secondary,
                    child: MyText.labelMedium(S.of(context).cancel, color: contentTheme.onSecondary),
                  ),
                  MySpacing.width(16),
                  MyButton.rounded(
                    onPressed: () async {
                      Language language = Language.getLanguageFromCode(newLanguageCode.value);
                      ThemeCustomizer.instance.currentLanguage = language;
                      await LocalStorage.setLanguage(language);
                      Get.updateLocale(language.locale);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    elevation: 0,
                    padding: MySpacing.xy(20, 16),
                    backgroundColor: contentTheme.primary,
                    child: MyText.labelMedium(S.of(context).confirm, color: contentTheme.onPrimary),
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
