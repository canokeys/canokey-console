import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:ccid/ccid.dart' if (dart.library.html) 'package:canokey_console/helper/ccid_dummy.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:get/get.dart';
import 'package:platform_detector/platform_detector.dart';

class SmartCard {
  static Timer? _timer;
  static String? _lastConnectedName;
  static CcidCard? _card;
  static bool _polled = false;
  static String currentId = '';

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

  static bool useNfc() {
    if (isWeb()) {
      return true;
    }
    if (isDesktop()) {
      return false;
    }
    return _card == null;
  }

  static Future<void> eject() async {
    if (isIOSApp() && !useNfc()) {
      var deviceInfo = DeviceInfoPlugin();
      var iosInfo = await deviceInfo.iosInfo;
      if (iosInfo.model.toLowerCase().contains("iphone")) {
        await _card?.transceive("FFEEFFEE");
      }
    }
  }

  static Future<void> process(Function f) async {
    if (useNfc()) {
      bool isFirstCalled = !_polled;
      _polled = true;

      try {
        Prompts.promptPolling();
        if (isFirstCalled) {
          final tag = await FlutterNfcKit.poll(iosAlertMessage: S.of(Get.context!).iosAlertMessage);
          currentId = tag.id;
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
          currentId = '';
        }
      }
    } else {
      await f();
    }
  }

  static Future<String> transceive(String capdu) async {
    if (useNfc()) {
      return await FlutterNfcKit.transceive(capdu);
    } else {
      if (_card == null) {
        Prompts.showPrompt(S.of(Get.context!).noCard, ContentThemeColor.danger);
        throw Exception('Card is not connected');
      }
      final rapdu = await _card!.transceive(capdu);
      if (rapdu == null) {
        throw Exception('Transceive failed');
      }
      return rapdu;
    }
  }

  static void pollCcid() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      List<String> readers = await Ccid().listReaders();
      final name = readers.firstWhereOrNull((name) => name.toLowerCase().contains("canokey"));
      if (name != null) {
        if (_lastConnectedName != name) {
          _timer?.cancel();
          _card = await Ccid().connect(name);
          _lastConnectedName = name;
          pollCcid();
        }
      } else {
        _card = null;
        _lastConnectedName = null;
      }
    });
  }
}
