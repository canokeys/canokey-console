import 'package:canokey_console/controller/settings.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/localization/language.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_style.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';
import 'package:canokey_console/helper/utils/shadow.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_card.dart';
import 'package:canokey_console/helper/widgets/customized_container.dart';
import 'package:canokey_console/helper/widgets/form_validator.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:platform_detector/platform_detector.dart';

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
      title: S.of(context).settings,
      topActions: InkWell(
        onTap: () {
          if (controller.polled) {
            controller.refreshData();
          } else {
            Prompts.showInputPinDialog(
              title: S.of(context).settingsInputPin,
              label: 'PIN',
              prompt: S.of(context).settingsInputPinPrompt,
            ).then((value) {
              controller.pinCache = value;
              SmartCard.process(() async {
                await controller.selectAndVerifyPin(skipClear: true);
                await controller.refreshData();
              });
            }).onError((error, stackTrace) => null); // User canceled
          }
        },
        child: Icon(LucideIcons.refreshCw, size: 20, color: topBarTheme.onBackground),
      ),
      child: GetBuilder(
        init: controller,
        builder: (_) {
          // not polled
          if (!controller.polled) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: Spacing.x(flexSpacing),
                  child: Column(
                    children: [
                      Spacing.height(20),
                      Center(
                          child: Padding(
                        padding: Spacing.horizontal(36),
                        child: CustomizedText.bodyMedium(S.of(context).pollCanoKey, fontSize: 14),
                      )),
                      Spacing.height(20),
                      _buildActionCard(context),
                      Spacing.height(20),
                      _buildOtherSettingsCard(context),
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
                                Icon(LucideIcons.keyRound, color: contentTheme.primary, size: 16),
                                Spacing.width(12),
                                CustomizedText.titleMedium(S.of(context).settingsInfo, fontWeight: 600, color: contentTheme.primary)
                              ],
                            ),
                          ),
                          Padding(
                            padding: Spacing.xy(flexSpacing, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfo(LucideIcons.shieldCheck, S.of(context).settingsModel, controller.key.model),
                                Spacing.height(16),
                                _buildInfo(LucideIcons.info, S.of(context).settingsFirmwareVersion, controller.key.firmwareVersion),
                                Spacing.height(16),
                                _buildInfo(LucideIcons.hash, S.of(context).settingsSN, controller.key.sn),
                                Spacing.height(16),
                                _buildInfo(LucideIcons.cpu, S.of(context).settingsChipId, controller.key.chipId),
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
                                Icon(LucideIcons.settings, color: contentTheme.primary, size: 16),
                                Spacing.width(12),
                                CustomizedText.titleMedium(S.of(context).settings, fontWeight: 600, color: contentTheme.primary)
                              ],
                            ),
                          ),
                          Padding(
                            padding: Spacing.xy(flexSpacing, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // LED
                                if (controller.key.getFunctionSet().contains(Func.led)) ...{
                                  _buildInfo(LucideIcons.lightbulb, 'LED', controller.key.ledOn ? S.of(context).on : S.of(context).off,
                                      () => _showChangeSwitchDialog('LED', Func.led, controller.key.ledOn)),
                                  Spacing.height(16),
                                },
                                // hotp
                                if (controller.key.getFunctionSet().contains(Func.hotp)) ...{
                                  _buildInfo(LucideIcons.keyboard, S.of(context).settingsHotp, controller.key.hotpOn ? S.of(context).on : S.of(context).off,
                                      () => _showChangeSwitchDialog(S.of(context).settingsHotp, Func.hotp, controller.key.hotpOn)),
                                  Spacing.height(16),
                                },
                                // keyboard with return
                                if (controller.key.getFunctionSet().contains(Func.keyboardWithReturn)) ...{
                                  _buildInfo(
                                      LucideIcons.cornerDownLeft,
                                      S.of(context).settingsKeyboardWithReturn,
                                      controller.key.keyboardWithReturn ? S.of(context).on : S.of(context).off,
                                      () => _showChangeSwitchDialog(
                                          S.of(context).settingsKeyboardWithReturn, Func.keyboardWithReturn, controller.key.keyboardWithReturn)),
                                  Spacing.height(16),
                                },
                                // webusb landing page
                                if (controller.key.getFunctionSet().contains(Func.webusbLandingPage)) ...{
                                  _buildInfo(
                                      LucideIcons.globe,
                                      S.of(context).settingsWebUSB,
                                      controller.key.webusbLandingEnabled ? S.of(context).on : S.of(context).off,
                                      () => _showChangeSwitchDialog(S.of(context).settingsWebUSB, Func.webusbLandingPage, controller.key.webusbLandingEnabled)),
                                  Spacing.height(16),
                                },
                                // ndef enabled
                                if (controller.key.getFunctionSet().contains(Func.ndefEnabled)) ...{
                                  _buildInfo(LucideIcons.tag, S.of(context).settingsNDEF, controller.key.ndefEnabled ? S.of(context).on : S.of(context).off,
                                      () => _showChangeSwitchDialog(S.of(context).settingsNDEF, Func.ndefEnabled, controller.key.ndefEnabled)),
                                  Spacing.height(16),
                                },
                                // ndef readonly
                                if (controller.key.getFunctionSet().contains(Func.ndefReadonly)) ...{
                                  _buildInfo(
                                      LucideIcons.shieldAlert,
                                      S.of(context).settingsNDEFReadonly,
                                      controller.key.ndefReadonly ? S.of(context).on : S.of(context).off,
                                      () => _showChangeSwitchDialog(S.of(context).settingsNDEFReadonly, Func.ndefReadonly, controller.key.ndefReadonly)),
                                  Spacing.height(16),
                                },
                                // nfc
                                if (controller.key.getFunctionSet().contains(Func.nfcSwitch)) ...{
                                  _buildInfo(LucideIcons.nfc, 'NFC', controller.key.nfcEnabled ? S.of(context).on : S.of(context).off,
                                      () => _showChangeSwitchDialog('NFC', Func.nfcSwitch, controller.key.nfcEnabled)),
                                  Spacing.height(16),
                                },
                                // TODO: openpgp related items
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacing.height(20),
                    _buildActionCard(context),
                    Spacing.height(20),
                    _buildOtherSettingsCard(context),
                    Spacing.height(40),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionCard(BuildContext context) {
    return CustomizedCard(
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
                Icon(LucideIcons.arrowRightCircle, color: contentTheme.primary, size: 16),
                Spacing.width(12),
                CustomizedText.titleMedium(S.of(context).actions, fontWeight: 600, color: contentTheme.primary)
              ],
            ),
          ),
          Padding(
            padding: Spacing.only(top: 12, left: 16, bottom: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (controller.polled) ...[
                  // Change PIN
                  CustomizedButton(
                    onPressed: () {
                      Prompts.showInputPinDialog(
                        title: S.of(context).changePin,
                        label: 'PIN',
                        prompt: S.of(context).changePinPrompt(6, 64),
                        validators: [LengthValidator(min: 6, max: 64)],
                      ).then((value) => controller.changePin(value)).onError((error, stackTrace) => null); // Canceled
                    },
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.primary,
                    borderRadiusAll: AppStyle.buttonRadius.medium,
                    child: CustomizedText.bodySmall(S.of(context).changePin, color: contentTheme.onPrimary),
                  ),
                  // Change SM2 settings for WebAuthn
                  if (controller.key.webAuthnSm2Config != null) ...{
                    CustomizedButton(
                      onPressed: _showWebAuthnSm2ConfigDialog,
                      elevation: 0,
                      padding: Spacing.xy(20, 16),
                      backgroundColor: contentTheme.primary,
                      borderRadiusAll: AppStyle.buttonRadius.medium,
                      child: CustomizedText.bodySmall(S.of(context).settingsWebAuthnSm2Support, color: contentTheme.onPrimary),
                    ),
                  },
                  // Reset applets
                  _buildResetButton(Applet.OATH, S.of(context).settingsResetOATH),
                  _buildResetButton(Applet.PIV, S.of(context).settingsResetPIV),
                  _buildResetButton(Applet.OpenPGP, S.of(context).settingsResetOpenPGP),
                  _buildResetButton(Applet.NDEF, S.of(context).settingsResetNDEF),
                  if (controller.key.getFunctionSet().contains(Func.resetWebAuthn)) ...{
                    _buildResetButton(Applet.WebAuthn, S.of(context).settingsResetWebAuthn),
                  },
                  if (controller.key.getFunctionSet().contains(Func.resetPass)) ...{
                    _buildResetButton(Applet.PASS, S.of(context).settingsResetPass),
                  },
                  if (controller.key.model == CanoKey.pigeon && !isMobile())
                    CustomizedButton(
                      onPressed: controller.fixNfc,
                      elevation: 0,
                      padding: Spacing.xy(20, 16),
                      backgroundColor: contentTheme.danger,
                      borderRadiusAll: AppStyle.buttonRadius.medium,
                      child: CustomizedText.bodySmall(S.of(context).settingsFixNFC, color: contentTheme.onDanger),
                    ),
                ],
                // Reset all
                CustomizedButton(
                  onPressed: () {
                    if (isMobile()) {
                      Prompts.showPrompt(S.of(context).notSupportedInNFC, ContentThemeColor.info);
                    } else {
                      _showResetDialog();
                    }
                  },
                  elevation: 0,
                  padding: Spacing.xy(20, 16),
                  backgroundColor: contentTheme.danger,
                  borderRadiusAll: AppStyle.buttonRadius.medium,
                  child: CustomizedText.bodySmall(S.of(context).settingsResetAll, color: contentTheme.onDanger),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOtherSettingsCard(BuildContext context) {
    return CustomizedCard(
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
                Icon(LucideIcons.settings2, color: contentTheme.primary, size: 16),
                Spacing.width(12),
                CustomizedText.titleMedium(S.of(context).settingsOtherSettings, fontWeight: 600, color: contentTheme.primary)
              ],
            ),
          ),
          Padding(
            padding: Spacing.xy(flexSpacing, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfo(LucideIcons.languages, S.of(context).settingsLanguage, ThemeCustomizer.instance.currentLanguage.languageName, _showLanguageDialog),
                Spacing.height(16),
                _buildInfo(LucideIcons.home, S.of(context).settingsStartPage, _getPageName(LocalStorage.getStartPage() ?? '/'), _showStartUpDialog),
                // MySpacing.height(16),
                // _buildInfo(
                //     LucideIcons.languages,
                //     S.of(context).settingsLanguage,
                //     'Dark',
                //     () => ThemeCustomizer.setTheme(
                //           ThemeCustomizer.instance.theme == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
                //         )),
              ],
            ),
          ),
        ],
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

  Widget _buildResetButton(Applet applet, String resetText) {
    return CustomizedButton(
      onPressed: () => _showResetDialog(applet: applet),
      elevation: 0,
      padding: Spacing.xy(20, 16),
      backgroundColor: contentTheme.danger,
      borderRadiusAll: AppStyle.buttonRadius.medium,
      child: CustomizedText.bodySmall(resetText, color: contentTheme.onDanger),
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
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.of(context).settings),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
                padding: Spacing.all(16),
                child: Row(
                  children: [
                    Obx(() => Checkbox(
                          onChanged: (value) => newState.value = value!,
                          value: newState.value,
                          activeColor: contentTheme.primary,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: getCompactDensity,
                        )),
                    Spacing.width(16),
                    CustomizedText.bodyMedium(title),
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
                    onPressed: () => controller.changeSwitch(func, newState.value),
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
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(title),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(prompt),
            ),
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
                    onPressed: () => applet == null ? controller.resetCanokey() : controller.resetApplet(applet),
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.danger,
                    child: CustomizedText.labelMedium(S.of(context).reset, color: contentTheme.onDanger),
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
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
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
    ));
  }

  void _showStartUpDialog() {
    RxString startPage = (LocalStorage.getStartPage() ?? '/').obs;

    Get.dialog(Dialog(
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
                    children: [
                      _buildStartPageItem(startPage, '/'),
                      _buildStartPageItem(startPage, '/applets/oath'),
                      _buildStartPageItem(startPage, '/applets/pass'),
                    ],
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
    ));
  }

  Widget _buildStartPageItem(RxString startPage, String path) {
    return CustomizedButton.text(
        padding: Spacing.xy(8, 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        splashColor: contentTheme.onBackground.withAlpha(20),
        onPressed: () => startPage.value = path,
        child: Row(
          children: [
            if (startPage.value == path) Icon(Icons.check, color: contentTheme.primary, size: 16) else Spacing.width(16),
            Spacing.width(20),
            Text(_getPageName(path)),
          ],
        ));
  }

  void _showWebAuthnSm2ConfigDialog() {
    RxBool enabled = controller.key.webAuthnSm2Config!.enabled.obs;

    FormValidator validator = FormValidator();
    validator.addField('curveId', controller: TextEditingController(), validators: [IntValidator(min: -65536, max: 65535)]);
    validator.addField('algoId', controller: TextEditingController(), validators: [IntValidator(min: -65536, max: 65535)]);
    validator.getController('curveId')!.text = controller.key.webAuthnSm2Config!.curveId.toString();
    validator.getController('algoId')!.text = controller.key.webAuthnSm2Config!.algoId.toString();

    Get.dialog(Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.of(context).settingsWebAuthnSm2Support),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
                padding: Spacing.all(16),
                child: Form(
                    key: validator.formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Obx(() => Checkbox(
                                  onChanged: (value) => enabled.value = value!,
                                  value: enabled.value,
                                  activeColor: contentTheme.primary,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: getCompactDensity,
                                )),
                            Spacing.width(16),
                            CustomizedText.bodyMedium(S.of(context).enabled),
                          ],
                        ),
                        Spacing.height(16),
                        TextFormField(
                          autofocus: true,
                          onTap: () => SmartCard.eject(),
                          controller: validator.getController('curveId'),
                          validator: validator.getValidator('curveId'),
                          decoration: InputDecoration(
                            labelText: 'Curve ID',
                            border: outlineInputBorder,
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                        ),
                        Spacing.height(16),
                        TextFormField(
                          onTap: () => SmartCard.eject(),
                          controller: validator.getController('algoId'),
                          validator: validator.getValidator('algoId'),
                          decoration: InputDecoration(
                            labelText: 'Algorithm ID',
                            border: outlineInputBorder,
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                        ),
                      ],
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
                      if (validator.formKey.currentState!.validate()) {
                        controller.changeWebAuthnSm2Config(
                            enabled.value, int.parse(validator.getController('curveId')!.text), int.parse(validator.getController('algoId')!.text));
                      }
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

  String _getPageName(String path) {
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
}
