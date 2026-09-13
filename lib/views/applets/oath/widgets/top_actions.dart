import 'package:canokey_console/controller/applets/oath/oath_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/input_pin_dialog.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:flutter/material.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:platform_detector/platform_detector.dart';

class TopActions extends StatelessWidget with UIMixin {
  static const double _actionWidth = 32;

  final OathController controller;
  final Widget? leading;
  final bool showAdd;
  final VoidCallback onQrScan;
  final VoidCallback onScreenCapture;
  final VoidCallback onManualAdd;

  const TopActions({
    super.key,
    required this.controller,
    this.leading,
    this.showAdd = true,
    required this.onQrScan,
    required this.onScreenCapture,
    required this.onManualAdd,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [?leading];

    if (controller.polled) {
      widgets.addAll([
        if (showAdd)
          OathAddAccountButton(
            onQrScan: onQrScan,
            onScreenCapture: onScreenCapture,
            onManualAdd: onManualAdd,
          ),
        if (controller.version != OathVersion.legacy) ...{
          IconButton(
            onPressed: () {
              InputPinDialog.show(
                title: S.of(context).oathSetCode,
                label: S.of(context).oathCode,
                prompt: S.of(context).oathNewCodePrompt,
                required: false,
                showSaveOption: true,
                onSubmit: (code, saveCode) async {
                  await controller.setCode(code, saveCode);
                },
              );
            },
            icon: Icon(LucideIcons.lock, color: topBarTheme.onBackground),
          ),
        },
      ]);
    }

    if (isWeb() || isIOSApp()) {
      widgets.add(
        IconButton(
          onPressed: controller.refreshData,
          icon: Icon(LucideIcons.refreshCw, color: topBarTheme.onBackground),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final widget in widgets)
          SizedBox(width: _actionWidth, height: 40, child: widget),
      ],
    );
  }
}

class OathAddAccountButton extends StatelessWidget with UIMixin {
  const OathAddAccountButton({
    super.key,
    required this.onQrScan,
    required this.onScreenCapture,
    required this.onManualAdd,
    this.prominent = false,
  });
  final VoidCallback onQrScan, onScreenCapture, onManualAdd;
  final bool prominent;
  @override
  Widget build(BuildContext context) => PopupMenuButton(
    offset: const Offset(0, 10),
    position: PopupMenuPosition.under,
    icon: prominent
        ? null
        : Icon(LucideIcons.plus, color: topBarTheme.onBackground),
    tooltip: S.of(context).oathAddAccount,
    child: prominent
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xff009b83),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.plus, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Flexible(
                  child: CustomizedText.bodyMedium(
                    S.of(context).oathAddAccount,
                    color: Colors.white,
                    fontWeight: 600,
                  ),
                ),
              ],
            ),
          )
        : null,
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
  );
}
