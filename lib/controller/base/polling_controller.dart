import 'dart:async';

import 'package:canokey_console/controller/base/base_controller.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/screenshot_mode.dart';
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
  bool _closed = false;
  Future<void>? _refreshFuture;
  Future<void> Function()? _registeredRefreshHandler;

  Future<void> doRefreshData();
  Logger get log;

  @override
  void onReady() async {
    super.onReady();
    _closed = false;

    if (ScreenshotMode.enabled) {
      try {
        await refreshData();
      } catch (e) {
        log.w('Failed to load screenshot data', error: e);
        polled = false;
        update();
      }
      return;
    }

    if (isWeb()) {
      // Web platform: initial read and polling
      try {
        await refreshData();
      } catch (e) {
        log.w('Failed to read card on web platform', error: e);
      }
      if (_closed) return;
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
      if (_closed) return;
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
      if (_closed) return;
      if (isAndroidApp()) {
        final handler = refreshData;
        _registeredRefreshHandler = handler;
        SmartCard.refreshHandler = handler;
        SmartCard.nfcState = SmartCard.connectionType == ConnectionType.ccid
            ? NfcState.mute
            : NfcState.idle;
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
            if (SmartCard.nfcState != NfcState.mute) {
              log.t('USB connected. Set nfcState to mute.');
              SmartCard.nfcState = NfcState.mute;
            }
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
    _closed = true;
    _usbPollTimer?.cancel();
    _webPollTimer?.cancel();
    final handler = _registeredRefreshHandler;
    if (handler != null && identical(SmartCard.refreshHandler, handler)) {
      SmartCard.refreshHandler = null;
    }
    try {
      ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
      ScaffoldMessenger.of(Get.context!).hideCurrentMaterialBanner();
      // ignore: empty_catches
    } catch (e) {}
    super.onClose();
  }

  Future<void> refreshData() {
    final activeRefresh = _refreshFuture;
    if (activeRefresh != null) {
      return activeRefresh;
    }

    late final Future<void> refresh;
    refresh = Future<void>.sync(doRefreshData).then((_) {
      _wasNfcConnection = SmartCard.connectionType == ConnectionType.nfc;
      log.t("wasNfcConnection = $_wasNfcConnection");
    }).whenComplete(() {
      if (identical(_refreshFuture, refresh)) {
        _refreshFuture = null;
      }
    });
    _refreshFuture = refresh;
    return refresh;
  }

  Future<void> _refreshCcidOnce(String platform, {bool force = false}) async {
    if (_closed ||
        _ccidRefreshInProgress ||
        (_ccidRefreshAttempted && !force)) {
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
