import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:ccid/ccid.dart' if (dart.library.html) 'package:canokey_console/helper/ccid_dummy.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:get/get.dart';
import 'package:platform_detector/platform_detector.dart';

final log = Logging.logger('SmartCard');

enum ConnectionType { none, ccid, nfc, webusb }

/// Because the Console manages the reading of CanoKey through the SmartCard.process method as a whole,
/// On Android, NFC should be handled through the foreground dispatcher, namely tagStream.
/// In order to handle correctly, the following states need to be introduced:
/// - refresh: read CanoKey information for the first time on the page
/// - idle: waiting for CanoKey to be tapped on the page
/// - poll_wo_input: card search triggered by the user
/// - process_wo_input: perform card reading operation
/// - input: waiting for user input
/// - poll_w_input: card search triggered by the user
/// - process_w_input: perform card reading operation.
///
///                                         finish/error
///                          ┌──────────────────────────────────────────┐
///                          │                                          │
/// ┌───────┐finish/error┌───▼──┐ UI event  ┌─────────────┐     ┌───────┴────────┐
/// │       ├────────────►      ├───────────►             │ tap │                │
/// │refresh│            │ idle │           │poll_wo_input├─────►process_wo_input┼──┐
/// │       ◄────────────┤      ◄───────────┤             │     │                │  │
/// └───┬───┘     tap    └▲─▲───┘  timeout  └─────────────┘     └────────────────┘  │
///     │                 │ │                 finish                                │
///     │                 │ └─────────────────────────────────────────────┐         │
///     │                 │             error / input required            │         │
///     │          cancel │ ┌───────────────────────────────────────────┐ │         │
///     │                 │ │                                           │ │         │
///     │                ┌┴─▼──┐  confirm   ┌────────────┐      ┌───────┴─┴──────┐  │
///     │                │     ├────────────►            │ tap  │                │  │
///     └────────────────►input│            │poll_w_input├──────►process_w_input │  │
///      input required  │     ◄────────────┤            │      │                │  │
///                      └──▲──┘  timeout   └────────────┘      └────────────────┘  │
///                         │                                                       │
///                         └───────────────────────────────────────────────────────┘
///                                            input required
enum NfcState {
  mute, // When USB is connected, NFC should be muted and not be polled
  refresh,
  idle,
  pollWithoutInput,
  processWithoutInput,
  input,
  pollWithInput,
  processWithInput,
}

typedef RefreshCallback = Future<void> Function();

class SmartCard {
  static String _currentSN = '';
  static CcidCard? _ccidCard;
  static late Completer<bool> _androidNfcCompleter;
  static Timer? _androidNfcTimer;
  static NfcState nfcState = NfcState.mute;
  static RefreshCallback? refreshHandler;

  static ConnectionType connectionType = ConnectionType.none;

  /// Returns the response APDU without the SW
  static String dropSW(String rapdu) {
    return rapdu.substring(0, rapdu.length - 4);
  }

  /// Returns true if the SW is '9000'
  static bool isOK(String rapdu) {
    return rapdu.endsWith('9000');
  }

  /// Throws an exception if the SW is not '9000'
  static void assertOK(String rapdu) {
    if (!isOK(rapdu)) {
      throw Exception('SW is not ok');
    }
  }

  /// On iOS, the built-in keyboard will be hidden if an external keyboard is connected.
  /// This function shows the keyboard by sending an eject consumer report.
  static Future<void> eject() async {
    if (isIOSApp() && connectionType == ConnectionType.ccid) {
      await _ccidCard?.transceive("FFEEFFEE");
    }
  }

