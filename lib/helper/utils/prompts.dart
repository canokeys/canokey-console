import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:platform_detector/platform_detector.dart';

class Prompts {
  static late SnackbarController _snackbarController;

  static String getPinFailureResult(String resp) {
    if (resp == '6983') {
      return S.of(Get.context!).appletLocked;
    } else if (resp == '6982') {
      return S.of(Get.context!).pinIncorrect;
    } else if (resp.toUpperCase().startsWith('63C')) {
      String retries = resp[resp.length - 1];
      return S.of(Get.context!).pinRetries(retries);
    } else if (resp == '6700') {
      return S.of(Get.context!).pinLength;
    } else {
      return 'Unknown response';
    }
  }

  static void promptPinFailureResult(String resp) {
    if (resp == '6983') {
      showPrompt(S.of(Get.context!).appletLocked, ContentThemeColor.danger);
    } else if (resp == '6982') {
      showPrompt(S.of(Get.context!).pinIncorrect, ContentThemeColor.danger);
    } else if (resp.toUpperCase().startsWith('63C')) {
      String retries = resp[resp.length - 1];
      showPrompt(S.of(Get.context!).pinRetries(retries), ContentThemeColor.danger);
    } else if (resp == '6700') {
      showPrompt(S.of(Get.context!).pinLength, ContentThemeColor.danger);
    } else {
      showPrompt('Unknown response', ContentThemeColor.danger);
    }
  }

  static void showPrompt(String content, ContentThemeColor selectedColor, {String level = 'E', bool forceSnackBar = false}) {
    Color backgroundColor = selectedColor.color;
    Color color = selectedColor.onColor;

    if (isIOS()) {
      MaterialBanner banner = MaterialBanner(
        content: CustomizedText.labelMedium(content, color: color),
        padding: Spacing.x(24),
        backgroundColor: backgroundColor,
        overflowAlignment: OverflowBarAlignment.center,
        actions: [Spacing.empty()],
      );
      ScaffoldMessenger.of(Get.context!).hideCurrentMaterialBanner();
      ScaffoldMessenger.of(Get.context!).showMaterialBanner(banner);
      Timer(Duration(seconds: 3), () {
        ScaffoldMessenger.of(Get.context!).hideCurrentMaterialBanner();
      });
    } else {
      try {
        if (forceSnackBar) {
          throw Exception('expected');
        }
        Get.find<RxString>(tag: 'dialog_error').value = content;
        Get.find<RxString>(tag: 'dialog_error_level').value = level;
        Timer(Duration(seconds: 3), () {
          Get.find<RxString>(tag: 'dialog_error').value = '';
        });
      } catch (e) {
        // log.d('Failed to find a dialog', error: e);
        SnackBar snackBar = SnackBar(
          behavior: SnackBarBehavior.floating,
          width: 300,
          duration: Duration(seconds: 3),
          showCloseIcon: true,
          closeIconColor: color,
          content: CustomizedText.labelLarge(content, color: color),
          backgroundColor: backgroundColor,
        );
        ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
        ScaffoldMessenger.of(Get.context!).showSnackBar(snackBar);
      }
    }
  }

  static promptAndroidPolling() {
    try {
      Get.find<RxBool>(tag: 'dialog_polling').value = true;
    } catch (e) {
      _snackbarController = Get.snackbar(
        S.of(Get.context!).androidAlertTitle,
        S.of(Get.context!).readingAlertMessage,
        icon: SpinKitRipple(color: Colors.tealAccent, size: 32.0),
        duration: const Duration(seconds: 99),
        backgroundColor: Colors.grey.withOpacity(0.8),
        snackPosition: SnackPosition.BOTTOM,
        maxWidth: 400,
      );
    }
  }

  static stopPromptAndroidPolling() {
    try {
      Get.find<RxBool>(tag: 'dialog_polling').value = false;
    } catch (e) {
      // ignore: empty_catches
    }
    try {
      _snackbarController.close();
    } catch (e) {
      // ignore: empty_catches
    }
  }
}

class UserCanceledError {}
