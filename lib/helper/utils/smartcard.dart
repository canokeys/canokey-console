import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/audio.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:ccid/ccid.dart'
    if (dart.library.html) 'package:canokey_console/helper/ccid_dummy.dart';
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
/// - process_without_input: perform card reading operation
/// - input: waiting for user input
/// - process_with_input: perform card reading operation.
///
///                                   finish/error
///                          ┌──────────────────────────┐
///                          │                          │
/// ┌───────┐finish/error┌───▼──┐ UI event  ┌───────────┴─────────┐
/// │       ├────────────►      ├───────────►                     │
/// │refresh│            │ idle │           │process_without_input├──┐
/// │       ◄────────────┤      ◄───────────┤                     │  │
/// └───┬───┘     tap    └▲─▲───┘  timeout  └─────────────────────┘  │
///     │                 │ │              finish                    │
///     │                 │ └───────────────────────────────┐        │
///     │                 │ error / input required          │        │
///     │          cancel │ ┌───────────────────┐           │        │
///     │                 │ │                   │           │        │
///     │                ┌┴─▼──┐  confirm   ┌───┴───────────┴──┐     │
///     │                │     ├────────────►                  │     │
///     └────────────────►input│            │process_with_input│     │
///      input required  │     ◄────────────┤                  │     │
///                      └──▲──┘  timeout   └──────────────────┘     │
///                         │                                        │
///                         └────────────────────────────────────────┘
///                                     input required
enum NfcState {
  mute, // When USB is connected, NFC should be muted and not be polled
  refresh,
  idle,
  processWithoutInput,
  input,
  processWithInput,
}

typedef RefreshCallback = Future<void> Function();

class SmartCard {
  static String _currentSN = '';

  static CcidCard? _ccidCard;

  static Completer<bool>? _androidNfcCompleter;

  static Timer? _androidNfcTimer;

  static int _androidNfcOperation = 0;

  static int _cardProcessGeneration = 0;

  static int _androidNfcCleanup = 0;

  static bool _ccidPollInProgress = false;

  static final Set<String> _permissionDeniedCcidReaders = {};

  static int _activeCardOperations = 0;

  static int _lastFinishedTime = 0;

  static NfcState _nfcState = NfcState.mute;
  static NfcState get nfcState => _nfcState;
  static set nfcState(NfcState value) {
    _nfcState = value;
    log.t('nfcState = $_nfcState');
  }

  static RefreshCallback? refreshHandler;

  static ConnectionType connectionType = ConnectionType.none;
  static String? connectionError;

  /// Returns the response APDU without the SW
  static String dropSW(String rapdu) {
    return rapdu.substring(0, rapdu.length - 4);
  }

  /// Returns true if the SW is '9000'
  static bool isOK(String rapdu) {
    return sw(rapdu) == '9000';
  }

