import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
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
import 'package:pem/pem.dart';

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
        String resp = await _transceive('00F700${hex.encode([slot])}00');
        if (resp.toUpperCase() == '6A88') {
          continue;
        }
        SmartCard.assertOK(resp);
        List<int> metadata = hex.decode(SmartCard.dropSW(resp));
        SlotInfo slotInfo = SlotInfo.parse(slot, metadata);
        if (_certDO.containsKey(slot)) {
          resp = await _transceive('00CB3FFF055C035FC1${hex.encode([_certDO[slot]!])}00');
          if (SmartCard.isOK(resp)) {
            final bytes = hex.decode(resp.substring(16, resp.length - 4));
            final cert = X509Utils.x509CertificateFromPem(PemCodec(PemLabel.certificate).encode(bytes));
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

  Future<bool> verifyManagementKey(String key) {
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

  Future<bool> importEccKey(String slot, ECPrivateKey key, PinPolicy pinPolicy, TouchPolicy touchPolicy) async {
    final c = new Completer<bool>();
    String algoId = '';
    switch (key.parameters!.domainName) {
      case 'prime256v1':
        algoId = '11';
        break;
      case 'secp384r1':
        algoId = '14';
        break;
      case 'secp256k1':
        algoId = '53';
        break;
    }
    var rawKey = key.d!.toRadixString(16);
    var data = '06${(rawKey.length ~/ 2).toRadixString(16).padLeft(2, '0')}${rawKey}AA01${pinPolicy.value.toRadixString(16).padLeft(2, '0')}AB01${touchPolicy.value.toRadixString(16).padLeft(2, '0')}';
    var capdu = '00FE$algoId$slot${(data.length ~/ 2).toRadixString(16).padLeft(2, '0')}$data';
    SmartCard.process(() async {
      String resp = await SmartCard.transceive(capdu);
      c.complete(SmartCard.isOK(resp));
    });
    return c.future;
  }

  Uint8List buildPivCert(Uint8List cert) {
    // Create a builder for the cert tag (0x70)
    var certTlv = Uint8List(2 + 2 + cert.length);
    certTlv[0] = 0x70;
    certTlv[1] = 0x82;
    certTlv[2] = (cert.length >> 8) & 0xFF;
    certTlv[3] = cert.length & 0xFF;
    certTlv.setRange(4, 4 + cert.length, cert);

    // Add the compressed tag (0x71)
    var compressedTlv = Uint8List(3);
    compressedTlv[0] = 0x71;
    compressedTlv[1] = 0x01;
    compressedTlv[2] = 0x00;

    // Add the LRC tag (0xFE)
    var lrcTlv = Uint8List(2);
    lrcTlv[0] = 0xFE;
    lrcTlv[1] = 0x00;

    // Calculate total length
    var totalLen = certTlv.length + compressedTlv.length + lrcTlv.length;
    
    // Create the final buffer with compact tag (0x53)
    var result = Uint8List(2 + 2 + totalLen);
    result[0] = 0x53;
    result[1] = 0x82;
    result[2] = (totalLen >> 8) & 0xFF;
    result[3] = totalLen & 0xFF;
    
    // Copy all TLVs into the result
    result.setRange(4, 4 + certTlv.length, certTlv);
    result.setRange(4 + certTlv.length, 4 + certTlv.length + compressedTlv.length, compressedTlv);
    result.setRange(4 + certTlv.length + compressedTlv.length, result.length, lrcTlv);
    
    return result;
  }

  Future<bool> importCert(String slot, Uint8List cert) async {
    final c = new Completer<bool>();
    int slotInt = int.parse(slot, radix: 16);
    if (_certDO.containsKey(slotInt)) {
      cert = buildPivCert(cert);
      String data = '5C035FC1${hex.encode([_certDO[slotInt]!])}${hex.encode(cert)}';
      int chunkSize = 2048;
      int offset = 0;
      while (offset < data.length) {
        int chunkLength = min(chunkSize, data.length - offset);
        String cla = '10';
        if (offset + chunkLength == data.length) cla = '00';
        int dataSize = chunkLength ~/ 2;
        String lc = dataSize.toRadixString(16).padLeft(dataSize > 255 ? 6 : 2, '0');
        String capdu = '${cla}DB3FFF$lc${data.substring(offset, offset + chunkLength)}';
        String resp = await SmartCard.transceive(capdu);
        if (SmartCard.isOK(resp)) {
          c.complete(false);
          return c.future;
        }
        offset += chunkLength;
      }
    }
    c.complete(true);
    return c.future;
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
