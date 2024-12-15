import 'package:canokey_console/controller/applets/oath/oath_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:platform_detector/platform_detector.dart';

class TopActions extends StatelessWidget with UIMixin {
  final OathController controller;
  final VoidCallback onQrScan;
  final VoidCallback onScreenCapture;
  final VoidCallback onManualAdd;

  TopActions({super.key, required this.controller, required this.onQrScan, required this.onScreenCapture, required this.onManualAdd});

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [
      InkWell(
        onTap: controller.refreshData,
        child: Icon(LucideIcons.refreshCw, size: 20, color: topBarTheme.onBackground),
      )
    ];

    if (controller.polled) {
      widgets.insertAll(0, [
        PopupMenuButton(
          offset: const Offset(0, 10),
          position: PopupMenuPosition.under,
          itemBuilder: (BuildContext context) => [
            if (!isDesktop()) // Use camera to scan the QR code
              PopupMenuItem(
                padding: Spacing.xy(16, 8),
                height: 10,
                onTap: onQrScan,
                child: CustomizedText.bodySmall(S.of(context).oathAddByScanning),
              ),
            if (isWeb() || isDesktop()) // Use screen to capture the QR code
              PopupMenuItem(
                padding: Spacing.xy(16, 8),
                height: 10,
                onTap: onScreenCapture,
                child: CustomizedText.bodySmall(S.of(context).oathAddByScreen),
              ),
            // Add manually
            PopupMenuItem(
              padding: Spacing.xy(16, 8),
              height: 10,
              onTap: onManualAdd,
              child: CustomizedText.bodySmall(S.of(context).oathAddManually),
            ),
          ],
          child: const Icon(LucideIcons.plus, size: 20),
        ),
        Spacing.width(12),
        if (controller.version != OathVersion.legacy) ...{
          InkWell(
            onTap: () {
              Prompts.showInputPinDialog(
                title: S.of(context).oathSetCode,
                label: S.of(context).oathCode,
                prompt: S.of(context).oathNewCodePrompt,
                required: false,
              ).then((value) => controller.setCode(value)).onError((error, stackTrace) => null); // Canceled
            },
            child: Icon(LucideIcons.lock, size: 20, color: topBarTheme.onBackground),
          ),
          Spacing.width(12),
        }
      ]);
    }

    return Row(children: widgets);
  }
}
