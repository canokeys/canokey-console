import 'dart:async';

import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';

abstract class BaseDialog extends StatefulWidget {
  const BaseDialog({super.key});

  bool get managesOwnScrolling => false;

  double get contentWidth => AppDialogWidth.compact;
}

abstract class BaseDialogState<T extends BaseDialog> extends State<T> {
  static final List<BaseDialogState> _dialogs = [];

  final RxBool _showPolling = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString errorLevel = 'E'.obs;

  @override
  void initState() {
    super.initState();
    _dialogs.add(this);
    _bindActiveDialog();
  }

  @override
  void dispose() {
    _dialogs.remove(this);
    _bindActiveDialog();
    super.dispose();
  }

  static void _bindActiveDialog() {
    Get.delete<RxBool>(tag: 'dialog_polling');
    Get.delete<RxString>(tag: 'dialog_error');
    Get.delete<RxString>(tag: 'dialog_error_level');
    if (_dialogs.isEmpty) return;
    final active = _dialogs.last;
    Get.put(active._showPolling, tag: 'dialog_polling');
    Get.put(active.errorMessage, tag: 'dialog_error');
    Get.put(active.errorLevel, tag: 'dialog_error_level');
  }

  Widget buildDialogContent();

  /// Standard form layout. Call inside Obx so dialog errors remain reactive.
  Widget buildFormContent({
    required String title,
    required Widget description,
    required Widget form,
    required FutureOr<void> Function()? onSubmit,
  }) => AppDialogColumn(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppDialogHeader(title: title),
      const Divider(height: 0, thickness: 1),
      Padding(padding: Spacing.all(24), child: description),
      const Divider(height: 0, thickness: 1),
      Padding(padding: Spacing.all(24), child: form),
      if (errorMessage.value.isNotEmpty)
        Padding(
          padding: Spacing.all(24),
          child: CustomizedText.bodyMedium(
            errorMessage.value,
            color: errorLevel.value == 'E'
                ? ContentThemeColor.danger.color
                : ContentThemeColor.warning.color,
          ),
        ),
      const Divider(height: 0, thickness: 1),
      AppDialogActions(
        children: [
          AppDialogAction(
            label: S.of(context).cancel,
            secondary: true,
            onPressed: () => Navigator.pop(context),
          ),
          AppDialogAction(label: S.of(context).save, onPressed: onSubmit),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final content = buildDialogContent();
    return AppDialogSurface(
      child: SizedBox(
        width: widget.contentWidth,
        child: Stack(
          children: [
            if (widget.managesOwnScrolling)
              content
            else
              SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: content,
              ),
            Positioned.fill(
              child: Obx(
                () => !_showPolling.value
                    ? Container()
                    : GestureDetector(
                        onTap: () {},
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.8),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SpinKitRipple(
                                  color: Colors.tealAccent,
                                  size: 64.0,
                                ),
                                Spacing.height(16),
                                CustomizedText.bodyLarge(
                                  S.of(Get.context!).readingAlertMessage,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
