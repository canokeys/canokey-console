import 'package:canokey_console/controller/applets/settings/settings_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/localization/hints.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/views/applets/settings/widgets/action_card.dart';
import 'package:canokey_console/views/applets/settings/widgets/info_card.dart';
import 'package:canokey_console/views/applets/settings/widgets/other_settings_card.dart';
import 'package:canokey_console/views/applets/settings/widgets/settings_card.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:platform_detector/platform_detector.dart';

final log = Logger('Console:Settings:View');

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin, UIMixin {
  final _controller = Get.put(SettingsController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      title: S.of(context).settings,
      topActions: isWeb() || isIOSApp()
          ? InkWell(
              onTap: () => _controller.refreshData(),
              child: Icon(LucideIcons.refreshCw, size: 20, color: topBarTheme.onBackground),
            )
          : Container(),
      child: GetBuilder(
        init: _controller,
        builder: (_) {
          List<Widget> widgets = [
            Spacing.height(20),
            ActionCard(controller: _controller),
            Spacing.height(20),
            OtherSettingsCard(),
            Spacing.height(20),
          ];

          if (!_controller.polled) {
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
                          child: CustomizedText.bodyMedium(Hints.pollCanoKeyPrompt, fontSize: 14),
                        ),
                      ),
                      ...widgets
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: Spacing.x(flexSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Spacing.height(20),
                      InfoCard(canokey: _controller.key),
                      Spacing.height(20),
                      SettingsCard(controller: _controller),
                      ...widgets,
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
