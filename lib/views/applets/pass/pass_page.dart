import 'package:canokey_console/controller/applets/pass.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/views/applets/pass/widgets/slot_card.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:lucide_icons/lucide_icons.dart';

final log = Logger('Console:Pass:View');

class PassPage extends StatefulWidget {
  const PassPage({super.key});

  @override
  State<PassPage> createState() => _PassPageState();
}

class _PassPageState extends State<PassPage> with UIMixin {
  late PassController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(PassController());
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      title: 'Pass',
      topActions: InkWell(
        onTap: () {
          if (controller.polled) {
            controller.refreshData(controller.pinCache);
          } else {
            Prompts.showInputPinDialog(
              title: S.of(context).settingsInputPin,
              label: 'PIN',
              prompt: S.of(context).passInputPinPrompt,
            ).then((value) {
              controller.refreshData(value);
            }).onError((error, stackTrace) => null); // User canceled
          }
        },
        child: Icon(LucideIcons.refreshCw, size: 20, color: topBarTheme.onBackground),
      ),
      child: GetBuilder(
        init: controller,
        builder: (_) {
          if (!controller.polled) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Spacing.height(MediaQuery.of(context).size.height / 2 - 120),
                Center(
                    child: Padding(
                  padding: Spacing.horizontal(36),
                  child: CustomizedText.bodyMedium(S.of(context).pollCanoKey, fontSize: 24),
                )),
              ],
            );
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
                    SlotCard(title: S.of(context).passSlotShort, slot: controller.slotShort, slotIndex: PassController.short, controller: controller),
                    Spacing.height(20),
                    SlotCard(title: S.of(context).passSlotLong, slot: controller.slotLong, slotIndex: PassController.long, controller: controller),
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
