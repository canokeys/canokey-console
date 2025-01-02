import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:ccid/ccid.dart' if (dart.library.html) 'package:canokey_console/helper/ccid_dummy.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:platform_detector/platform_detector.dart';

final log = Logger('SmartCard');

enum ConnectionType { none, ccid, nfc, webusb }

class SmartCard {
  static String _currentSN = '';

  static CcidCard? _ccidCard;

  static ConnectionType connectionType = ConnectionType.none;

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

  static Future<void> eject() async {
    if (isIOSApp() && connectionType == ConnectionType.ccid) {
      await _ccidCard?.transceive("FFEEFFEE");
    }
  }

  static Future<void> process(Function(String sn) f, {bool waitForAndroidTap = true}) async {
    if (connectionType == ConnectionType.ccid) {
      await f(_currentSN);
    } else {
      try {
        if (isAndroidApp()) {
          if (waitForAndroidTap) {
            Prompts.promptAndroidPolling();
            if (!await _pollAndroidNFC()) {
              Prompts.stopPromptAndroidPolling();
              Prompts.showPrompt(S.of(Get.context!).pollCanceled, ContentThemeColor.danger);
              return;
            }
          }
        } else {
          await FlutterNfcKit.poll(iosAlertMessage: S.of(Get.context!).iosAlertMessage);
        }
        assertOK(await FlutterNfcKit.transceive('00A4040005F000000000'));
        final resp = await SmartCard.transceive('0032000000');
        SmartCard.assertOK(resp);
        final sn = SmartCard.dropSW(resp).toUpperCase();
        _currentSN = sn;
        if (isWeb()) {
          connectionType = ConnectionType.webusb;
          log.info('CanoKey (WebUSB) Polled. SN: $sn. Connection Type updated to WebUSB.');
        } else {
          connectionType = ConnectionType.nfc;
          log.info('CanoKey (NFC) Polled. SN: $sn. Connection Type updated to NFC.');
        }
        await f(sn);
      } on PlatformException catch (e) {
        if (e.message?.contains('SecurityError') == true) {
          rethrow;
        }
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
        if (isAndroidApp()) {
          if (waitForAndroidTap) {
            Prompts.stopPromptAndroidPolling();
          }
        } else {
          FlutterNfcKit.finish(closeWebUSB: false);
        }
        if (!isWeb()) {
          log.info('CanoKey (NFC) removed: $_currentSN. Connection Type updated to None.');
          _currentSN = '';
          connectionType = ConnectionType.none;
        }
      }
    }
  }

  static Future<String> transceive(String capdu) async {
    if (connectionType != ConnectionType.ccid) {
      return await FlutterNfcKit.transceive(capdu);
    } else {
      if (_ccidCard == null) {
        Prompts.showPrompt(S.of(Get.context!).noCard, ContentThemeColor.danger);
        throw Exception('Card is not connected');
      }
      log.config('C-APDU: $capdu');
      final rapdu = await _ccidCard!.transceive(capdu);
      if (rapdu == null) {
        throw Exception('Transceive failed');
      }
      log.config('R-APDU: $rapdu');
      return rapdu;
    }
  }

  static void pollCcid() {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      List<String> readers = await Ccid().listReaders();
      final name = readers.firstWhereOrNull((name) => name.toLowerCase().contains("canokey"));
      if (name != null) {
        if (_ccidCard == null) {
          log.info('New CanoKey (USB) detected: $name');
          try {
            _ccidCard = await Ccid().connect(name);
            var resp = await _ccidCard!.transceive('00A4040005F000000000');
            assertOK(resp!);
            resp = await _ccidCard!.transceive('0032000000');
            assertOK(resp!);
            _currentSN = SmartCard.dropSW(resp).toUpperCase();
            connectionType = ConnectionType.ccid;
            log.info('Successfully connected to CanoKey (USB). SN: $_currentSN. Connection Type updated to CCID.');
          } catch (e) {
            log.severe('Failed to connect to CanoKey (USB): $e');
            _ccidCard = null;
            _currentSN = '';
          }
        }
      } else if (connectionType == ConnectionType.ccid && _currentSN != '') {
        log.info('CanoKey (USB) removed: $_currentSN. Connection Type updated to None.');
        _ccidCard = null;
        _currentSN = '';
        connectionType = ConnectionType.none;
      }
    });
  }

  static void onWebUSBDisconnected() {
    _currentSN = '';
    connectionType = ConnectionType.none;
    log.info('CanoKey (WebUSB) removed: $_currentSN. Connection Type updated to None.');
  }

  static Future<bool> _pollAndroidNFC() async {
    final completer = Completer<bool>();
    StreamSubscription? listener;

    log.info('Android NFC tag polling started');
    listener = FlutterNfcKit.tagStream.listen((tag) {
      log.info('Android NFC tag polled: ${tag.id}');
      listener?.cancel();
      completer.complete(true);
    });

    Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        listener?.cancel();
        completer.complete(false);
      }
    });

    return completer.future;
  }
}
