import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:get/get.dart';

class Apdu {
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
    try {
      await FlutterNfcKit.poll();
      await f();
    } on PlatformException catch (e) {
      if (e.message == 'NotFoundError: No device selected.') {
        Prompts.showSnackbar(S.of(Get.context!).pollCanceled, ContentThemeColor.danger);
      } else if (e.message == 'NetworkError: A transfer error has occurred.') {
        Prompts.showSnackbar(S.of(Get.context!).networkError, ContentThemeColor.danger);
      } else {
        Prompts.showSnackbar(e.message ?? 'Unknown error', ContentThemeColor.danger);
      }
    } finally {
      FlutterNfcKit.finish(closeWebUSB: false);
    }
  }
}
