import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:ccid/ccid.dart' if (dart.library.html) 'package:canokey_console/helper/ccid_dummy.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:platform_detector/platform_detector.dart';

final log = Logger('SmartCard');

class SmartCard {
  static String _currentSN = '';

  static CcidCard? _card;

  static bool isWebUSBConnected = false;

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
    bool nfcMode = _card == null;
    if (isWeb()) {
      nfcMode = false;
    }
    return nfcMode;
  }

  static bool isUsbConnected() {
    return _card != null;
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

  /// Process a smart card transaction.
  ///
  /// When this method is called, if a CanoKey is connected using USB,
  /// we can directly send the APDU command to the card, and we do nothing.
  /// If there is no CanoKey connected via USB, then we need to use
  /// FlutterNfcKit to communicate with the card.
  ///
  /// WebUSB and NFC require polling before communicating with the card.
  /// For Android, we need a customized prompt to indicate to the user
  /// that the card is being read. After polling, we maintain the SN.
  static Future<void> process(Function(String sn) f) async {
    if (isUsbConnected()) {
      await f(_currentSN);
    } else {
      try {
        Prompts.promptPolling();
        await FlutterNfcKit.poll(iosAlertMessage: S.of(Get.context!).iosAlertMessage);
        assertOK(await FlutterNfcKit.transceive('00A4040005F000000000'));
        final resp = await SmartCard.transceive('0032000000');
        SmartCard.assertOK(resp);
        final sn = SmartCard.dropSW(resp).toUpperCase();
        _currentSN = sn;
        if (isWeb()) {
          isWebUSBConnected = true;
          log.info('CanoKey (WebUSB) Polled. SN: $sn');
        } else {
          log.info('CanoKey (NFC) Polled. SN: $sn');
        }
        await f(sn);
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
        FlutterNfcKit.finish(closeWebUSB: false);
      }
    }
  }

  static Future<String> transceive(String capdu) async {
    if (useNfc() || isWeb()) {
      return await FlutterNfcKit.transceive(capdu);
    } else {
      if (_card == null) {
        Prompts.showPrompt(S.of(Get.context!).noCard, ContentThemeColor.danger);
        throw Exception('Card is not connected');
      }
      log.config('C-APDU: $capdu');
      final rapdu = await _card!.transceive(capdu);
      if (rapdu == null) {
        throw Exception('Transceive failed');
      }
      log.config('R-APDU: $rapdu');
      return rapdu;
    }
  }

  static void onWebUSBDisconnected() {
    log.info('CanoKey (WebUSB) removed: $_currentSN');
    isWebUSBConnected = false;
    _currentSN = '';
  }

  static void pollCcid() {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      List<String> readers = await Ccid().listReaders();
      final name = readers.firstWhereOrNull((name) => name.toLowerCase().contains("canokey"));
      if (name != null) {
        if (_card == null) {
          log.info('New CanoKey (USB) detected: $name');
          try {
            _card = await Ccid().connect(name);
            var resp = await _card!.transceive('00A4040005F000000000');
            assertOK(resp!);
            resp = await _card!.transceive('0032000000');
            assertOK(resp!);
            _currentSN = SmartCard.dropSW(resp).toUpperCase();
            log.info('Successfully connected to CanoKey (USB). SN: $_currentSN');
          } catch (e) {
            log.severe('Failed to connect to CanoKey (USB): $e');
            _card = null;
            _currentSN = '';
          }
        }
      } else if (_currentSN != '') {
        log.info('CanoKey (USB) removed: $_currentSN');
        _card = null;
        _currentSN = '';
      }
    });
  }
}
