import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StartPageDialog extends StatefulWidget {
  const StartPageDialog({super.key});

  static Future<void> show() {
    return AppDialog.show(const StartPageDialog());
  }

  static String pageName(BuildContext context, String path) {
    switch (path) {
      case '/':
        return S.of(context).home;
      case '/applets/oath':
        return 'OTP';
      case '/applets/piv':
        return 'PIV';
      case '/applets/openpgp':
        return 'OpenPGP';
      case '/applets/ndef':
        return 'NFC Tag';
      case '/applets/webauthn':
        return 'WebAuthn';
      case '/applets/pass':
        return 'Pass';
      default:
        return S.current.settingsKeyboardLayoutUnknown;
    }
  }

  @override
  State<StartPageDialog> createState() => _StartPageDialogState();
}

class _StartPageDialogState extends State<StartPageDialog> with UIMixin {
  late final startPage = (LocalStorage.getStartPage() ?? '/').obs;

  Widget _buildStartPageItem(
    BuildContext context,
    RxString startPage,
    String path,
  ) {
    return AppDialogChoice(
      title: StartPageDialog.pageName(context, path),
      selected: startPage.value == path,
      onTap: () => startPage.value = path,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogSurface(
      child: SizedBox(
        width: AppDialogWidth.compact,
        child: AppDialogColumn(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppDialogHeader(
              title: S.of(context).settingsStartPage,
              icon: Icons.home_outlined,
            ),
            Divider(height: 0, thickness: 1),
            Obx(
              () => Column(
                children: [
                  _buildStartPageItem(context, startPage, '/'),
                  _buildStartPageItem(context, startPage, '/applets/oath'),
                  _buildStartPageItem(context, startPage, '/applets/webauthn'),
                  _buildStartPageItem(context, startPage, '/applets/pass'),
                  _buildStartPageItem(context, startPage, '/applets/piv'),
                  _buildStartPageItem(context, startPage, '/applets/openpgp'),
                  _buildStartPageItem(context, startPage, '/applets/ndef'),
                ],
              ),
            ),
            Divider(height: 0, thickness: 1),
            AppDialogActions(
              children: [
                AppDialogAction(
                  label: S.of(context).cancel,
                  onPressed: () => Navigator.pop(context),
                  secondary: true,
                  destructive: false,
                ),
                AppDialogAction(
                  label: S.of(context).save,
                  onPressed: () async {
                    await LocalStorage.setStartPage(startPage.value);
                    Prompts.showPrompt(
                      S.current.successfullyChanged,
                      ContentThemeColor.success,
                    );
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
