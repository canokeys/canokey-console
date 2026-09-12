import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/controller/applets/pass/pass_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/applet_disabled_screen.dart';
import 'package:canokey_console/helper/widgets/poll_canokey_screen.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/views/applets/pass/widgets/slot_card.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:canokey_console/views/layout/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:platform_detector/platform_detector.dart';

class PassPage extends StatefulWidget {
  const PassPage({super.key});

  @override
  State<PassPage> createState() => _PassPageState();
}

class _PassPageState extends State<PassPage> {
  final _controller = Get.put(PassController());

  @override
  Widget build(BuildContext context) {
    final mobile = ScreenMedia.getTypeFromWidth(
      MediaQuery.sizeOf(context).width,
    ).isMobile;
    return Layout(
      title: 'Pass',
      onRefresh: _controller.refreshData,
      topActions: isWeb() || isIOSApp()
          ? TopBarRefreshButton(onPressed: _controller.refreshData)
          : null,
      child: GetBuilder(
        init: _controller,
        builder: (_) {
          if (_controller.disabledMessage != null) {
            return AppletDisabledScreen(message: _controller.disabledMessage!);
          }
          if (!_controller.polled) {
            return PollCanoKeyScreen();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  flexSpacing,
                  ScreenMedia.getTypeFromWidth(
                        MediaQuery.sizeOf(context).width,
                      ).isMobile
                      ? 16
                      : 0,
                  flexSpacing,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!mobile) ...[
                      Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xff009b83,
                              ).withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              LucideIcons.keyboard,
                              size: 36,
                              color: Color(0xff009b83),
                            ),
                          ),
                          const SizedBox(width: 22),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomizedText.headlineMedium(
                                  'Pass',
                                  fontWeight: 700,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                const SizedBox(height: 6),
                                CustomizedText.bodyMedium(
                                  S.of(context).passDescription,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                    ],
                    SlotCard(
                      title: S.of(context).passSlotShort,
                      slot: _controller.slotShort,
                      slotIndex: PassController.short,
                      controller: _controller,
                    ),
                    Spacing.height(20),
                    SlotCard(
                      title: S.of(context).passSlotLong,
                      slot: _controller.slotLong,
                      slotIndex: PassController.long,
                      controller: _controller,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
