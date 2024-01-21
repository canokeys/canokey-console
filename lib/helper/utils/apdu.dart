import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:get/get.dart';

class Apdu {
  static bool _polled = false;

  static String dropSW(String rapdu) {
    return rapdu.substring(0, rapdu.length - 4);
  }

  static bool isOK(String rapdu) {
    return rapdu.endsWith('9000');
  }

  static void assertOK(String rapdu) {
    if (!isOK(rapdu)) {
      throw Exception('SW is not ok');
    }
  }

  static Future<void> process(Function f) async {
    bool isFirstCalled = !_polled;
    _polled = true;

    try {
      Prompts.promptPolling();
      if (isFirstCalled) {
        await FlutterNfcKit.poll(iosAlertMessage: S.of(Get.context!).iosAlertMessage);
      }
      await f();
    } on PlatformException catch (e) {
      if (e.message == 'NotFoundError: No device selected.') {
        Prompts.showPrompt(S.of(Get.context!).pollCanceled, ContentThemeColor.danger);
      } else if (e.message == 'NetworkError: A transfer error has occurred.') {
        Prompts.showPrompt(S.of(Get.context!).networkError, ContentThemeColor.danger);
      } else if (e.message == 'SessionCanceled') {
        Prompts.showPrompt(S.of(Get.context!).pollCanceled, ContentThemeColor.danger);
      } else {
        Prompts.showPrompt(e.message ?? 'Unknown error', ContentThemeColor.danger);
      }
    } finally {
      Prompts.stopPromptPolling();
      if (isFirstCalled) {
        FlutterNfcKit.finish(closeWebUSB: false);
        _polled = false;
      }
    }
  }
}
