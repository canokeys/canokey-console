import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResetDialog extends BaseDialog with UIMixin {
  final Applet? applet;
  final Function resetCanokey;
  final Function(Applet applet) resetApplet;

  const ResetDialog({
    super.key,
    this.applet,
    required this.resetCanokey,
    required this.resetApplet,
  });

  static Future<void> show({
    Applet? applet,
    required Function resetCanokey,
    required Function(Applet applet) resetApplet,
  }) {
    return AppDialog.show(
      ResetDialog(
        applet: applet,
        resetCanokey: resetCanokey,
        resetApplet: resetApplet,
      ),
    );
  }

  @override
  State<ResetDialog> createState() => _ResetDialogState();
}

class _ResetDialogState extends BaseDialogState<ResetDialog> with UIMixin {
  @override
  Widget buildDialogContent() {
    final title = widget.applet == null
        ? S.of(context).settingsResetAll
        : S.of(context).reset;
    final prompt = widget.applet == null
        ? S.of(context).settingsResetAllPrompt
        : S.of(context).settingsResetApplet(widget.applet!.name);

    return Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDialogHeader(title: title),
          Divider(height: 0, thickness: 1),
          Padding(
            padding: Spacing.all(16),
            child: CustomizedText.labelLarge(prompt),
          ),
          if (errorMessage.value.isNotEmpty)
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.bodyMedium(
                errorMessage.value,
                color: errorLevel.value == 'E'
                    ? ContentThemeColor.danger.color
                    : ContentThemeColor.warning.color,
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
                label: S.of(context).confirm,
                onPressed: () => widget.applet == null
                    ? widget.resetCanokey()
                    : widget.resetApplet(widget.applet!),
                secondary: false,
                destructive: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
