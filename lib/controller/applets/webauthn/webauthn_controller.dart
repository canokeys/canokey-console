import 'package:canokey_console/controller/base/polling_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/widgets/input_pin_dialog.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/models/webauthn.dart';
import 'package:convert/convert.dart';
import 'package:fido2/fido2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';

class WebAuthnController extends PollingController {
  late Ctap2 _ctap;
  final Map<String, String> _localPinCache = {};
  final List<WebAuthnItem> webAuthnItems = [];

  @override
  Logger get log => Logger('Console:WebAuthn:Controller');

  @override
  Future<void> doRefreshData() async {
    SmartCard.process((String sn) async {
      String resp = await SmartCard.transceive('00A4040008A0000006472F0001');
      SmartCard.assertOK(resp);

      _ctap = await Ctap2.create(CtapNfc());

      // We do nothing if the device does not support credMgmt or clientPin
      if (_ctap.info.options?['credMgmt'] != true || _ctap.info.options?['clientPin'] == null) {
        Prompts.showPrompt(S.of(Get.context!).webauthnClientPinNotSupported, ContentThemeColor.danger);
        return;
      }

      // PIN is not set
      if (_ctap.info.options?['clientPin'] == false) {
        // When using NFC, we need to finish NFC before showing the dialog
        if (SmartCard.useNfc()) {
          Prompts.stopPromptPolling();
          FlutterNfcKit.finish(closeWebUSB: false);
        }
        (String, bool) result;
        try {
          result = await InputPinDialog.show(
            title: S.of(Get.context!).webauthnSetPinTitle,
            label: 'PIN',
            prompt: S.of(Get.context!).webauthnSetPinPrompt,
            validators: [LengthValidator(min: 4, max: 63)],
          );
        } on UserCanceledError catch (_) {
          return;
        }
        // When using NFC, we need to poll NFC again after showing the dialog
        if (SmartCard.useNfc()) {
          Prompts.promptPolling();
          await FlutterNfcKit.poll(iosAlertMessage: S.of(Get.context!).iosAlertMessage);
          String resp = await FlutterNfcKit.transceive('00A4040008A0000006472F0001');
          SmartCard.assertOK(resp);
        }

        // Set PIN and refresh by recreating Ctap2
        final cp = ClientPin(_ctap);
        await cp.setPin(result.$1);
        await _setPinCache(sn, result.$1, result.$2);
        Prompts.showPrompt(S.of(Get.context!).pinChanged, ContentThemeColor.success);
        _ctap = await Ctap2.create(CtapNfc());
      }

      assert(_ctap.info.options?['clientPin'] == true);

      String? pinToTry = _loadPin(sn);
      if (pinToTry == null) {
        // When using NFC, we need to finish NFC before showing the dialog
        if (SmartCard.useNfc()) {
          Prompts.stopPromptPolling();
          FlutterNfcKit.finish(closeWebUSB: false);
        }
        try {
          final result = await InputPinDialog.show(
            title: S.of(Get.context!).webauthnInputPinTitle,
            label: 'PIN',
            prompt: S.of(Get.context!).webauthnInputPinPrompt,
            showSaveOption: true,
          );
          _localPinCache[sn] = result.$1;
          if (result.$2) {
            LocalStorage.setPinCache(sn, _tag, result.$1);
          }
          pinToTry = result.$1;
        } on UserCanceledError catch (_) {
          return;
        }
        // When using NFC, we need to poll NFC again after showing the dialog
        if (SmartCard.useNfc()) {
          Prompts.promptPolling();
          await FlutterNfcKit.poll(iosAlertMessage: S.of(Get.context!).iosAlertMessage);
          String resp = await FlutterNfcKit.transceive('00A4040008A0000006472F0001');
          SmartCard.assertOK(resp);
        }
      }

      final cp = ClientPin(_ctap);
      late final List<int> pinToken;
      try {
        pinToken = await cp.getPinToken(pinToTry, permissions: [ClientPinPermission.credentialManagement]);
      } on CtapError catch (e) {
        await _clearPinCache(sn);
        if (e.status == CtapStatusCode.ctap2ErrPinInvalid) {
          Prompts.showPrompt(S.of(Get.context!).pinIncorrect, ContentThemeColor.danger);
        } else if (e.status == CtapStatusCode.ctap2ErrPinAuthBlocked) {
          Prompts.showPrompt(S.of(Get.context!).webauthnPinAuthBlocked, ContentThemeColor.danger);
        } else if (e.status == CtapStatusCode.ctap2ErrPinBlocked) {
          Prompts.showPrompt(S.of(Get.context!).webauthnPinBlocked, ContentThemeColor.danger);
        } else {
          Prompts.showPrompt('Unknown error', ContentThemeColor.danger);
        }
        return;
      }

      webAuthnItems.clear();
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
          log.info('No credentials');
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

  Future<void> _setPinCache(String sn, String pin, bool cachedInLocalStorage) async {
    _localPinCache[sn] = pin;
    if (cachedInLocalStorage) {
      await LocalStorage.setPinCache(sn, _tag, pin);
    }
  }

  Future<void> _clearPinCache(String sn) async {
    _localPinCache.remove(sn);
    await LocalStorage.setPinCache(sn, _tag, null);
  }

  final String _tag = 'webauthn';
}

class CtapNfc extends CtapDevice {
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
