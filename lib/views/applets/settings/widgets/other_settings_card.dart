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
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OtherSettingsCard extends StatelessWidget with UIMixin {
  const OtherSettingsCard({super.key});

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
            color: contentTheme.primary.withValues(alpha: 0.08),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
