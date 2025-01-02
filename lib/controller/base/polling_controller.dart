import 'dart:async';

import 'package:canokey_console/controller/base/base_controller.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:platform_detector/platform_detector.dart';

abstract class PollingController extends Controller {
  StreamSubscription<NFCTag>? _nfcListener;
  Timer? _usbPollTimer, _webPollTimer;
  bool polled = false;
  bool _wasNfcConnection = false;

  Future<void> doRefreshData();
  Logger get log;

  @override
  void onReady() async {
    super.onReady();

    if (isWeb()) {
      // Web platform: initial read and polling
      try {
        await refreshData();
      } catch (e) {
        log.warning('Failed to read card on web platform', e);
      }
      _webPollTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (SmartCard.connectionType == ConnectionType.none) {
          polled = false;
          update();
        }
        // Ignore other cases because we cannot detect if CanoKey is connected via WebUSB.
      });
    } else if (isDesktop()) {
      // Desktop platform: initial read and polling
      if (SmartCard.connectionType == ConnectionType.ccid) {
        try {
          await refreshData();
        } catch (e) {
          log.warning('Failed to read card on desktop platform', e);
        }
      }
      _usbPollTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (SmartCard.connectionType == ConnectionType.ccid && !polled) {
          refreshData();
          polled = true; // We need to set polled to true here because PIN may be required in refreshData
        } else if (SmartCard.connectionType == ConnectionType.none) {
          polled = false;
          update();
        } else {
          // Polled and connected to CCID, do nothing
        }
      });
    } else {
      // Initial read if USB connected and polling
      if (SmartCard.connectionType == ConnectionType.ccid) {
        try {
          await refreshData();
        } catch (e) {
          log.warning('Failed to read card on mobile platform', e);
        }
      }
      _usbPollTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if ((!polled || _wasNfcConnection) && SmartCard.connectionType == ConnectionType.ccid) {
          refreshData();
          polled = true; // We need to set polled to true here because PIN may be required in refreshData
        } else if (!_wasNfcConnection && SmartCard.connectionType == ConnectionType.none) {
          // Only update polled state if previous connection was not NFC
          polled = false;
          update();
        }
        if (isAndroidApp() && SmartCard.connectionType == ConnectionType.none) {
          if (_nfcListener == null) {
            log.info('Starting TagStream.');
            _nfcListener = FlutterNfcKit.tagStream.listen((tag) {
              log.info('TagStream: ${tag.id}.');
              refreshData();
            });
          }
        }
      });
    }
  }

  @override
  void onClose() {
    try {
      ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
      ScaffoldMessenger.of(Get.context!).hideCurrentMaterialBanner();
      _usbPollTimer?.cancel();
      _webPollTimer?.cancel();
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> refreshData() async {
    _wasNfcConnection = true;
    await doRefreshData();
  }
}
