import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/localization/language.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/utils/sentry_setup.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
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
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.of(context).privacyConsentTitle),
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
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          if (await canLaunchUrlString(privacyPolicyUrl)) {
                            await launchUrlString(privacyPolicyUrl,
                                mode: LaunchMode.externalApplication);
                          }
                        }),
                  TextSpan(text: S.of(context).privacyConsentAfterLink),
                ],
                style: CustomizedTextStyle.bodyMedium(),
              )),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomizedButton.rounded(
                    onPressed: () => SystemNavigator.pop(),
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.secondary,
                    child: CustomizedText.labelMedium(
                        S.of(context).disagreeAndExit,
                        color: contentTheme.onSecondary),
                  ),
                  Spacing.width(16),
                  CustomizedButton.rounded(
                    onPressed: () async {
                      await LocalStorage.setPrivacyAgreed(true);
                      await initSentry();
                      if (context.mounted) Navigator.pop(context);
                    },
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium(
                        S.of(context).agreeAndContinue,
                        color: contentTheme.onPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
