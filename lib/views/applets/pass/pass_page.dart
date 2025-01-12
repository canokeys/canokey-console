import 'package:canokey_console/controller/applets/pass/pass_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/poll_canokey_screen.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/views/applets/pass/widgets/slot_card.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:platform_detector/platform_detector.dart';

class PassPage extends StatefulWidget {
  const PassPage({super.key});

  @override
  State<PassPage> createState() => _PassPageState();
}

class _PassPageState extends State<PassPage> with UIMixin {
  final _controller = Get.put(PassController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      title: 'Pass',
      topActions: isWeb() || isIOSApp()
          ? InkWell(
              onTap: () => _controller.refreshData(),
              child: Icon(LucideIcons.refreshCw, size: 20, color: topBarTheme.onBackground),
            )
          : Container(),
      child: GetBuilder(
        init: _controller,
        builder: (_) {
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
                    SlotCard(title: S.of(context).passSlotShort, slot: _controller.slotShort, slotIndex: PassController.short, controller: _controller),
                    Spacing.height(20),
                    SlotCard(title: S.of(context).passSlotLong, slot: _controller.slotLong, slotIndex: PassController.long, controller: _controller),
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
