import 'package:canokey_console/controller/base_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/models/webauthn.dart';
import 'package:convert/convert.dart';
import 'package:fido2/fido2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:platform_detector/platform_detector.dart';

final log = Logger('Console:WebAuthn:Controller');

class WebAuthnController extends Controller {
  late Ctap2 _ctap;
  String _pinCache = '';
  String _uid = '';

  bool polled = false;
  List<WebAuthnItem> webAuthnItems = [];

  @override
  void onClose() {
    try {
      ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
      ScaffoldMessenger.of(Get.context!).hideCurrentMaterialBanner();
      // ignore: empty_catches
    } catch (e) {}
  }

  void refreshData() {
    SmartCard.process(() async {
      if (_uid != SmartCard.currentId) {
        _uid = SmartCard.currentId;
        _pinCache = '';
      }

      String resp = await SmartCard.transceive('00A4040008A0000006472F0001');
      SmartCard.assertOK(resp);

      _ctap = await Ctap2.create(CtapNfc());

      // We do nothing if the device does not support clientPin
      if (_ctap.info.options?['clientPin'] == null) {
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
        _pinCache = await Prompts.showInputPinDialog(
          title: S.of(Get.context!).webauthnSetPinTitle,
          label: 'PIN',
          prompt: S.of(Get.context!).webauthnSetPinPrompt,
          validators: [LengthValidator(min: 4, max: 63)],
        );
        // When using NFC, we need to poll NFC again after showing the dialog
        if (SmartCard.useNfc()) {
          Prompts.promptPolling();
          await FlutterNfcKit.poll(iosAlertMessage: S.of(Get.context!).iosAlertMessage);
          String resp = await FlutterNfcKit.transceive('00A4040008A0000006472F0001');
          SmartCard.assertOK(resp);
        }
        final cp = ClientPin(_ctap);
        await cp.setPin(_pinCache);
        Prompts.showPrompt(S.of(Get.context!).pinChanged, ContentThemeColor.success);
      }

      assert(_ctap.info.options?['clientPin'] == true);

      if (_pinCache.isEmpty) {
        // When using NFC, we need to finish NFC before showing the dialog
        if (SmartCard.useNfc()) {
          Prompts.stopPromptPolling();
          FlutterNfcKit.finish(closeWebUSB: false);
        }
        _pinCache = await Prompts.showInputPinDialog(
          title: S.of(Get.context!).webauthnInputPinTitle,
          label: 'PIN',
          prompt: S.of(Get.context!).webauthnInputPinPrompt,
        );
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
        pinToken = await cp.getPinToken(_pinCache, permissions: [ClientPinPermission.credentialManagement]);
      } on CtapError catch (e) {
        _pinCache = '';
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
        final rp = await cm.enumerateRpsBegin();
        for (var element in (await cm.enumerateCredentials(rp.rpIdHash))) {
          webAuthnItems.add(WebAuthnItem(
            rpId: rp.rp.id,
            userName: element.user.name,
            userDisplayName: element.user.displayName,
            credentialId: element.credentialId,
          ));
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
    SmartCard.process(() async {
      if (_uid != SmartCard.currentId) {
        refreshData();
        return;
      }

      String resp = await SmartCard.transceive('00A4040008A0000006472F0001');
      SmartCard.assertOK(resp);

      final cp = ClientPin(_ctap);
      if (!await cp.changePin(_pinCache, newPin)) {
        Prompts.showPrompt('Unknown error', ContentThemeColor.danger);
        return;
      }
      Prompts.showPrompt(S.of(Get.context!).pinChanged, ContentThemeColor.success);
      _pinCache = newPin;
    });
  }

  delete(PublicKeyCredentialDescriptor credentialId) {
    SmartCard.process(() async {
      if (_uid != SmartCard.currentId) {
        refreshData();
        return;
      }

      String resp = await SmartCard.transceive('00A4040008A0000006472F0001');
      SmartCard.assertOK(resp);

      final cp = ClientPin(_ctap);
      final pinToken = await cp.getPinToken(_pinCache, permissions: [ClientPinPermission.credentialManagement]);
      final cm = CredentialManagement(_ctap, cp.pinProtocolVersion == 1 ? PinProtocolV1() : PinProtocolV2(), pinToken);
      await cm.deleteCredential(credentialId);

      Navigator.pop(Get.context!);
      Prompts.showPrompt(S.of(Get.context!).delete, ContentThemeColor.success);
      webAuthnItems.removeWhere((element) => element.credentialId == credentialId);
      update();
    });
  }
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
