import 'dart:async';

import 'package:canokey_console/controller/base/base_controller.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:platform_detector/platform_detector.dart';

abstract class PollingController extends Controller {
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
        if (!SmartCard.isWebUSBConnected) {
          polled = false;
          update();
        }
      });
    } else if (isDesktop()) {
      // Desktop platform: initial read and polling
      if (SmartCard.isUsbConnected()) {
        try {
          await refreshData();
        } catch (e) {
          log.warning('Failed to read card on desktop platform', e);
        }
      }
      _usbPollTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!polled && SmartCard.isUsbConnected()) {
          refreshData();
        } else if (!SmartCard.isUsbConnected()) {
          polled = false;
          update();
        }
      });
    } else {
      // iOS/Android platform: initial read if USB connected and polling
      if (SmartCard.isUsbConnected()) {
        try {
          await refreshData();
          polled = true;
        } catch (e) {
          log.warning('Failed to read card on mobile platform', e);
        }
      }
      _usbPollTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if ((!polled || _wasNfcConnection) && SmartCard.isUsbConnected()) {
          refreshData();
        } else if (!SmartCard.isUsbConnected() && !_wasNfcConnection) {
          // Only update polled state if previous connection was not NFC
          polled = false;
          update();
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
    _wasNfcConnection = SmartCard.useNfc();
    await doRefreshData();
  }
}