  static startNfcHandler() {
    FlutterNfcKit.tagStream.listen((tag) async {
      log.t('[tagStream] NFC tag polled: ${tag.id}');
      switch (nfcState) {
        case NfcState.mute:
        case NfcState.input:
          log.t("[tagStream] Current state: $nfcState. Do nothing.");

        case NfcState.idle:
          log.t("[tagStream] Current state: idle. Next state: refresh.");
          nfcState = NfcState.refresh;
          if (refreshHandler != null) {
            await refreshHandler!();
          }

        case NfcState.pollWithoutInput:
        case NfcState.pollWithInput:
          if (nfcState == NfcState.pollWithoutInput) {
            log.t("[tagStream] Current state: pollWithoutInput. Next state: processWithoutInput.");
            nfcState = NfcState.processWithoutInput;
          } else {
            log.t("[tagStream] Current state: pollWithInput. Next state: processWithInput.");
            nfcState = NfcState.processWithInput;
          }
          _androidNfcTimer?.cancel();
          try {
            _androidNfcCompleter.complete(true);
          } on StateError catch (e) {
            log.w("[tagStream] Timed out. Shoule be handled in pollNfcOrWebUsb.", error: e);
          }

        case NfcState.refresh:
        case NfcState.processWithoutInput:
        case NfcState.processWithInput:
          log.t("[tagStream] Current state: $nfcState. No tag should be polled. Next state: idle.");
          nfcState = NfcState.idle;
      }
    });
  }

  static Future<bool> startPollingNfcOrWebUsb() async {
    if (connectionType == ConnectionType.ccid) {
      log.e("[startPollingNfcOrWebUsb] Current connection type: CCID. No need to poll.");
      return true;
    }
    if (isAndroidApp()) {
      switch (nfcState) {
        case NfcState.mute:
        case NfcState.idle:
        case NfcState.input:
        case NfcState.processWithoutInput: // TODO:why?
        case NfcState.processWithInput: // TODO: why?
          log.e("[startPollingNfcOrWebUsb] Tag should not be polled in $nfcState state.");
          return false;

        case NfcState.pollWithoutInput:
        case NfcState.pollWithInput:
          log.t("[startPollingNfcOrWebUsb] Current state: ${nfcState.name}. Start polling.");
          _androidNfcCompleter = Completer<bool>();
          Prompts.promptAndroidPolling();
          _androidNfcTimer = Timer(const Duration(seconds: 10), () {
            Prompts.stopPromptAndroidPolling();
            // TODO: i18n
            Prompts.showPrompt('Timeout', ContentThemeColor.warning);
            _androidNfcCompleter.complete(false);
            if (nfcState == NfcState.pollWithoutInput) {
              log.t("[startPollingNfcOrWebUsb] Current state: pollWithoutInput. Timeout. Next state: idle.");
              nfcState = NfcState.idle;
            } else {
              log.t("[startPollingNfcOrWebUsb] Current state: pollWithInput. Timeout. Next state: input.");
              nfcState = NfcState.input;
            }
          });
          return _androidNfcCompleter.future;

        case NfcState.refresh:
          log.t("[startPollingNfcOrWebUsb] Current state: refresh. Tag has been polled.");
          return true;
      }
    } else {
      await FlutterNfcKit.poll(iosAlertMessage: S.of(Get.context!).iosAlertMessage);
      return true;
    }
  }

  static Future<void> stopPollingNfc({withInput = false}) async {
    if (isAndroidApp()) {
      Prompts.stopPromptAndroidPolling();
      switch (nfcState) {
        case NfcState.idle:
        case NfcState.input:
          log.t("[stopPollingNfc] Current state: $nfcState. Do nothing.");

        case NfcState.processWithoutInput:
        case NfcState.processWithInput:
          log.t("[stopPollingNfc] Current state: $nfcState. Next state: idle.");
          nfcState = NfcState.idle;

        case NfcState.mute:
        case NfcState.pollWithoutInput:
        case NfcState.pollWithInput:
          log.t("[stopPollingNfc] Tag should not be polled in $nfcState state.");

        case NfcState.refresh:
          if (withInput) {
            log.t("[stopPollingNfc] Current state: refresh. Next state: input.");
            nfcState = NfcState.input;
          } else {
            log.t("[stopPollingNfc] Current state: refresh. Next state: idle.");
            nfcState = NfcState.idle;
          }
      }
    } else {
      await FlutterNfcKit.finish(closeWebUSB: false);
    }
  }

