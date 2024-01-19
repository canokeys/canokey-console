import 'package:canokey_console/controller/my_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/apdu.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/widgets/my_validators.dart';
import 'package:canokey_console/models/webauthn.dart';
import 'package:convert/convert.dart';
import 'package:fido2/fido2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';

final log = Logger('Console:WebAuthn:Controller');

class WebAuthnController extends MyController {
  late Ctap2 ctap;
  bool polled = false;
  String pinCache = '';
  List<WebAuthnItem> webAuthnItems = [];

  @override
  void onClose() {
    try {
      ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
      // ignore: empty_catches
    } catch (e) {}
  }

  void refreshData() {
    Apdu.process(() async {
      String resp = await FlutterNfcKit.transceive('00A4040008A0000006472F0001');
      Apdu.assertOK(resp);

      ctap = await Ctap2.create(CtapNfc());
      if (ctap.info.options?['clientPin'] == null) {
        Prompts.showSnackbar(S.of(Get.context!).webauthnClientPinNotSupported, ContentThemeColor.danger);
        return;
      }
      if (ctap.info.options?['clientPin'] == false) {
        pinCache = await Prompts.showInputPinDialog(
          title: S.of(Get.context!).webauthnSetPinTitle,
          label: 'PIN',
          prompt: S.of(Get.context!).webauthnSetPinPrompt,
          validators: [MyLengthValidator(min: 4, max: 63)],
        );
        Prompts.showSnackbar(S.of(Get.context!).pinChanged, ContentThemeColor.success);
        return;
      }
      assert(ctap.info.options?['clientPin'] == true);

      if (pinCache.isEmpty) {
        pinCache = await Prompts.showInputPinDialog(
          title: S.of(Get.context!).webauthnInputPinTitle,
          label: 'PIN',
          prompt: S.of(Get.context!).webauthnInputPinPrompt,
        );
      }

      final cp = ClientPin(ctap);
      final pinToken = await cp.getPinToken(pinCache, permissions: [ClientPinPermission.credentialManagement]);
      final cm = CredentialManagement(ctap, cp.pinProtocolVersion == 1 ? PinProtocolV1() : PinProtocolV2(), pinToken);
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
      } on CtapException catch (e) {
        if (e.errorCode == 0x2E) {
          log.info('No credentials');
        }
        rethrow;
      }

      polled = true;
      update();
    });
  }

  changePin(String newPin) {
    Apdu.process(() async {
      String resp = await FlutterNfcKit.transceive('00A4040008A0000006472F0001');
      Apdu.assertOK(resp);

      final cp = ClientPin(ctap);
      if (!await cp.changePin(pinCache, newPin)) {
        Prompts.showSnackbar('Unknown error', ContentThemeColor.danger);
        return;
      }
      Prompts.showSnackbar(S.of(Get.context!).pinChanged, ContentThemeColor.success);
      pinCache = newPin;
    });
  }

  delete(PublicKeyCredentialDescriptor credentialId) {
    Apdu.process(() async {
      String resp = await FlutterNfcKit.transceive('00A4040008A0000006472F0001');
      Apdu.assertOK(resp);

      final cp = ClientPin(ctap);
      final pinToken = await cp.getPinToken(pinCache, permissions: [ClientPinPermission.credentialManagement]);
      final cm = CredentialManagement(ctap, cp.pinProtocolVersion == 1 ? PinProtocolV1() : PinProtocolV2(), pinToken);
      await cm.deleteCredential(credentialId);

      Navigator.pop(Get.context!);
      Prompts.showSnackbar(S.of(Get.context!).delete, ContentThemeColor.success);
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
      rapdu += await FlutterNfcKit.transceive(capdu);
    } while (rapdu.substring(rapdu.length - 4, rapdu.length - 2) == '61');
    List<int> resp = hex.decode(rapdu);
    return CtapResponse(resp[0], resp.sublist(1, resp.length - 2));
  }
}
