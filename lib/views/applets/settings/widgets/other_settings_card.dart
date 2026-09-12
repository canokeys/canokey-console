import 'package:canokey_console/helper/widgets/applet_section_card.dart';
import 'package:canokey_console/views/applets/settings/widgets/settings_surface.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';
import 'package:canokey_console/helper/utils/icp_filing.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/customized_text_style.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/views/applets/settings/dialogs/language_dialog.dart';
import 'package:canokey_console/views/applets/settings/dialogs/nfc_sound_dialog.dart';
import 'package:canokey_console/views/applets/settings/dialogs/start_page_dialog.dart';
import 'package:canokey_console/views/applets/settings/dialogs/clear_pin_cache_dialog.dart';
import 'package:canokey_console/views/applets/settings/widgets/info_item.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:platform_detector/platform_detector.dart';
import 'package:url_launcher/url_launcher.dart';

class OtherSettingsCard extends StatefulWidget {
  final bool showNfcSound;

  const OtherSettingsCard({super.key, required this.showNfcSound});

  @override
  State<OtherSettingsCard> createState() => _OtherSettingsCardState();
}

class _OtherSettingsCardState extends State<OtherSettingsCard> with UIMixin {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> _launchUrl(Uri url) async {
    Logging.logger(
      'Settings:Page',
    ).t('Call _OtherSettingsCardState._launchUrl');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final languageName = ThemeCustomizer.instance.currentLanguage.languageName;
    final isChinese = Localizations.localeOf(context).languageCode == 'zh';
    final privacyPolicyUrl = isChinese
        ? 'https://www.canokeys.com/privacy/'
        : 'https://www.canokeys.org/privacy/';
    final feedbackEmail = isChinese
        ? 'support@canokeys.com'
        : 'support@canokeys.org';
    final startPage = StartPageDialog.pageName(
      context,
      LocalStorage.getStartPage() ?? '/',
    );
    final icpFiling = icpFilingNumber();
    return AppletSectionCard(
      icon: LucideIcons.settings2,
      title: S.of(context).settingsOtherSettings,
      child: SettingsRows(
        children: [
          InfoItem(
            iconData: LucideIcons.languages,
            title: S.of(context).settingsLanguage,
            value: languageName,
            onTap: LanguageDialog.show,
          ),
          InfoItem(
            iconData: LucideIcons.home,
            title: S.of(context).settingsStartPage,
            value: startPage,
            onTap: StartPageDialog.show,
          ),
          InfoItem(
            iconData: LucideIcons.pin,
            title: S.of(context).settingsClearPinCache,
            value: '',
            onTap: () => ClearPinCacheDialog.show(),
          ),
          if (widget.showNfcSound) ...{
            InfoItem(
              iconData: LucideIcons.bellRing,
              title: S.of(context).nfcSound,
              value: '',
              onTap: () => NfcSoundDialog.show(),
            ),
          },
          InfoItem(
            iconData: LucideIcons.fileText,
            title: S.of(context).logsTitle,
            value: '',
            onTap: () => Get.toNamed('/logs'),
          ),
          InfoItem(
            iconData: LucideIcons.info,
            title: S.of(context).about,
            value: '',
            onTap: () => showAboutDialog(
              context: context,
              barrierDismissible: false,
              applicationName: S.of(context).homeScreenTitle,
              applicationVersion:
                  '${_packageInfo.version} / build ${_packageInfo.buildNumber}'
                      .trim(),
              applicationIcon: Image.asset(
                'assets/images/logo/logo_icon_dark.png',
                width: 75,
                height: 75,
              ),
              applicationLegalese: '© 2026 canokeys.org',
              children: [
                Padding(
                  padding: Spacing.y(8),
                  child: CustomizedText.bodyMedium(
                    S.of(context).appDescription,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: S.of(context).beforeSourceLink),
                      TextSpan(
                        text: 'canokeys/canokey-console',
                        style: TextStyle(
                          color: contentTheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            const repoUrl =
                                'https://github.com/canokeys/canokey-console';
                            await _launchUrl(Uri.parse(repoUrl));
                          },
                      ),
                    ],
                    style: CustomizedTextStyle.bodyMedium(),
                  ),
                ),
                if (isIOSApp() || isAndroidApp()) ...[
                  Spacing.height(12),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: S.of(context).privacyPolicy,
                          style: TextStyle(
                            color: contentTheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () =>
                                _launchUrl(Uri.parse(privacyPolicyUrl)),
                        ),
                      ],
                      style: CustomizedTextStyle.bodyMedium(),
                    ),
                  ),
                ],
                Spacing.height(12),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: '${S.of(context).feedback}: '),
                      TextSpan(
                        text: feedbackEmail,
                        style: TextStyle(
                          color: contentTheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _launchUrl(
                            Uri(scheme: 'mailto', path: feedbackEmail),
                          ),
                      ),
                    ],
                    style: CustomizedTextStyle.bodyMedium(),
                  ),
                ),
                if (widget.showNfcSound) ...[
                  Spacing.height(12),
                  CustomizedText.bodySmall(S.of(context).soundCredit),
                ],
                if (icpFiling != null) ...[
                  Spacing.height(12),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: icpFiling,
                          style: TextStyle(
                            color: contentTheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              await _launchUrl(Uri.parse(icpFilingUrl));
                            },
                        ),
                      ],
                      style: CustomizedTextStyle.bodyMedium(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
