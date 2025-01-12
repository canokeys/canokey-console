import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';
import 'package:canokey_console/helper/utils/shadow.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_card.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/views/applets/settings/dialogs/language_dialog.dart';
import 'package:canokey_console/views/applets/settings/dialogs/start_page_dialog.dart';
import 'package:canokey_console/views/applets/settings/dialogs/clear_pin_cache_dialog.dart';
import 'package:canokey_console/views/applets/settings/widgets/info_item.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class OtherSettingsCard extends StatefulWidget {
  const OtherSettingsCard({super.key});

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
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageName = ThemeCustomizer.instance.currentLanguage.languageName;
    final startPage = StartPageDialog.pageName(context, LocalStorage.getStartPage() ?? '/');

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
                InfoItem(iconData: LucideIcons.languages, title: S.of(context).settingsLanguage, value: languageName, onTap: LanguageDialog.show),
                Spacing.height(16),
                InfoItem(iconData: LucideIcons.home, title: S.of(context).settingsStartPage, value: startPage, onTap: StartPageDialog.show),
                Spacing.height(16),
                InfoItem(iconData: LucideIcons.pin, title: S.of(context).settingsClearPinCache, value: '', onTap: () => ClearPinCacheDialog.show()),
                Spacing.height(16),
                InfoItem(
                    iconData: LucideIcons.info,
                    title: S.of(context).about,
                    value: '',
                    onTap: () => showAboutDialog(
                          context: context,
                          applicationName: S.of(context).homeScreenTitle,
                          applicationVersion: '${_packageInfo.version} / build ${_packageInfo.buildNumber}'.trim(),
                          applicationIcon: Image.asset('assets/images/logo/logo_icon_dark.png', width: 75, height: 75),
                          applicationLegalese: '© 2025 canokeys.org',
                          children: [
                            Padding(
                              padding: Spacing.y(8),
                              child: CustomizedText.bodyMedium(S.of(context).appDescription),
                            ),
                            RichText(text: TextSpan(
                              children: [
                                TextSpan(text: S.of(context).beforeSourceLink, style: TextStyle()),
                                TextSpan(
                                  text: 'canokeys/canokey-console',
                                  style: TextStyle(color: contentTheme.primary, decoration: TextDecoration.underline),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      const repoUrl = 'https://github.com/canokeys/canokey-console';
                                      if (await canLaunchUrlString(repoUrl)) {
                                        await launchUrlString(repoUrl, mode: LaunchMode.externalApplication);
                                      }
                                    }
                                  ),
                              ]
                            )),
                            Spacing.height(12),
                            CustomizedText.bodySmall(S.of(context).soundCredit),
                          ],
                        ))
              ],
            ),
          ),
        ],
      ),
    );
  }
}
