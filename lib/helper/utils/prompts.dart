import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';

class Prompts {
  static SnackbarController? _pollingSnackbarController;
  static OverlayEntry? _resultEntry;
  static OverlayState? _resultOverlay;

  static Future<void> copyText(String value) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      showPrompt(S.current.copied, ContentThemeColor.success);
    } catch (_) {
      showPrompt(S.current.operationFailed, ContentThemeColor.danger);
    }
  }

  static String getPinFailureResult(String resp) {
    resp = resp.toUpperCase();
    if (resp == '6983') {
      return S.of(Get.context!).appletLocked;
    } else if (resp == '6982') {
      return S.of(Get.context!).pinIncorrect;
    } else if (resp.toUpperCase().startsWith('63C')) {
      String retries = resp[resp.length - 1];
      return S.of(Get.context!).pinRetries(retries);
    } else if (resp == '6700') {
      return S.of(Get.context!).pinLength;
    } else if (isStorageFull(resp)) {
      return S.of(Get.context!).storageFull;
    } else {
      return S.current.operationFailed;
    }
  }

  static void promptPinFailureResult(String resp) =>
      showPrompt(getPinFailureResult(resp), ContentThemeColor.danger);

  static bool isStorageFull(String resp) {
    final sw = resp.toUpperCase();
    return sw == '6A84' || sw == '6581';
  }

  static void showPrompt(
    String content,
    ContentThemeColor selectedColor, {
    String level = 'E',
    bool forceSnackBar = false,
  }) {
    final success = selectedColor == ContentThemeColor.success;
    final warning = selectedColor == ContentThemeColor.warning;
    final failure = selectedColor == ContentThemeColor.danger;
    final color = selectedColor.onColor;
    // Use the navigator overlay on every platform so results remain visible
    // above modal barriers. Validation errors stay next to their form fields.
    dismissTransientPrompt();
    final overlay = Get.key.currentState!.overlay!;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ResultNotice(
        message: content,
        color: selectedColor.color,
        foreground: color,
        icon: success
            ? Icons.check_circle_outline
            : failure
            ? Icons.error_outline
            : warning
            ? Icons.warning_amber_rounded
            : Icons.info_outline,
        duration: Duration(seconds: success ? 3 : 6),
        onClose: () {
          if (identical(_resultEntry, entry)) dismissTransientPrompt();
        },
      ),
    );
    _resultEntry = entry;
    _resultOverlay = overlay;
    overlay.insert(entry);
  }

  static void dismissTransientPrompt() {
    if (_resultOverlay?.mounted == true) {
      _resultEntry?.remove();
      _resultEntry?.dispose();
    }
    _resultEntry = null;
    _resultOverlay = null;
    if (Get.isRegistered<RxString>(tag: 'dialog_error')) {
      Get.find<RxString>(tag: 'dialog_error').value = '';
    }
  }

  static void promptAndroidPolling() {
    dismissTransientPrompt();
    try {
      Get.find<RxBool>(tag: 'dialog_polling').value = true;
    } catch (e) {
      _pollingSnackbarController?.close();
      _pollingSnackbarController = Get.snackbar(
        S.of(Get.context!).androidAlertTitle,
        S.of(Get.context!).readingAlertMessage,
        icon: SpinKitRipple(color: Colors.tealAccent, size: 32.0),
        duration: const Duration(seconds: 99),
        backgroundColor: Colors.grey.withValues(alpha: 0.2),
        snackPosition: SnackPosition.BOTTOM,
        maxWidth: 400,
      );
    }
  }

  static void stopPromptAndroidPolling() {
    try {
      Get.find<RxBool>(tag: 'dialog_polling').value = false;
    } catch (e) {
      // ignore: empty_catches
    }
    try {
      _pollingSnackbarController?.close();
      _pollingSnackbarController = null;
    } catch (e) {
      // ignore: empty_catches
    }
  }
}

class UserCanceledError {}

/// The timer belongs to the overlay widget, so app/route teardown cancels it.
class _ResultNotice extends StatefulWidget {
  final String message;
  final Color color, foreground;
  final IconData icon;
  final Duration duration;
  final VoidCallback onClose;
  const _ResultNotice({
    required this.message,
    required this.color,
    required this.foreground,
    required this.icon,
    required this.duration,
    required this.onClose,
  });
  @override
  State<_ResultNotice> createState() => _ResultNoticeState();
}

class _ResultNoticeState extends State<_ResultNotice> {
  late final Timer timer;
  @override
  void initState() {
    super.initState();
    timer = Timer(widget.duration, widget.onClose);
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned(
    left: 16,
    right: 16,
    bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
    child: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Semantics(
            liveRegion: true,
            child: Material(
              color: widget.color,
              elevation: 8,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                child: Row(
                  children: [
                    Icon(widget.icon, color: widget.foreground),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                              ((MediaQuery.sizeOf(context).height -
                                          MediaQuery.viewInsetsOf(
                                            context,
                                          ).bottom) *
                                      .4)
                                  .clamp(48.0, 240.0),
                        ),
                        child: SingleChildScrollView(
                          child: CustomizedText.bodyMedium(
                            widget.message,
                            color: widget.foreground,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: widget.onClose,
                      icon: Icon(Icons.close, color: widget.foreground),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
