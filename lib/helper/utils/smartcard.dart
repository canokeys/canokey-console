import 'dart:async';

import 'package:canokey_console/helper/utils/card_session.dart';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/audio.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/src/rust/api/protocol.dart';
import 'package:ccid/ccid.dart'
    if (dart.library.html) 'package:canokey_console/helper/ccid_dummy.dart';
import 'package:convert/convert.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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
  static final CardSessions _sessions = CardSessions();

  static CardLease get currentLease =>
      _sessions.current?.lease ??
      (throw StateError('Protocol operations require SmartCard.process'));

  static String _currentSN = '';
  // The serial read while probing a CCID candidate happens before any session
  // binds; it is attached to each lease bound for that same physical card.
  static Uint8List? _ccidBootstrapSerial;

  static CcidCard? _ccidCard;
  static bool _connectionQuarantined = false;

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
  static int _dialogInputScopeDepth = 0;
  static NfcState? _dialogInputRestoreState;
  static NfcState? _pendingDialogInputRestoreState;

  static NfcState get nfcState => _nfcState;
  static set nfcState(NfcState value) {
    // A dialog may be dismissed while its card operation is still settling.
    // Restore the page state when that operation returns to input.
    if (_dialogInputScopeDepth == 0 &&
        value == NfcState.input &&
        _pendingDialogInputRestoreState != null) {
      value = _pendingDialogInputRestoreState!;
      _pendingDialogInputRestoreState = null;
    }
    _nfcState = value;
    log.t('nfcState = $_nfcState');
  }

  static void beginDialogInputScope() {
    if (_dialogInputScopeDepth++ > 0) {
      return;
    }

    _dialogInputRestoreState = _pendingDialogInputRestoreState ?? nfcState;
    _pendingDialogInputRestoreState = null;
    if (nfcState == NfcState.idle) {
      nfcState = NfcState.input;
    }
  }

  static void endDialogInputScope() {
    if (_dialogInputScopeDepth == 0) {
      return;
    }
    if (--_dialogInputScopeDepth > 0) {
      return;
    }

    final restoreState = _dialogInputRestoreState;
    _dialogInputRestoreState = null;
    if (restoreState == null || restoreState == NfcState.input) {
      return;
    }
    if (nfcState == NfcState.input) {
      nfcState = restoreState;
    } else if (nfcState == NfcState.processWithInput) {
      _pendingDialogInputRestoreState = restoreState;
    }
  }

  static RefreshCallback? refreshHandler;

  static ConnectionType connectionType = ConnectionType.none;
  static String? connectionError;

  /// On iOS, the built-in keyboard will be hidden if an external keyboard is connected.
  /// This function shows the keyboard by sending an eject consumer report.
  static Future<void> eject() async {
    if (!isIOSApp() || connectionType != ConnectionType.ccid) return;
    final session = _sessions.current;
    if (session != null) {
      // PIN prompts retain the owner zone. The keyboard consumer report must
      // not overlap card I/O; it does not SELECT or change authentication.
      final lease = session.lease;
      if (!lease.isExchanging) await lease.exchange('FFEEFFEE');
      return;
    }
    if (_sessions.isBusy) return;
    await _sessions.run((session) async {
      _bindConnection();
      await session.lease.exchange('FFEEFFEE');
    });
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
        // A re-poll of the tag held in the field is the in-flight operation's
        // own event (the process* states complete its completer below), so
        // evidence is only invalidated when a new use case binds its lease.
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
                "[nfcHandler] Current state: $nfcState. Too soon. Ignored.",
              );
              break;
            }
            log.t(
              "[nfcHandler] Current state: $nfcState. Next state: refresh.",
            );
            _beginAndroidNfcOperation();
            Audio.poll();
            Prompts.promptAndroidPolling();
            nfcState = NfcState.refresh;
            unawaited(
              handler().catchError((Object error, StackTrace stack) {
                log.e(
                  '[nfcHandler] Failed to refresh NFC data.',
                  error: error,
                  stackTrace: stack,
                );
              }),
            );

          case NfcState.refresh:
            log.e(
              "[nfcHandler] Current state: $nfcState. No tag should be polled. Next state: idle.",
            );
            nfcState = NfcState.idle;

          case NfcState.processWithoutInput:
          case NfcState.processWithInput:
            log.t(
              "[nfcHandler] Current state: $nfcState. Continue to process.",
            );
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
        log.e(
          '[nfcHandler] Current state: $nfcState. Error polling NFC tag.',
          error: e,
        );
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  static Future<bool> pollNfcOrWebUsb() async {
    _requireReusableConnection();
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
            "[pollNfcOrWebUsb] Tag should not be polled in $nfcState state.",
          );
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
                "[pollNfcOrWebUsb] Current state: $nfcState. Timeout. Next state: idle.",
              );
              nfcState = NfcState.idle;
            } else {
              log.t(
                "[pollNfcOrWebUsb] Current state: $nfcState. Timeout. Next state: input.",
              );
              nfcState = NfcState.input;
            }
          });
          final found = await completer.future;
          if (found) _bindConnection();
          return found;

        case NfcState.refresh:
          log.t(
            "[pollNfcOrWebUsb] Current state: refresh. Tag has been polled.",
          );
          _bindConnection();
          return true;
      }
    } else {
      if (isIOSApp()) {
        FocusManager.instance.primaryFocus?.unfocus();
        await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      }
      await FlutterNfcKit.poll(
        iosAlertMessage: S.of(Get.context!).iosAlertMessage,
      );
      _bindConnection();
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

  static Future<void> stopPollingNfc({
    bool withInput = false,
    int? operation,
    int? process,
  }) async {
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
            "[stopPollingNfc] Current state: $nfcState. Tag should not be polled.",
          );

        case NfcState.idle:
          log.t("[stopPollingNfc] Current state: $nfcState. Do nothing.");
        // _lastFinishedTime = DateTime.now().millisecondsSinceEpoch;
        // Audio.finish();

        case NfcState.processWithoutInput:
          final nextState = withInput ? NfcState.input : NfcState.idle;
          log.t(
            "[stopPollingNfc] Current state: $nfcState. Next state: $nextState.",
          );
          nfcState = nextState;
          Audio.finish();

        case NfcState.processWithInput:
          log.t(
            "[stopPollingNfc] Current state: $nfcState. Next state: input.",
          );
          nfcState = NfcState.input;

        case NfcState.input: // CHECKED CASE
          log.t("[stopPollingNfc] Current state: $nfcState. Do nothing.");
          _lastFinishedTime = DateTime.now().millisecondsSinceEpoch;
          Audio.finish();

        case NfcState.refresh: // CHECKED CASE
          final nextState = withInput ? NfcState.input : NfcState.idle;
          log.t(
            "[stopPollingNfc] Current state: $nfcState. Next state: $nextState.",
          );
          nfcState = nextState;
          _lastFinishedTime = DateTime.now().millisecondsSinceEpoch;
          Audio.finish();
      }
    } else {
      _sessions.invalidate();
      await FlutterNfcKit.finish();
    }
  }

  static Future<void> process(Function(String sn) f) =>
      _sessions.run((_) => _process(f));

  static Future<void> _process(Function(String sn) f) async {
    _requireReusableConnection();
    final processGeneration = ++_cardProcessGeneration;
    final timer = Stopwatch()..start();
    log.t('process #$processGeneration: started; connection=$connectionType');
    _activeCardOperations++;
    try {
      if (connectionType == ConnectionType.ccid) {
        _bindConnection();
        await f(_currentSN);
      } else {
        if (nfcState == NfcState.idle) {
          nfcState = NfcState.processWithoutInput;
        }
        if (nfcState == NfcState.input) {
          nfcState = NfcState.processWithInput;
        }
        if (!await pollNfcOrWebUsb()) {
          log.t('process #$processGeneration: polling canceled');
          return;
        }
        try {
          const transport = SmartCardApduTransport();
          await executeProtocolOperation(
            ProtocolOperation.bootstrapIdentity(
              step: BootstrapIdentityStep.selectAdmin,
            ),
            transport,
          );
          final serial = await executeProtocolOperation(
            ProtocolOperation.bootstrapIdentity(
              step: BootstrapIdentityStep.serial,
            ),
            transport,
          );
          currentLease.recordBootstrapSerial(serial);
          final sn = hex.encode(serial).toUpperCase();
          _currentSN = sn;
          if (isWeb()) {
            connectionType = ConnectionType.webusb;
            log.i(
              '[process] CanoKey (WebUSB) Polled. SN: $sn. Connection Type updated to WebUSB.',
            );
          } else {
            connectionType = ConnectionType.nfc;
            log.i(
              '[process] CanoKey (NFC) Polled. SN: $sn. Connection Type updated to NFC.',
            );
          }
          await f(sn);
        } on PlatformException catch (e, stack) {
          log.e(
            'process #$processGeneration: communication failed',
            error: e,
            stackTrace: stack,
          );
          if (e.message?.contains('SecurityError') == true) {
            // This is for WebUSB, handled by PollingController
            rethrow;
          }
          Prompts.stopPromptAndroidPolling(); // Hide other prompts first
          // TODO: check error messages
          if (e.message == 'NotFoundError: No device selected.') {
            Prompts.showPrompt(
              S.of(Get.context!).pollCanceled,
              ContentThemeColor.danger,
            );
          } else if (e.message ==
              'NetworkError: A transfer error has occurred.') {
            Prompts.showPrompt(
              S.of(Get.context!).networkError,
              ContentThemeColor.danger,
            );
          } else if (e.message == 'SessionCanceled') {
            Prompts.showPrompt(
              S.of(Get.context!).pollCanceled,
              ContentThemeColor.danger,
            );
          } else if (e.code == '500') {
            Prompts.showPrompt(
              S.of(Get.context!).interrupted,
              ContentThemeColor.danger,
            );
          } else {
            Prompts.showPrompt(
              S.current.operationFailed,
              ContentThemeColor.danger,
            );
          }
          if (isAndroidApp()) {
            Audio.error();
            switch (nfcState) {
              case NfcState.refresh:
                log.t(
                  "[process] Current state: refresh. Communication error. Next state: idle.",
                );
                nfcState = NfcState.idle;

              case NfcState.processWithoutInput:
                log.t(
                  "[process] Current state: processWithoutInput. Communication error. Next state: idle.",
                );
                nfcState = NfcState.idle;

              case NfcState.processWithInput:
                log.t(
                  "[process] Current state: processWithInput. Communication error. Next state: input.",
                );
                nfcState = NfcState.input;

              case NfcState.mute:
              case NfcState.idle:
              case NfcState.input:
                break;
            }
          }
        } finally {
          await stopPollingNfc(
            operation: _androidNfcOperation,
            process: processGeneration,
          );
        }
      }
    } catch (error, stack) {
      log.e(
        'process #$processGeneration: failed',
        error: error,
        stackTrace: stack,
      );
      rethrow;
    } finally {
      log.t(
        'process #$processGeneration: finished in ${timer.elapsedMilliseconds}ms',
      );
      _activeCardOperations--;
    }
  }

  // Capture the physical connection once; never route an old operation through
  // a newly selected global connection after an await.
  static void _requireReusableConnection() {
    if (_connectionQuarantined) {
      throw StateError(
        'Card transport cleanup failed; restart the app before reuse',
      );
    }
  }

  static void _bindConnection() {
    _requireReusableConnection();
    final session = _sessions.current;
    if (session == null) return;
    final card = _ccidCard;
    final ccid = connectionType == ConnectionType.ccid;
    final ccidBootstrapSerial = ccid ? _ccidBootstrapSerial : null;
    session.bind((command) async {
      try {
        log.d('C-APDU: $command');
        final response = ccid
            ? await (card ?? (throw StateError('Card is not connected')))
                  .transceive(command)
            : await FlutterNfcKit.transceive(command);
        if (response == null) throw StateError('Transceive failed');
        log.d('R-APDU: $response');
        return response;
      } catch (_) {
        // Isolate a failed/timed-out backend before the use-case lock is freed.
        // Never replay the APDU. A later use case must connect/poll afresh.
        _sessions.invalidate();
        _connectionQuarantined = true;
        if (ccid) {
          if (identical(_ccidCard, card)) {
            _ccidCard = null;
            _ccidBootstrapSerial = null;
          }
          _connectionQuarantined = !await _disconnectCcidCard(card);
        } else {
          try {
            await FlutterNfcKit.finish();
            _connectionQuarantined = false;
          } catch (_) {
            // Preserve the original transport failure and prevent channel reuse.
          }
        }
        if (_connectionQuarantined) {
          connectionError =
              'Card transport cleanup failed; restart the app before reuse';
        }
        _currentSN = '';
        connectionType = ConnectionType.none;
        rethrow;
      }
    });
    if (ccidBootstrapSerial != null) {
      session.lease.recordBootstrapSerial(ccidBootstrapSerial);
    }
  }

  static Future<String> transceive(String capdu) async {
    final session = _sessions.current;
    if (session != null) return session.lease.exchange(capdu);
    // Legacy one-off users also respect an active protocol use-case lease.
    return _sessions.run((session) async {
      _bindConnection();
      return session.lease.exchange(capdu);
    });
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
    if (_connectionQuarantined) return;
    List<String> readers;
    try {
      readers = await Ccid().listReaders();
      if (_connectionQuarantined) return;
      connectionError = null;
      _permissionDeniedCcidReaders.retainAll(readers);
    } catch (e) {
      log.e('Failed to get available readers. Will retry.', error: e);
      connectionError = e.toString();
      return;
    }

    // Observe unplug events without waiting for an in-flight use case. Channel
    // teardown and connection/probe APDUs still wait for exclusive ownership.
    if (_ccidCard case final card?) {
      if (!readers.contains(card.reader)) _sessions.invalidate();
    }
    await _sessions.run((_) => _updateCcidConnection(readers));
  }

  static Future<void> _updateCcidConnection(List<String> readers) async {
    if (_connectionQuarantined) return;
    final activeCard = _ccidCard;
    if (activeCard != null && !readers.contains(activeCard.reader)) {
      log.i(
        'CanoKey (USB) removed: $_currentSN. Connection Type updated to None.',
      );
      _sessions.invalidate();
      if (!await _disconnectCcidCard(activeCard)) {
        _connectionQuarantined = true;
        connectionError =
            'Card transport cleanup failed; restart the app before reuse';
      }
      _ccidCard = null;
      _ccidBootstrapSerial = null;
      if (connectionType == ConnectionType.ccid) {
        _currentSN = '';
        connectionType = ConnectionType.none;
        if (isAndroidApp() && nfcState == NfcState.mute) {
          nfcState = NfcState.idle;
        }
      }
    }

    final name = readers.firstWhereOrNull(
      (name) =>
          name.toLowerCase().contains('canokey') &&
          !_permissionDeniedCcidReaders.contains(name),
    );
    if (name == null || _ccidCard != null || _activeCardOperations > 0) {
      return;
    }

    CcidCard? candidate;
    try {
      candidate = await Ccid().connect(name);
      // The probe shares the use-case queue but binds no session yet; exchange
      // directly on the candidate until it becomes the active card.
      final probe = _CcidProbeTransport(candidate);
      await executeProtocolOperation(
        ProtocolOperation.bootstrapIdentity(
          step: BootstrapIdentityStep.selectAdmin,
        ),
        probe,
      );
      final serial = await executeProtocolOperation(
        ProtocolOperation.bootstrapIdentity(step: BootstrapIdentityStep.serial),
        probe,
      );

      _ccidCard = candidate;
      _ccidBootstrapSerial = Uint8List.fromList(serial);
      _currentSN = hex.encode(serial).toUpperCase();
      connectionType = ConnectionType.ccid;
      if (isAndroidApp()) {
        _beginAndroidNfcOperation();
        Prompts.stopPromptAndroidPolling();
        nfcState = NfcState.mute;
      }
      log.i(
        'Successfully connected to CanoKey (USB). SN: $_currentSN. Connection Type updated to CCID.',
      );
    } catch (e) {
      if (!await _disconnectCcidCard(candidate)) {
        _connectionQuarantined = true;
        connectionError =
            'Card transport cleanup failed; restart the app before reuse';
      }
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

  static Future<bool> _disconnectCcidCard(CcidCard? card) async {
    if (card == null) return true;
    try {
      await card.disconnect();
      return true;
    } catch (e) {
      log.w('Failed to disconnect CanoKey (USB)', error: e);
      return false;
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
    _sessions.invalidate();
    log.i(
      'CanoKey (WebUSB) removed: $_currentSN. Connection Type updated to None.',
    );
    _currentSN = '';
    connectionType = ConnectionType.none;
  }
}

/// Bootstrap probe of a not-yet-active CCID candidate. The caller still owns
/// connection cleanup and disconnects the candidate on any failure.
class _CcidProbeTransport implements ApduTransport {
  const _CcidProbeTransport(this.card);

  final CcidCard card;

  @override
  Future<String> transceive(String capdu) async =>
      await card.transceive(capdu) ?? (throw StateError('Transceive failed'));
}