  static Future<void> process(Function(String sn) f) async {
    if (connectionType == ConnectionType.ccid) {
      await f(_currentSN);
    } else {
      if (nfcState == NfcState.idle) {
        nfcState = NfcState.pollWithoutInput;
      }
      if (!await startPollingNfcOrWebUsb()) {
        return;
      }
      try {
        assertOK(await FlutterNfcKit.transceive('00A4040005F000000000'));
        final resp = await SmartCard.transceive('0032000000');
        SmartCard.assertOK(resp);
        final sn = SmartCard.dropSW(resp).toUpperCase();
        _currentSN = sn;
        if (isWeb()) {
          connectionType = ConnectionType.webusb;
          log.i('[process] CanoKey (WebUSB) Polled. SN: $sn. Connection Type updated to WebUSB.');
        } else {
          connectionType = ConnectionType.nfc;
          log.i('[process] CanoKey (NFC) Polled. SN: $sn. Connection Type updated to NFC.');
        }
        await f(sn);
      } on PlatformException catch (e) {
        if (e.message?.contains('SecurityError') == true) {
          rethrow;
        }
        // TODO: check error messages
        if (e.message == 'NotFoundError: No device selected.') {
          Prompts.showPrompt(S.of(Get.context!).pollCanceled, ContentThemeColor.danger);
        } else if (e.message == 'NetworkError: A transfer error has occurred.') {
          Prompts.showPrompt(S.of(Get.context!).networkError, ContentThemeColor.danger);
        } else if (e.message == 'SessionCanceled') {
          Prompts.showPrompt(S.of(Get.context!).pollCanceled, ContentThemeColor.danger);
        } else {
          Prompts.showPrompt(e.message ?? 'Unknown error', ContentThemeColor.danger);
        }
        if (isAndroidApp()) {
          switch (nfcState) {
            case NfcState.refresh:
              log.t("[process] Current state: refresh. Communication error. Next state: idle.");
              nfcState = NfcState.idle;

            case NfcState.processWithoutInput:
              log.t("[process] Current state: processWithoutInput. Communication error. Next state: idle.");
              nfcState = NfcState.idle;

            case NfcState.processWithInput:
              log.t("[process] Current state: processWithInput. Communication error. Next state: input.");
              nfcState = NfcState.input;

            case NfcState.mute:
            case NfcState.idle:
            case NfcState.input:
            case NfcState.pollWithoutInput:
            case NfcState.pollWithInput:
              break;
          }
        }
      } finally {
        stopPollingNfc();
      }
    }
  }

  static Future<String> transceive(String capdu) async {
    String? rapdu;
    log.d('C-APDU: $capdu');
    if (connectionType != ConnectionType.ccid) {
      rapdu = await FlutterNfcKit.transceive(capdu);
    } else {
      if (_ccidCard == null) {
        Prompts.showPrompt(S.of(Get.context!).noCard, ContentThemeColor.danger);
        throw Exception('Card is not connected');
      }
      rapdu = await _ccidCard!.transceive(capdu);
      if (rapdu == null) {
        throw Exception('Transceive failed');
      }
    }
    log.d('R-APDU: $rapdu');
    return rapdu!;
  }

  static void pollCcid() {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      List<String> readers = await Ccid().listReaders();
      final name = readers.firstWhereOrNull((name) => name.toLowerCase().contains("canokey"));
      if (name != null) {
        if (_ccidCard == null) {
          log.i('[pollCcid] New CanoKey (USB) detected: $name');
          try {
            _ccidCard = await Ccid().connect(name);
            var resp = await _ccidCard!.transceive('00A4040005F000000000');
            assertOK(resp!);
            resp = await _ccidCard!.transceive('0032000000');
            assertOK(resp!);
            _currentSN = SmartCard.dropSW(resp).toUpperCase();
            connectionType = ConnectionType.ccid;
            log.i('[pollCcid] Successfully connected to CanoKey (USB). SN: $_currentSN. Connection Type updated to CCID.');
          } catch (e) {
            log.e('[pollCcid] Failed to connect to CanoKey (USB)', error: e);
            _ccidCard = null;
            _currentSN = '';
          }
        }
      } else if (connectionType == ConnectionType.ccid && _currentSN != '') {
        log.i('[pollCcid] CanoKey (USB) removed: $_currentSN. Connection Type updated to None.');
        _ccidCard = null;
        _currentSN = '';
        connectionType = ConnectionType.none;
      }
    });
  }

  static void onWebUSBDisconnected() {
    log.i('[onWebUSBDisconnected] CanoKey (WebUSB) removed: $_currentSN. Connection Type updated to None.');
    _currentSN = '';
    connectionType = ConnectionType.none;
  }
}
