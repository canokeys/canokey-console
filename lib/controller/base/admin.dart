import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/widgets/input_pin_dialog.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

final log = Logging.logger('AdminApplet');

/// PIN cache policy:
/// A local cache (in this controller) is maintained for each sn, which is used for avoiding
/// re-prompting the user for PIN.
/// If the user allows to save the PIN, the cache is also saved in the local storage, which
/// is identified by the sn.
mixin AdminApplet {
  final Map<String, String> _localPinCache = {};
  final String _tag = 'ADMIN';

  /// Returns true if CanoKey is authenticated. Must be called within SmartCard.process.
  ///
  /// We first try to use the local cache. If not cached, try LocalStorage.
  /// Finally, prompt the user for PIN.
  Future<bool> authenticate(String sn) async {
    // Try local cache first
    if (_localPinCache.containsKey(sn)) {
      if (await _selectAndVerifyPin(_localPinCache[sn]!)) {
        return true;
      }
      _localPinCache.remove(sn);
    }

    // Try LocalStorage
    String? pinToTry = LocalStorage.getPinCache(sn, _tag);
    if (pinToTry != null) {
      if (await _selectAndVerifyPin(pinToTry)) {
        _localPinCache[sn] = pinToTry;
        return true;
      } else {
        await LocalStorage.setPinCache(sn, _tag, null);
      }
    }

    // Finally, prompt user
    // When using NFC, we need to finish NFC before showing the dialog
    SmartCard.stopPollingNfc(withInput: true);
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
          Prompts.showPrompt(S.of(Get.context!).noCard, ContentThemeColor.warning, level: 'W');
          return; // timeout, do not close the dialog
        }
        Prompts.stopPromptAndroidPolling();
        bool verified = false;
        try {
          verified = await _selectAndVerifyPin(pin);
        } on PlatformException catch (e) {
          SmartCard.stopPollingNfc(withInput: true);
          log.e('_selectAndVerifyPin failed', error: e);
          if (e.code == '500') {
            Prompts.showPrompt(S.of(Get.context!).interrupted, ContentThemeColor.danger);
          }
        }
        if (verified) {
          log.t('PIN verified');
          _localPinCache[sn] = pin;
          if (savePin) {
            await LocalStorage.setPinCache(sn, _tag, pin);
          }
          completer.complete(true);
          // Since PIN has been cached, if error happens, we don't need to re-prompt
          SmartCard.nfcState = NfcState.processWithoutInput;
          // Close the dialog
          Navigator.pop(Get.context!);
        }
      },
      onCancel: () async {
        SmartCard.nfcState = NfcState.idle;
        completer.complete(false);
      },
    );
    return await completer.future;
  }

  Future<void> updatePinCache(String sn, String newPin) async {
    _localPinCache[sn] = newPin;
    if (LocalStorage.getPinCache(sn, _tag) != null) {
      await LocalStorage.setPinCache(sn, _tag, newPin);
    }
  }

  /// Returns true if pin is verified
  Future<bool> _selectAndVerifyPin(String pin) async {
    String resp = await SmartCard.transceive('00A4040005F000000000');
    SmartCard.assertOK(resp);
    resp = await SmartCard.transceive('00200000${pin.length.toRadixString(16).padLeft(2, '0')}${hex.encode(pin.codeUnits)}');
    if (SmartCard.isOK(resp)) {
      return true;
    } else {
      Prompts.promptPinFailureResult(resp);
      return false;
    }
  }
}