  /// Returns the status word of the response APDU in uppercase.
  static String sw(String rapdu) {
    return rapdu.substring(rapdu.length - 4).toUpperCase();
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

  static Future<void> startAndroidNfcHandler() async {
    while (true) {
      try {
        final tag = await FlutterNfcKit.poll(
          timeout: const Duration(seconds: 10),
          androidCheckNDEF: false,
          readIso14443B: false,
          readIso15693: false,
          androidPlatformSound: false,
        );
        log.t('[nfcHandler] NFC tag polled: ${tag.id}');
        switch (nfcState) {
          case NfcState.mute:
          case NfcState.input:
            log.t("[nfcHandler] Current state: $nfcState. Do nothing.");

          case NfcState.idle:
            final handler = refreshHandler;
            if (handler == null) {
              log.t('[nfcHandler] No active refresh handler. Ignored.');
              break;
            }
            if (DateTime.now().millisecondsSinceEpoch - _lastFinishedTime <
                2000) {
              log.t(
                  "[nfcHandler] Current state: $nfcState. Too soon. Ignored.");
              break;
            }
            log.t(
                "[nfcHandler] Current state: $nfcState. Next state: refresh.");
            _beginAndroidNfcOperation();
            Audio.poll();
            Prompts.promptAndroidPolling();
            nfcState = NfcState.refresh;
            unawaited(handler().catchError((Object error, StackTrace stack) {
              log.e('[nfcHandler] Failed to refresh NFC data.',
                  error: error, stackTrace: stack);
            }));

          case NfcState.refresh:
            log.e(
                "[nfcHandler] Current state: $nfcState. No tag should be polled. Next state: idle.");
            nfcState = NfcState.idle;

          case NfcState.processWithoutInput:
          case NfcState.processWithInput:
            log.t(
                "[nfcHandler] Current state: $nfcState. Continue to process.");
            _androidNfcTimer?.cancel();
            final completer = _androidNfcCompleter;
            if (completer != null && !completer.isCompleted) {
              completer.complete(true);
            } else {
              log.w('[nfcHandler] No NFC operation is waiting for this tag.');
            }
            Audio.poll();
        }
      } on PlatformException catch (e) {
        if (e.code == '408') {
          // do nothing
        } else {
          rethrow;
        }
      } catch (e) {
        log.e('[nfcHandler] Current state: $nfcState. Error polling NFC tag.',
            error: e);
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  static Future<bool> pollNfcOrWebUsb() async {
    if (connectionType == ConnectionType.ccid) {
      // No need to poll
      return true;
    }
    if (isAndroidApp()) {
      switch (nfcState) {
        case NfcState.mute:
        case NfcState.idle:
        case NfcState.input:
          log.e(
              "[pollNfcOrWebUsb] Tag should not be polled in $nfcState state.");
          return false;

        case NfcState.processWithoutInput:
        case NfcState.processWithInput:
          log.t("[pollNfcOrWebUsb] Current state: $nfcState. Start polling.");
          final operation = _beginAndroidNfcOperation();
          Prompts.promptAndroidPolling();
          final completer = Completer<bool>();
          _androidNfcCompleter = completer;
          _androidNfcTimer = Timer(const Duration(seconds: 10), () {
            if (operation != _androidNfcOperation || completer.isCompleted) {
              return;
            }
            completer.complete(false);
            if (nfcState == NfcState.processWithoutInput) {
              log.t(
                  "[pollNfcOrWebUsb] Current state: $nfcState. Timeout. Next state: idle.");
              nfcState = NfcState.idle;
            } else {
              log.t(
                  "[pollNfcOrWebUsb] Current state: $nfcState. Timeout. Next state: input.");
              nfcState = NfcState.input;
            }
          });
          return completer.future;

        case NfcState.refresh:
          log.t(
              "[pollNfcOrWebUsb] Current state: refresh. Tag has been polled.");
          return true;
      }
    } else {
      await FlutterNfcKit.poll(
          iosAlertMessage: S.of(Get.context!).iosAlertMessage);
      return true;
    }
  }

  static int _beginAndroidNfcOperation() {
    _androidNfcCleanup++;
    _androidNfcTimer?.cancel();
    final previousCompleter = _androidNfcCompleter;
    if (previousCompleter != null && !previousCompleter.isCompleted) {
      previousCompleter.complete(false);
    }
    _androidNfcCompleter = null;
    return ++_androidNfcOperation;
  }

  static Future<void> stopPollingNfc(
      {bool withInput = false, int? operation, int? process}) async {
    if (connectionType == ConnectionType.ccid) {
      return;
    }
    if (isAndroidApp()) {
      final cleanup = ++_androidNfcCleanup;
      final expectedOperation = operation ?? _androidNfcOperation;
      final expectedProcess = process ?? _cardProcessGeneration;
      await Future.delayed(const Duration(milliseconds: 500));
      if (cleanup != _androidNfcCleanup ||
          expectedOperation != _androidNfcOperation ||
          expectedProcess != _cardProcessGeneration) {
        log.t('[stopPollingNfc] Superseded by newer NFC work. Ignored.');
        return;
      }
      _androidNfcTimer?.cancel();
      _androidNfcTimer = null;
      _androidNfcCompleter = null;
      Prompts.stopPromptAndroidPolling();
      switch (nfcState) {
        case NfcState.mute:
          log.e(
              "[stopPollingNfc] Current state: $nfcState. Tag should not be polled.");

        case NfcState.idle:
          log.t("[stopPollingNfc] Current state: $nfcState. Do nothing.");
        // _lastFinishedTime = DateTime.now().millisecondsSinceEpoch;
        // Audio.finish();

        case NfcState.processWithoutInput:
          final nextState = withInput ? NfcState.input : NfcState.idle;
          log.t(
              "[stopPollingNfc] Current state: $nfcState. Next state: $nextState.");
          nfcState = nextState;
          Audio.finish();

        case NfcState.processWithInput:
          log.t(
              "[stopPollingNfc] Current state: $nfcState. Next state: input.");
          nfcState = NfcState.input;

        case NfcState.input: // CHECKED CASE
          log.t("[stopPollingNfc] Current state: $nfcState. Do nothing.");
          _lastFinishedTime = DateTime.now().millisecondsSinceEpoch;
          Audio.finish();

        case NfcState.refresh: // CHECKED CASE
          final nextState = withInput ? NfcState.input : NfcState.idle;
          log.t(
              "[stopPollingNfc] Current state: $nfcState. Next state: $nextState.");
          nfcState = nextState;
          _lastFinishedTime = DateTime.now().millisecondsSinceEpoch;
          Audio.finish();
      }
    } else {
      await FlutterNfcKit.finish();
    }
  }

  static Future<void> process(Function(String sn) f) async {
    final processGeneration = ++_cardProcessGeneration;
    _activeCardOperations++;
    try {
      if (connectionType == ConnectionType.ccid) {
        await f(_currentSN);
      } else {
        if (nfcState == NfcState.idle) {
          nfcState = NfcState.processWithoutInput;
        }
        if (nfcState == NfcState.input) {
          nfcState = NfcState.processWithInput;
        }
        if (!await pollNfcOrWebUsb()) {
          return;
        }
        try {
          assertOK(await SmartCard.transceive('00A4040005F000000000'));
          final resp = await SmartCard.transceive('0032000000');
          SmartCard.assertOK(resp);
          final sn = SmartCard.dropSW(resp).toUpperCase();
          _currentSN = sn;
          if (isWeb()) {
            connectionType = ConnectionType.webusb;
            log.i(
                '[process] CanoKey (WebUSB) Polled. SN: $sn. Connection Type updated to WebUSB.');
          } else {
            connectionType = ConnectionType.nfc;
            log.i(
                '[process] CanoKey (NFC) Polled. SN: $sn. Connection Type updated to NFC.');
          }
          await f(sn);
        } on PlatformException catch (e) {
          if (e.message?.contains('SecurityError') == true) {
            // This is for WebUSB, handled by PollingController
            rethrow;
          }
          Prompts.stopPromptAndroidPolling(); // Hide other prompts first
          // TODO: check error messages
          if (e.message == 'NotFoundError: No device selected.') {
            Prompts.showPrompt(
                S.of(Get.context!).pollCanceled, ContentThemeColor.danger);
          } else if (e.message ==
              'NetworkError: A transfer error has occurred.') {
            Prompts.showPrompt(
                S.of(Get.context!).networkError, ContentThemeColor.danger);
          } else if (e.message == 'SessionCanceled') {
            Prompts.showPrompt(
                S.of(Get.context!).pollCanceled, ContentThemeColor.danger);
          } else if (e.code == '500') {
            Prompts.showPrompt(
                S.of(Get.context!).interrupted, ContentThemeColor.danger);
          } else {
            Prompts.showPrompt(
                e.message ?? 'Unknown error', ContentThemeColor.danger);
          }
          if (isAndroidApp()) {
            Audio.error();
            switch (nfcState) {
              case NfcState.refresh:
                log.t(
                    "[process] Current state: refresh. Communication error. Next state: idle.");
                nfcState = NfcState.idle;

              case NfcState.processWithoutInput:
                log.t(
                    "[process] Current state: processWithoutInput. Communication error. Next state: idle.");
                nfcState = NfcState.idle;

              case NfcState.processWithInput:
                log.t(
                    "[process] Current state: processWithInput. Communication error. Next state: input.");
                nfcState = NfcState.input;

              case NfcState.mute:
              case NfcState.idle:
              case NfcState.input:
                break;
            }
          }
        } finally {
          await stopPollingNfc(
              operation: _androidNfcOperation, process: processGeneration);
        }
      }
    } finally {
      _activeCardOperations--;
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
    Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_ccidPollInProgress) {
        return;
      }
      _ccidPollInProgress = true;
      try {
        await _pollCcidOnce();
      } finally {
        _ccidPollInProgress = false;
      }
    });
  }

  static Future<void> _pollCcidOnce() async {
    List<String> readers;
    try {
      readers = await Ccid().listReaders();
      connectionError = null;
      _permissionDeniedCcidReaders.retainAll(readers);
    } catch (e) {
      log.e('Failed to get available readers. Will retry.', error: e);
      connectionError = e.toString();
      return;
    }

    final activeCard = _ccidCard;
    if (activeCard != null && !readers.contains(activeCard.reader)) {
      log.i(
          'CanoKey (USB) removed: $_currentSN. Connection Type updated to None.');
      await _disconnectCcidCard(activeCard);
      _ccidCard = null;
      if (connectionType == ConnectionType.ccid) {
        _currentSN = '';
        connectionType = ConnectionType.none;
        if (isAndroidApp() && nfcState == NfcState.mute) {
          nfcState = NfcState.idle;
        }
      }
    }

    final name = readers.firstWhereOrNull((name) =>
        name.toLowerCase().contains('canokey') &&
        !_permissionDeniedCcidReaders.contains(name));
    if (name == null || _ccidCard != null || _activeCardOperations > 0) {
      return;
    }

    CcidCard? candidate;
    try {
      candidate = await Ccid().connect(name);
      var resp = await candidate.transceive('00A4040005F000000000');
      assertOK(resp!);
      resp = await candidate.transceive('0032000000');
      assertOK(resp!);

      _ccidCard = candidate;
      _currentSN = SmartCard.dropSW(resp).toUpperCase();
      connectionType = ConnectionType.ccid;
      if (isAndroidApp()) {
        _beginAndroidNfcOperation();
        Prompts.stopPromptAndroidPolling();
        nfcState = NfcState.mute;
      }
      log.i(
          'Successfully connected to CanoKey (USB). SN: $_currentSN. Connection Type updated to CCID.');
    } catch (e) {
      await _disconnectCcidCard(candidate);
      if (_isUsbPermissionDenied(e)) {
        _permissionDeniedCcidReaders.add(name);
        log.w('USB permission denied for CanoKey reader $name.');
      } else if (_isNoCardReaderState(e)) {
        log.d('CanoKey CCID reader is not ready.', error: e);
      } else {
        log.e('Failed to connect to CanoKey (USB)', error: e);
      }
    }
  }

  static Future<void> _disconnectCcidCard(CcidCard? card) async {
    if (card == null) {
      return;
    }
    try {
      await card.disconnect();
    } catch (e) {
      log.w('Failed to disconnect CanoKey (USB)', error: e);
    }
  }

  static bool _isNoCardReaderState(Object error) {
    return error is PlatformException &&
        (error.code == 'NO_CARD' ||
            error.code == 'CCID_READER_NOT_FOUND' ||
            error.code == 'CCID_READER_NOT_CONNECTED' ||
            error.message == 'Failed to find a card' ||
            error.message == 'Card is not connected' ||
            error.message == 'Reader not found' ||
            error.message == 'Reader not connected');
  }

  static bool _isUsbPermissionDenied(Object error) {
    return error is PlatformException &&
        error.code == 'CCID_USB_PERMISSION_DENIED';
  }

  static void onWebUSBDisconnected() {
    log.i(
        'CanoKey (WebUSB) removed: $_currentSN. Connection Type updated to None.');
    _currentSN = '';
    connectionType = ConnectionType.none;
  }
}
