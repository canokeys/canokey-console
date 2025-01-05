import 'package:canokey_console/controller/base/polling_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/widgets/input_pin_dialog.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/models/webauthn.dart';
import 'package:convert/convert.dart';
import 'package:fido2/fido2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class WebAuthnController extends PollingController {
  late Ctap2 _ctap;
  final Map<String, String> _localPinCache = {};
  final List<WebAuthnItem> webAuthnItems = [];

  @override
  Logger get log => Logging.logger('WebAuthn:Controller');

  @override
  Future<void> doRefreshData() async {
    SmartCard.process((String sn) async {
      List<int>? pinToken = await _getPinToken(sn);
      if (pinToken == null) {
        return;
      }

      webAuthnItems.clear();

      final cp = ClientPin(_ctap);
      final cm = CredentialManagement(_ctap, cp.pinProtocolVersion == 1 ? PinProtocolV1() : PinProtocolV2(), pinToken);
      try {
        for (var rp in (await cm.enumerateRPs())) {
          for (var element in (await cm.enumerateCredentials(rp.rpIdHash))) {
            webAuthnItems.add(WebAuthnItem(
              rpId: rp.rp.id,
              userName: element.user.name,
              userDisplayName: element.user.displayName,
              userId: element.user.id,
              credentialId: element.credentialId,
            ));
          }
        }
      } on CtapError catch (e) {
        if (e.status == CtapStatusCode.ctap2ErrNoCredentials) {
          log.i('No credentials');
        } else {
          rethrow;
        }
      }

      polled = true;
      update();
    });
  }

  changePin(String newPin) {
    SmartCard.process((String sn) async {
      String? pinToTry = _loadPin(sn);
      if (pinToTry == null) {
        await refreshData();
        changePin(newPin);
        return;
      }

      String resp = await SmartCard.transceive('00A4040008A0000006472F0001');
      SmartCard.assertOK(resp);

      final cp = ClientPin(_ctap);
      try {
        await cp.changePin(pinToTry, newPin);
        await _setPinCache(sn, newPin, LocalStorage.getPinCache(sn, _tag) != null);
        Prompts.showPrompt(S.of(Get.context!).pinChanged, ContentThemeColor.success);
      } catch (e) {
        if (e is CtapError) {
          if (e.status == CtapStatusCode.ctap2ErrPinInvalid) {
            Prompts.showPrompt(S.of(Get.context!).pinIncorrect, ContentThemeColor.danger);
          } else if (e.status == CtapStatusCode.ctap2ErrPinAuthBlocked) {
            Prompts.showPrompt(S.of(Get.context!).webauthnPinAuthBlocked, ContentThemeColor.danger);
          } else if (e.status == CtapStatusCode.ctap2ErrPinBlocked) {
            Prompts.showPrompt(S.of(Get.context!).webauthnPinBlocked, ContentThemeColor.danger);
          } else {
            Prompts.showPrompt('Unknown error', ContentThemeColor.danger);
          }
        } else {
          rethrow;
        }
      }
    });
  }

  delete(PublicKeyCredentialDescriptor credentialId) {
    SmartCard.process((String sn) async {
      String? pinToTry = _loadPin(sn);
      if (pinToTry == null) {
        await refreshData();
        delete(credentialId);
        return;
      }

      String resp = await SmartCard.transceive('00A4040008A0000006472F0001');
      SmartCard.assertOK(resp);

      final cp = ClientPin(_ctap);
      final pinToken = await cp.getPinToken(pinToTry, permissions: [ClientPinPermission.credentialManagement]);
      final cm = CredentialManagement(_ctap, cp.pinProtocolVersion == 1 ? PinProtocolV1() : PinProtocolV2(), pinToken);
      await cm.deleteCredential(credentialId);

      Navigator.pop(Get.context!);
      Prompts.showPrompt(S.of(Get.context!).delete, ContentThemeColor.success);
      webAuthnItems.removeWhere((element) => element.credentialId == credentialId);
      update();
    });
  }

  String? _loadPin(String sn) {
    // Try local cache first
    if (_localPinCache.containsKey(sn)) {
      return _localPinCache[sn]!;
    }

    // Try local storage
    final pin = LocalStorage.getPinCache(sn, _tag);
    if (pin != null) {
      _localPinCache[sn] = pin;
      return pin;
    }

    return null;
  }

  Future<List<int>?> _getPinToken(String sn) async {
    String resp = await SmartCard.transceive('00A4040008A0000006472F0001');
    SmartCard.assertOK(resp);
    _ctap = await Ctap2.create(CtapTransimtter());

    // We do nothing if the device does not support credMgmt or clientPin
    // TODO: prompt user
    if (_ctap.info.options?['credMgmt'] != true || _ctap.info.options?['clientPin'] == null) {
      Prompts.showPrompt(S.of(Get.context!).webauthnClientPinNotSupported, ContentThemeColor.danger);
      return null;
    }

    // If PIN is not set, ask the user to set PIN first
    if (_ctap.info.options?['clientPin'] == false) {
      if (!await _setPin(sn)) {
        return null;
      }
    }

    assert(_ctap.info.options?['clientPin'] == true);

    // Try local cache first
    if (_localPinCache.containsKey(sn)) {
      final pinToken = await _doGetPinToken(_localPinCache[sn]!);
      if (pinToken != null) {
        return pinToken;
      }
      _localPinCache.remove(sn);
    }

    // Try LocalStorage
    String? pinToTry = LocalStorage.getPinCache(sn, _tag);
    if (pinToTry != null) {
      final pinToken = await _doGetPinToken(pinToTry);
      if (pinToken != null) {
        _localPinCache[sn] = pinToTry;
        return pinToken;
      } else {
        await LocalStorage.setPinCache(sn, _tag, null);
      }
    }

    // Finally, prompt user
    // When using NFC, we need to finish NFC before showing the dialog
    if (SmartCard.connectionType == ConnectionType.nfc) {
      SmartCard.stopPollingNfc(withInput: true);
    }
    final stream = InputPinDialog.show(
      title: S.of(Get.context!).webauthnInputPinTitle,
      label: 'PIN',
      prompt: S.of(Get.context!).webauthnInputPinPrompt,
      validators: [LengthValidator(min: 4, max: 63)],
      showSaveOption: true,
    );
    try {
      await for (final result in stream) {
        // When using NFC, we need to poll NFC again
        if (SmartCard.connectionType == ConnectionType.nfc) {
          SmartCard.nfcState = NfcState.pollWithInput;
          if (!await SmartCard.startPollingNfcOrWebUsb()) {
            // timeout
            continue;
          }
        }

        List<int>? pinToken;
        try {
          pinToken = await _doGetPinToken(result.$1);
        } on PlatformException catch (e) {
          if (SmartCard.connectionType == ConnectionType.nfc) {
            SmartCard.stopPollingNfc();
          }
          log.e('_verifyCode failed', error: e);
          if (e.code == '500') {
            Prompts.showPrompt(e.message!, ContentThemeColor.danger);
            continue;
          }
          rethrow;
        }
        if (pinToken != null) {
          log.t('pin verified');
          _localPinCache[sn] = result.$1;
          if (result.$2) {
            await LocalStorage.setPinCache(sn, _tag, result.$1);
          }
          // PIN verified, close the dialog
          Navigator.pop(Get.context!);
          // Since PIN has been cached, if error happens, we don't need to re-prompt
          SmartCard.nfcState = NfcState.processWithoutInput;

          return pinToken;
        }
      }

      log.w('should not be reached');
      return null;
    } on UserCanceledError catch (_) {
      if (SmartCard.connectionType == ConnectionType.nfc) {
        SmartCard.nfcState = NfcState.idle;
      }
      return null;
    }
  }

  Future<bool> _setPin(String sn) async {
    // When using NFC, we need to stop polling before showing the dialog
    if (SmartCard.connectionType == ConnectionType.nfc) {
      SmartCard.stopPollingNfc(withInput: true);
    }
    final stream = InputPinDialog.show(
      title: S.of(Get.context!).webauthnSetPinTitle,
      label: 'PIN',
      prompt: S.of(Get.context!).webauthnSetPinPrompt,
      validators: [LengthValidator(min: 4, max: 63)],
    );
    try {
      await for (final result in stream) {
        // When using NFC, we need to poll NFC again
        if (SmartCard.connectionType == ConnectionType.nfc) {
          SmartCard.nfcState = NfcState.pollWithInput;
          if (!await SmartCard.startPollingNfcOrWebUsb()) {
            // timeout
            continue;
          }
        }
        try {
          // Set PIN and refresh by recreating Ctap2
          String resp = await FlutterNfcKit.transceive('00A4040008A0000006472F0001');
          SmartCard.assertOK(resp);
          final cp = ClientPin(_ctap);
          await cp.setPin(result.$1);
          log.i('setPin success');
        } on PlatformException catch (e) {
          if (SmartCard.connectionType == ConnectionType.nfc) {
            SmartCard.stopPollingNfc();
          }
          log.e('setPin error', error: e);
          if (e.code == '500') {
            Prompts.showPrompt(e.message!, ContentThemeColor.danger);
            continue;
          }
          rethrow;
        }
        await _setPinCache(sn, result.$1, result.$2);

        // PIN set, close the dialog and prompt the user
        Navigator.pop(Get.context!);
        Prompts.showPrompt(S.of(Get.context!).pinChanged, ContentThemeColor.success);
        // Since PIN has been cached, if error happens, we don't need to re-prompt
        SmartCard.nfcState = NfcState.processWithoutInput;
        // Update _ctap
        _ctap = await Ctap2.create(CtapTransimtter());

        return true;
      }

      log.w('should not be reached');
      return false;
    } on UserCanceledError catch (_) {
      if (SmartCard.connectionType == ConnectionType.nfc) {
        SmartCard.nfcState = NfcState.idle;
      }
      return false;
    }
  }

  Future<List<int>?> _doGetPinToken(String pin) async {
    String resp = await FlutterNfcKit.transceive('00A4040008A0000006472F0001');
    SmartCard.assertOK(resp);
    final cp = ClientPin(_ctap);
    try {
      return await cp.getPinToken(pin, permissions: [ClientPinPermission.credentialManagement]);
    } on CtapError catch (e) {
      if (e.status == CtapStatusCode.ctap2ErrPinInvalid) {
        Prompts.showPrompt(S.of(Get.context!).pinIncorrect, ContentThemeColor.danger);
      } else if (e.status == CtapStatusCode.ctap2ErrPinAuthBlocked) {
        Prompts.showPrompt(S.of(Get.context!).webauthnPinAuthBlocked, ContentThemeColor.danger);
      } else if (e.status == CtapStatusCode.ctap2ErrPinBlocked) {
        Prompts.showPrompt(S.of(Get.context!).webauthnPinBlocked, ContentThemeColor.danger);
      } else {
        Prompts.showPrompt('Unknown error', ContentThemeColor.danger);
      }
      return null;
    }
  }

  Future<void> _setPinCache(String sn, String pin, bool cachedInLocalStorage) async {
    _localPinCache[sn] = pin;
    if (cachedInLocalStorage) {
      await LocalStorage.setPinCache(sn, _tag, pin);
    }
  }

  final String _tag = 'webauthn';
}

class CtapTransimtter extends CtapDevice {
  @override
  Future<CtapResponse<List<int>>> transceive(List<int> command) async {
    List<int> lc;
    if (command.length <= 255) {
      lc = [command.length];
    } else {
      lc = [0, command.length >> 8, command.length & 0xff];
    }
    String capdu = '80100000${hex.encode(lc)}${hex.encode(command)}';
    String rapdu = '';
    do {
      if (rapdu.length >= 4) {
        final remain = rapdu.substring(rapdu.length - 2);
        capdu = '80C00000$remain';
        rapdu = rapdu.substring(0, rapdu.length - 4);
      }
      rapdu += await SmartCard.transceive(capdu);
    } while (rapdu.substring(rapdu.length - 4, rapdu.length - 2) == '61');
    List<int> resp = hex.decode(rapdu);
    return CtapResponse(resp[0], resp.sublist(1, resp.length - 2));
  }
}
