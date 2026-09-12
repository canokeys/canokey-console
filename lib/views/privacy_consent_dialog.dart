import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/localization/language.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_text_style.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:platform_detector/platform_detector.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// OPPO compliance: the privacy consent dialog only applies to Chinese
/// users on iOS and Android; other platforms never require it.
bool requiresPrivacyConsent() {
  if (!isAndroidApp() && !isIOSApp()) return false;
  return Language.getCurrentLanguage().locale.languageCode == 'zh' &&
      !LocalStorage.isPrivacyAgreed();
}

class PrivacyConsentDialog extends StatelessWidget with UIMixin {
  static const String privacyPolicyUrl = 'https://canokeys.com/privacy/';

  const PrivacyConsentDialog({super.key});

  static Future<void> showIfNeeded() {
    if (!requiresPrivacyConsent()) {
      return Future.value();
    }
    return AppDialog.show(const PrivacyConsentDialog());
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogSurface(
      child: SizedBox(
        width: AppDialogWidth.compact,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppDialogHeader(
              title: S.of(context).privacyConsentTitle,
              showClose: false,
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: S.of(context).privacyConsentBeforeLink),
                    TextSpan(
                      text: S.of(context).privacyPolicy,
                      style: TextStyle(
                        color: contentTheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          if (await canLaunchUrlString(privacyPolicyUrl)) {
                            await launchUrlString(
                              privacyPolicyUrl,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                    ),
                    TextSpan(text: S.of(context).privacyConsentAfterLink),
                  ],
                  style: CustomizedTextStyle.bodyMedium(),
                ),
              ),
            ),
            Divider(height: 0, thickness: 1),
            AppDialogActions(
              children: [
                AppDialogAction(
                  label: S.of(context).disagreeAndExit,
                  onPressed: () => SystemNavigator.pop(),
                  secondary: true,
                  destructive: false,
                ),
                AppDialogAction(
                  label: S.of(context).agreeAndContinue,
                  onPressed: () async {
                    await LocalStorage.setPrivacyAgreed(true);
                    if (context.mounted) Navigator.pop(context);
                  },
                  secondary: false,
                  destructive: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
