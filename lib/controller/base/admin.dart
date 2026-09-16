import 'dart:async';
import 'dart:convert';
import 'package:canokey_console/helper/utils/card_session.dart';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/admin_card.dart';
import 'package:canokey_console/helper/utils/audio.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/widgets/input_pin_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

final log = Logging.logger('AdminApplet');

/// PIN cache policy:
/// A local cache (in this controller) is maintained for each sn, which is used for avoiding
/// re-prompting the user for PIN.
/// If the user allows to save the PIN, the cache is also saved in the local storage, which
/// is identified by the sn.
mixin AdminApplet on GetxController {
  final AdminCardClient _adminCardClient = AdminCardClient();
  AdminCardClient get adminCardClient => _adminCardClient;
  Uint8List? _leasePin;
  CardLease? _pinLease;
  String? _pinSerial;
  int? _pinGeneration;

  /// Explicit input for each upstream Admin request, never an authorization token.
  String get adminPinForCurrentLease {
    final lease = SmartCard.currentLease;
    if (!identical(lease, _pinLease) || _leasePin == null) {
      throw StateError('Admin PIN was not verified in this lease');
    }
    lease.check();
    if (_pinGeneration !=
        LocalStorage.credentialGeneration(_pinSerial!, _tag)) {
      _forgetLeasePin();
      throw StateError('Admin credential was invalidated');
    }
    return utf8.decode(_leasePin!);
  }

  void _forgetLeasePin() {
    _leasePin?.fillRange(0, _leasePin!.length, 0);
    _leasePin = null;
    _pinLease = null;
    _pinSerial = null;
    _pinGeneration = null;
  }

  Future<void> forgetAdminPin(String sn) async {
    _forgetLeasePin();
    _localPinCache.remove(sn);
    await LocalStorage.setPinCache(sn, _tag, null);
  }

  @override
  void onClose() {
    adminCardClient.cancelPendingOperations();
    _forgetLeasePin();
    _localPinCache.clear();
    super.onClose();
  }

  final _localPinCache = CredentialCache('ADMIN');
  final String _tag = 'ADMIN';

  /// Returns true if CanoKey is authenticated. Must be called within SmartCard.process.
  ///
  /// We first try to use the local cache. If not cached, try LocalStorage.
  /// Finally, prompt the user for PIN.
  Future<bool> authenticate(String sn) async {
    final attemptedPins = <String>{};
    Future<bool> tryCachedPin(String pin) async {
      if (!attemptedPins.add(pin)) return false;
      return _selectAndVerifyPin(pin, sn);
    }

    // Try local cache first
    if (_localPinCache.containsKey(sn)) {
      if (await tryCachedPin(_localPinCache[sn]!)) {
        return true;
      }
      _localPinCache.remove(sn);
    }

    // Try LocalStorage
    String? pinToTry = LocalStorage.getPinCache(sn, _tag);
    if (pinToTry != null) {
      if (await tryCachedPin(pinToTry)) {
        _localPinCache[sn] = pinToTry;
        return true;
      } else {
        await LocalStorage.setPinCache(sn, _tag, null);
      }
    }

    // Finally, prompt user
    // When using NFC, we need to finish NFC before showing the dialog
    await SmartCard.stopPollingNfc(withInput: true);
    final completer = Completer<bool>();
    InputPinDialog.show(
      title: S.of(Get.context!).settingsInputPin,
      label: 'PIN',
      prompt: S.of(Get.context!).settingsInputPinPrompt,
      showSaveOption: true,
      onSubmit: (pin, savePin) async {
        // When using NFC, we need to poll NFC again
        SmartCard.nfcState = NfcState.processWithInput;
        if (!await SmartCard.pollNfcOrWebUsb()) {
          Prompts.stopPromptAndroidPolling();
          Prompts.showPrompt(
            S.of(Get.context!).noCard,
            ContentThemeColor.warning,
            level: 'W',
          );
          Audio.error();
          return; // timeout, do not close the dialog
        }
        Prompts.stopPromptAndroidPolling();
        bool verified = false;
        try {
          verified = await _selectAndVerifyPin(pin, sn);
        } on PlatformException catch (e) {
          await SmartCard.stopPollingNfc(withInput: true);
          log.e('_selectAndVerifyPin failed', error: e);
          if (e.code == '500') {
            Prompts.showPrompt(
              S.of(Get.context!).interrupted,
              ContentThemeColor.danger,
            );
            Audio.error();
          }
        } catch (error, stack) {
          // Terminal protocol/lifecycle failures must settle the owning use case.
          if (completer.isCompleted) return;
          completer.completeError(error, stack);
          Navigator.pop(Get.context!);
          return;
        }
        if (verified && !completer.isCompleted) {
          log.t('PIN verified');
          await updatePinCache(sn, pin, savePin);
          completer.complete(true);
          // Since PIN has been cached, if error happens, we don't need to re-prompt
          SmartCard.nfcState = NfcState.processWithoutInput;
          // Close the dialog
          Navigator.pop(Get.context!);
        }
      },
      onCancel: () async {
        SmartCard.nfcState = NfcState.idle;
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    return await completer.future;
  }

  Future<void> updatePinCache(String sn, String pin, bool savePin) async {
    _localPinCache[sn] = pin;
    if (savePin) {
      await LocalStorage.setPinCache(sn, _tag, pin);
    }
  }

  /// Returns true if pin is verified
  Future<bool> _selectAndVerifyPin(String pin, String expectedSerial) async {
    _forgetLeasePin();
    final lease = SmartCard.currentLease;
    await adminCardClient.prepare();
    if (await adminCardClient.readSerial() != expectedSerial.toUpperCase()) {
      throw StateError('Admin device changed before authentication');
    }
    if (await adminCardClient.verifyPin(pin)) {
      lease.check();
      _pinLease = lease;
      _pinSerial = expectedSerial;
      _pinGeneration = LocalStorage.credentialGeneration(expectedSerial, _tag);
      final bytes = _leasePin = Uint8List.fromList(utf8.encode(pin));
      lease.onClose(() {
        bytes.fillRange(0, bytes.length, 0);
        if (identical(_leasePin, bytes)) _forgetLeasePin();
      });
      return true;
    } else {
      Prompts.promptPinFailureResult(adminCardClient.lastStatusWord ?? '');
      return false;
    }
  }
}
