import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/views/applets/settings/widgets/settings_surface.dart';
import 'package:canokey_console/controller/applets/settings/settings_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/localization/hints.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/views/applets/settings/widgets/action_card.dart';
import 'package:canokey_console/views/applets/settings/widgets/info_card.dart';
import 'package:canokey_console/views/applets/settings/widgets/other_settings_card.dart';
import 'package:canokey_console/views/applets/settings/widgets/settings_card.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:canokey_console/views/layout/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:platform_detector/platform_detector.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _controller = Get.put(SettingsController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      title: S.of(context).settings,
      onRefresh: _controller.refreshData,
      topActions: isWeb() || isIOSApp()
          ? TopBarRefreshButton(onPressed: _controller.refreshData)
          : null,
      child: GetBuilder(
        init: _controller,
        builder: (_) {
          final showNfcSound =
              isAndroidApp() &&
              (!_controller.polled ||
                  _controller.key.getFunctionSet().contains(Func.nfcSwitch));
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 960;
              final mainCards = <Widget>[
                if (_controller.polled) ...[
                  InfoCard(canokey: _controller.key),
                  const SizedBox(height: 16),
                  SettingsCard(controller: _controller),
                  const SizedBox(height: 16),
                ] else ...[
                  SettingsSection(
                    icon: LucideIcons.info,
                    title: S.of(context).settingsInfo,
                    child: CustomizedText.bodyMedium(Hints.pollCanoKeyPrompt),
                  ),
                  const SizedBox(height: 16),
                ],
                OtherSettingsCard(showNfcSound: showNfcSound),
              ];
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 24 : 16,
                  wide ? 0 : 16,
                  wide ? 24 : 16,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: SettingsStyle.accent.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            LucideIcons.settings,
                            size: 36,
                            color: SettingsStyle.accent,
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomizedText.headlineMedium(
                                S.of(context).settings,
                                fontWeight: 700,
                              ),
                              const SizedBox(height: 6),
                              CustomizedText.bodyMedium(
                                S.of(context).settingsDescription,
                                muted: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: mainCards,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: ActionCard(controller: _controller),
                          ),
                        ],
                      )
                    else ...[
                      ...mainCards,
                      const SizedBox(height: 16),
                      ActionCard(controller: _controller),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
