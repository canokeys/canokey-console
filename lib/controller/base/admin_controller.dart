import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/widgets/input_pin_dialog.dart';
import 'package:convert/convert.dart';
import 'package:get/get.dart';

/// PIN cache policy:
/// A local cache (in this controller) is maintained for each sn, which is used for avoiding
/// re-prompting the user for PIN.
/// If the user allows to save the PIN, the cache is also saved in the local storage, which
/// is identified by the sn.
mixin AdminApplet {
  final Map<String, String> _localPinCache = {};
  final String _tag = 'ADMIN';

  /// Returns true if CanoKey is authenticated.
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
    try {
      final result = await InputPinDialog.show(
        title: S.of(Get.context!).settingsInputPin,
        label: 'PIN',
        prompt: S.of(Get.context!).settingsInputPinPrompt,
        showSaveOption: true,
      );
      if (await _selectAndVerifyPin(result.$1)) {
        _localPinCache[sn] = result.$1;
        if (result.$2) {
          await LocalStorage.setPinCache(sn, _tag, result.$1);
        }
        return true;
      }
    } on UserCanceledError catch (_) {
      // user canceled
    }
    return false;
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
