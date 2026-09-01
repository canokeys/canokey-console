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
                padding: Spacing.x(flexSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Spacing.height(20),
                    SlotCard(
                        title: S.of(context).passSlotShort,
                        slot: _controller.slotShort,
                        slotIndex: PassController.short,
                        controller: _controller),
                    Spacing.height(20),
                    SlotCard(
                        title: S.of(context).passSlotLong,
                        slot: _controller.slotLong,
                        slotIndex: PassController.long,
                        controller: _controller),
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
