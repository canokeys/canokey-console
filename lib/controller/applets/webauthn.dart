import 'package:canokey_console/controller/my_controller.dart';
import 'package:canokey_console/helper/utils/apdu.dart';
import 'package:convert/convert.dart';
import 'package:fido2/fido2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';

final log = Logger('Console:WebAuthn:Controller');

class WebAuthnController extends MyController {
  bool polled = false;

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

      final (status, result) = await _transceive(Ctap2.makeGetInfoRequest());
      Info info = Ctap2.parseGetInfoResponse(result);

      update();
    });
  }

  Future<(int, List<int>)> _transceive(List<int> request) async {
    String ctapCmd = hex.encode(request);
    String capdu = '80100000${(ctapCmd.length ~/ 2).toRadixString(16).padLeft(2, '0')}$ctapCmd';
    String rapdu = '';
    do {
      if (rapdu.length >= 4) {
        var remain = rapdu.substring(rapdu.length - 2);
        if (remain != '') {
          capdu = '80C00000$remain';
          rapdu = rapdu.substring(0, rapdu.length - 4);
        }
      }
      rapdu += await FlutterNfcKit.transceive(capdu);
    } while (rapdu.substring(rapdu.length - 4, rapdu.length - 2) == '61');
    Apdu.assertOK(rapdu);
    String resp = Apdu.dropSW(rapdu);
    assert(resp.length >= 2);
    int status = hex.decode(resp.substring(0, 2))[0];
    List<int> response = [];
    if (resp.length > 2) {
      response = hex.decode(resp.substring(2));
    }
    return (status, response);
  }
}
