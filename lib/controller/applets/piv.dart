import 'dart:async';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:canokey_console/controller/base_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:convert/convert.dart';
import 'package:dart_des/dart_des.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:x509/x509.dart';

final log = Logger('Console:PIV:Controller');

class PivController extends Controller {
  bool polled = true;
  Map<int, SlotInfo> slots = {};

  @override
  void onClose() {
    try {
      ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
      ScaffoldMessenger.of(Get.context!).hideCurrentMaterialBanner();
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> refreshData(String pin) async {
    await SmartCard.process(() async {
      SmartCard.assertOK(await SmartCard.transceive('00A4040005A000000308'));
      for (var slot in [0x80, 0x81, 0x9B, 0x9A, 0x9C, 0x9D, 0x9E, 0x82, 0x83]) {
        String resp = await SmartCard.transceive('00F700${hex.encode([slot])}00');
        if (resp.toUpperCase() == '6A88') {
          continue;
        }
        SmartCard.assertOK(resp);
        List<int> metadata = hex.decode(SmartCard.dropSW(resp));
        SlotInfo slotInfo = SlotInfo.parse(slot, metadata);
        if (_certDO.containsKey(slot)) {
          resp = await _transceive('00CB3FFF055C035FC1${hex.encode([_certDO[slot]!])}00');
          if (SmartCard.isOK(resp)) {
            var bytes = hex.decode(resp.substring(16, resp.length - 4));
            var p = ASN1Parser(bytes as Uint8List);
            var o = p.nextObject();
            if (o is! ASN1Sequence) {
              throw FormatException('Expected SEQUENCE, got ${o.runtimeType}');
            }
            var cert = X509Certificate.fromAsn1(o);
            slotInfo.cert = cert;
            slotInfo.certBytes = bytes;
          }
        }
        slots[slot] = slotInfo;
      }

      update();
    });
  }

  changePin(String oldPin, String newPin) {
    SmartCard.process(() async {
      SmartCard.assertOK(await SmartCard.transceive('00A4040005A000000308'));
      String oldPinHex = _padPin(oldPin);
      String newPinHex = _padPin(newPin);
      String resp = await SmartCard.transceive('0024008010$oldPinHex$newPinHex');
      if (SmartCard.isOK(resp)) {
        Navigator.pop(Get.context!);
        Prompts.showPrompt(S.of(Get.context!).successfullyChanged, ContentThemeColor.success);
      } else {
        Prompts.promptPinFailureResult(resp);
      }
    });
  }

  changePUK(String oldPin, String newPin) {
    SmartCard.process(() async {
      SmartCard.assertOK(await SmartCard.transceive('00A4040005A000000308'));
      String oldPinHex = _padPin(oldPin);
      String newPinHex = _padPin(newPin);
      String resp = await SmartCard.transceive('0024008110$oldPinHex$newPinHex');
      if (SmartCard.isOK(resp)) {
        Navigator.pop(Get.context!);
        Prompts.showPrompt(S.of(Get.context!).successfullyChanged, ContentThemeColor.success);
      } else {
        Prompts.promptPinFailureResult(resp);
      }
    });
  }

  Future<bool> verifyManagementKey(String key) async {
    final c = new Completer<bool>();
    SmartCard.process(() async {
      SmartCard.assertOK(await SmartCard.transceive('00A4040005A000000308'));
      String resp = await SmartCard.transceive('0087039B047C028100');
      SmartCard.assertOK(resp);
      String challenge = resp.substring(8, resp.length - 4);
      DES3 des3 = DES3(key: hex.decode(key));
      String auth = hex.encode(des3.encrypt(hex.decode(challenge))).substring(0, 16);
      resp = await SmartCard.transceive('0087039B0C7C0A8208$auth');
      c.complete(SmartCard.isOK(resp));
    });
    return c.future;
  }

  setManagementKey(String key) async {
    SmartCard.process(() async {
      SmartCard.assertOK(await SmartCard.transceive('00FFFFFF1B039B18$key'));
      Navigator.pop(Get.context!);
      Prompts.showPrompt(S.of(Get.context!).successfullyChanged, ContentThemeColor.success);
    });
  }

  String _padPin(String pin) {
    String pinHex = pin.codeUnits.map((e) => e.toRadixString(16)).join();
    if (pinHex.length < 16) {
      pinHex = pinHex.padRight(16, 'F');
    }
    return pinHex;
  }

  Future<String> _transceive(String capdu) async {
    String rapdu = '';
    do {
      if (rapdu.length >= 4) {
        var remain = rapdu.substring(rapdu.length - 2);
        if (remain != '') {
          capdu = '00C00000$remain';
          rapdu = rapdu.substring(0, rapdu.length - 4);
        }
      }
      rapdu += await SmartCard.transceive(capdu);
    } while (rapdu.substring(rapdu.length - 4, rapdu.length - 2) == '61');
    return rapdu;
  }

  final Map<int, int> _certDO = {
    0x9A: 0x05,
    0x9C: 0x0A,
    0x9D: 0x0B,
    0x9E: 0x01,
    0x82: 0x0D,
    0x83: 0x0E,
  };
}
