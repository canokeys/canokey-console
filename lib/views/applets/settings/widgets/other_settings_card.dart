import 'package:canokey_console/helper/widgets/applet_section_card.dart';
import 'package:canokey_console/views/applets/settings/widgets/settings_surface.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';
import 'package:canokey_console/helper/utils/build_info.dart';
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

  late final TapGestureRecognizer _repoRecognizer;
  late final TapGestureRecognizer _privacyPolicyRecognizer;
  late final TapGestureRecognizer _feedbackEmailRecognizer;
  late final TapGestureRecognizer _icpFilingRecognizer;
  late final TapGestureRecognizer _commitRecognizer;

  @override
  void initState() {
    super.initState();
    _repoRecognizer = TapGestureRecognizer()
      ..onTap = () => _launchUrl(
        Uri.parse('https://github.com/canokeys/canokey-console'),
      );
    _privacyPolicyRecognizer = TapGestureRecognizer()
      ..onTap = () => _launchUrl(Uri.parse(_privacyPolicyUrl));
    _feedbackEmailRecognizer = TapGestureRecognizer()
      ..onTap = () =>
          _launchUrl(Uri(scheme: 'mailto', path: _feedbackEmail));
    _icpFilingRecognizer = TapGestureRecognizer()
      ..onTap = () => _launchUrl(Uri.parse(icpFilingUrl));
    _commitRecognizer = TapGestureRecognizer()
      ..onTap = () => _launchUrl(Uri.parse(BuildInfo.commitUrl));
    _initPackageInfo();
  }

  @override
  void dispose() {
    _repoRecognizer.dispose();
    _commitRecognizer.dispose();
    _privacyPolicyRecognizer.dispose();
    _feedbackEmailRecognizer.dispose();
    _icpFilingRecognizer.dispose();
    super.dispose();
  }

  bool get _isChinese =>
      Localizations.localeOf(context).languageCode == 'zh';

  String get _privacyPolicyUrl => _isChinese
      ? 'https://www.canokeys.com/privacy/'
      : 'https://www.canokeys.org/privacy/';

  String get _feedbackEmail =>
      _isChinese ? 'support@canokeys.com' : 'support@canokeys.org';

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
                if (BuildInfo.commit.isNotEmpty) ...[
                  Padding(
                    padding: Spacing.y(8),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: '${S.of(context).buildCommit}  '),
                          TextSpan(
                            text: BuildInfo.shortCommit,
                            style: TextStyle(
                              color: contentTheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: _commitRecognizer,
                          ),
                        ],
                        style: CustomizedTextStyle.bodySmall(),
                      ),
                    ),
                  ),
                ],
                if (BuildInfo.localTime.isNotEmpty)
                  Padding(
                    padding: Spacing.y(8),
                    child: CustomizedText.bodySmall(
                      '${S.of(context).buildTime}  ${BuildInfo.localTime}',
                    ),
                  ),
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
                        recognizer: _repoRecognizer,
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
                          recognizer: _privacyPolicyRecognizer,
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
                        text: _feedbackEmail,
                        style: TextStyle(
                          color: contentTheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: _feedbackEmailRecognizer,
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
                          recognizer: _icpFilingRecognizer,
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
