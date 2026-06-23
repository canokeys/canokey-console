import 'dart:async';

import 'package:canokey_console/controller/base/base_controller.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:platform_detector/platform_detector.dart';

abstract class PollingController extends Controller {
  Timer? _usbPollTimer, _webPollTimer;
  bool polled = false;
  bool _wasNfcConnection = false;
  bool _ccidRefreshAttempted = false;
  bool _ccidRefreshInProgress = false;

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
        log.w('Failed to read card on web platform', error: e);
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
        await _refreshCcidOnce('desktop platform');
      }
      _usbPollTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (SmartCard.connectionType == ConnectionType.ccid) {
          await _refreshCcidOnce('desktop platform');
        } else if (SmartCard.connectionType == ConnectionType.none) {
          _ccidRefreshAttempted = false;
          polled = false;
          update();
        } else {
          // NFC/WebUSB are handled by their platform-specific flows.
        }
      });
    } else {
      // Initial read if USB connected and polling
      if (SmartCard.connectionType == ConnectionType.ccid) {
        await _refreshCcidOnce('mobile platform');
      }
      if (isAndroidApp()) {
        SmartCard.refreshHandler = refreshData;
        SmartCard.nfcState = NfcState.idle;
      }
      _usbPollTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (SmartCard.connectionType == ConnectionType.ccid) {
          await _refreshCcidOnce('mobile platform', force: _wasNfcConnection);
        } else if (SmartCard.connectionType == ConnectionType.none) {
          _ccidRefreshAttempted = false;
          polled = false;
          update();
        }
        if (isAndroidApp()) {
          if (SmartCard.connectionType == ConnectionType.ccid) {
            log.t('USB connected. Set nfcState to mute.');
            SmartCard.nfcState = NfcState.mute;
          } else if (SmartCard.nfcState == NfcState.mute) {
            log.t('USB disconnected. Set nfcState to idle.');
            SmartCard.nfcState = NfcState.idle;
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
    await doRefreshData();
    _wasNfcConnection = SmartCard.connectionType == ConnectionType.nfc;
    log.t("wasNfcConnection = $_wasNfcConnection");
  }

  Future<void> _refreshCcidOnce(String platform, {bool force = false}) async {
    if (_ccidRefreshInProgress || (_ccidRefreshAttempted && !force)) {
      return;
    }
    _ccidRefreshAttempted = true;
    _ccidRefreshInProgress = true;
    try {
      await refreshData();
    } catch (e) {
      log.w('Failed to read card on $platform', error: e);
    } finally {
      _ccidRefreshInProgress = false;
    }
  }
}
