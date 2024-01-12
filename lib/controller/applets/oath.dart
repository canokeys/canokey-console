import 'dart:convert';
import 'dart:io';

import 'package:canokey_console/controller/my_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/tlv.dart';
import 'package:canokey_console/helper/utils/apdu.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:timer_controller/timer_controller.dart';

final log = Logger('Console:OATH:Controller');

class OathController extends MyController {
  Map<String, OathItem> oathMap = {};
  OathVersion version = OathVersion.v1;
  bool polled = false;
  TimerController timerController = TimerController.seconds(30);
  String codeCache = '';

  @override
  void onInit() {
    super.onInit();
    timerController.addListener(() {
      if (timerController.value.remaining == 0) {
        // set codes to empty for TOTP with touch required
        for (var name in oathMap.keys) {
          if (oathMap[name]!.requireTouch) {
            oathMap[name]!.code = '';
          }
        }
        update();
        if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          refreshData();
        }
      }
    });
  }

  @override
  void dispose() {
    timerController.dispose();
    super.dispose();
    try {
      ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
      // ignore: empty_catches
    } catch (e) {}
  }

  void refreshData() {
    Apdu.process(() async {
      String resp = await _transceive('00A4040007A0000005272101');
      Apdu.assertOK(resp);
      if (resp == '9000') {
        version = OathVersion.legacy; // not code support
      } else {
        Map info = TLV.parse(hex.decode(Apdu.dropSW(resp)));
        if (hex.encode(info[0x79]) == '050505') {
          version = OathVersion.v1;
        } else if (hex.encode(info[0x79]) == '060000') {
          version = OathVersion.v2;
        }
        if (info.containsKey(0x74)) {
          if (codeCache.isEmpty) {
            // without a pin
            Prompts.showInputPinDialog(
              title: S.of(Get.context!).oathInputCode,
              label: S.of(Get.context!).oathCode,
              prompt: S.of(Get.context!).oathInputCodePrompt,
            ).then((value) {
              codeCache = value;
              refreshData();
            }).onError((error, stackTrace) => null); // Canceled
            return;
          } else {
            final hmacSha1 = Hmac(Sha1());
            final pbkdf2 = Pbkdf2(macAlgorithm: hmacSha1, iterations: 1000, bits: 128);
            final key = await pbkdf2.deriveKey(secretKey: SecretKey(utf8.encode(codeCache)), nonce: info[0x71]);
            final mac = await hmacSha1.calculateMac(info[0x74], secretKey: key);
            resp = await _transceive('00A300001C7514${hex.encode(mac.bytes)}740400000000');
            if (resp == '6a80') {
              Prompts.showSnackbar(S.of(Get.context!).pinIncorrect, ContentThemeColor.danger);
              codeCache = '';
              return;
            }
            Apdu.assertOK(resp);
          }
        }
      }
      int challenge = DateTime.now().millisecondsSinceEpoch ~/ 30000;
      String challengeStr = challenge.toRadixString(16).padLeft(16, '0');
      if (version == OathVersion.legacy) {
        resp = await _transceive('000500000A7408$challengeStr');
      } else {
        resp = await _transceive('00A400010A7408$challengeStr');
      }
      Apdu.assertOK(resp);
      List<int> data = hex.decode(Apdu.dropSW(resp));
      polled = true;

      var items = _parse(data);
      // update oathMap with items
      for (var item in items) {
        if (oathMap.containsKey(item.name)) {
          // only update code
          if (item.code.isNotEmpty) {
            oathMap[item.name]!.code = item.code;
          }
        } else {
          oathMap[item.name] = item;
        }
      }
      // find names to remove
      List<String> toRemove = [];
      for (var name in oathMap.keys) {
        if (!items.any((element) => element.name == name)) {
          toRemove.add(name);
        }
      }
      // remove items by names
      for (var name in toRemove) {
        oathMap.remove(name);
      }

      int running = DateTime.now().millisecondsSinceEpoch ~/ 1000 % 30;
      timerController.reset();
      timerController.value = new TimerValue(remaining: 30 - running, unit: TimerUnit.second);
      timerController.start();
      update();
    });
  }

  void addAccount(String name, String secretHex, OathType type, OathAlgorithm algo, int digits, bool requireTouch, int initValue) {
    Apdu.process(() async {
      String resp = await _transceive('00A4040007A0000005272101');
      Apdu.assertOK(resp);

      // TODO: verify code

      List<int> nameBytes = utf8.encode(name);
      String capduData = '71${nameBytes.length.toRadixString(16).padLeft(2, '0')}${hex.encode(nameBytes)}'; // name 0x71
      capduData += '73' + // tag
          (secretHex.length ~/ 2 + 2).toRadixString(16).padLeft(2, '0') + // length
          (type.toValue() | algo.toValue()).toRadixString(16).padLeft(2, '0') + // type & algo
          digits.toRadixString(16).padLeft(2, '0') + // digits
          secretHex;
      if (requireTouch) {
        if (version == OathVersion.legacy) {
          capduData += '780102';
        } else {
          capduData += '7802';
        }
      }
      if (initValue > 0) {
        capduData += '7A04${initValue.toRadixString(16).padLeft(4, '0')}';
      }

      resp = await _transceive('00010000${(capduData.length ~/ 2).toRadixString(16).padLeft(2, '0')}$capduData');
      Apdu.assertOK(resp);

      Navigator.pop(Get.context!);
      Prompts.showSnackbar(S.of(Get.context!).oathAdded, ContentThemeColor.success);
      refreshData();
    });
  }

  void setCode(String newCode) {
    Apdu.process(() async {
      String resp = await _transceive('00A4040007A0000005272101');
      Apdu.assertOK(resp);
      if (resp == '9000') {
        return;
      } else {
        Map info = TLV.parse(hex.decode(Apdu.dropSW(resp)));
        if (hex.encode(info[0x79]) == '050505') {
          if (newCode.isEmpty) {
            // clear code
            resp = await _transceive('00030000027300');
          } else {
            final hmacSha1 = Hmac(Sha1());
            final pbkdf2 = Pbkdf2(macAlgorithm: hmacSha1, iterations: 1000, bits: 128);
            final key = await pbkdf2.deriveKey(secretKey: SecretKey(utf8.encode(newCode)), nonce: info[0x71]);
            final keyString = hex.encode(await key.extractBytes());
            final mac = await hmacSha1.calculateMac(List.of([0, 0, 0, 0]), secretKey: key);
            resp = await _transceive('000300002F731101${keyString}7404000000007514${hex.encode(mac.bytes)}');
          }
          Apdu.assertOK(resp);
          codeCache = newCode;
          Prompts.showSnackbar(S.of(Get.context!).oathCodeChanged, ContentThemeColor.success);
        }
      }
    });
  }

  Future<String> calculate(String name, OathType type) async {
    late String code;
    await Apdu.process(() async {
      String resp = await _transceive('00A4040007A0000005272101');
      Apdu.assertOK(resp);

      // TODO: verify code

      List<int> nameBytes = utf8.encode(name);
      String capduData = '71${nameBytes.length.toRadixString(16).padLeft(2, '0')}${hex.encode(nameBytes)}';
      if (type == OathType.totp) {
        int challenge = DateTime.now().millisecondsSinceEpoch ~/ 30000;
        String challengeStr = challenge.toRadixString(16).padLeft(16, '0');
        capduData += '7408$challengeStr';
      }
      if (version == OathVersion.legacy) {
        resp = await _transceive('00040000${(capduData.length ~/ 2).toRadixString(16).padLeft(2, '0')}$capduData');
      } else {
        resp = await _transceive('00A20001${(capduData.length ~/ 2).toRadixString(16).padLeft(2, '0')}$capduData');
      }
      Apdu.assertOK(resp);

      List<int> data = hex.decode(Apdu.dropSW(resp));
      code = _parseResponse(data.sublist(2));
      oathMap[name]!.code = code;

      update();
    });
    return code;
  }

  void delete(String name) {
    Apdu.process(() async {
      String resp = await _transceive('00A4040007A0000005272101');
      Apdu.assertOK(resp);
      List<int> nameBytes = utf8.encode(name);
      String capduData = '71${nameBytes.length.toRadixString(16).padLeft(2, '0')}${hex.encode(nameBytes)}';
      Apdu.assertOK(await _transceive('00020000${(capduData.length ~/ 2).toRadixString(16).padLeft(2, '0')}$capduData'));

      Navigator.pop(Get.context!);
      Prompts.showSnackbar(S.of(Get.context!).oathDeleted, ContentThemeColor.success);
      refreshData();
    });
  }

  List<OathItem> _parse(List<int> data) {
    List<OathItem> result = [];
    int pos = 0;
    while (pos < data.length) {
      OathItem item = _parseSingle(data.sublist(pos));
      pos += item.length;
      result.add(item);
    }
    return result;
  }

  OathItem _parseSingle(List<int> data) {
    assert(data.length >= 4);
    assert(data[0] == 0x71);

    int nameLen = data[1];
    assert(4 + nameLen <= data.length);
    String name = utf8.decode(data.sublist(2, 2 + nameLen));

    int dataLen = data[3 + nameLen];
    assert(4 + nameLen + dataLen <= data.length);

    String issuer, account;
    int colon = name.indexOf(':');
    if (colon == -1) {
      issuer = '';
      account = name;
    } else {
      issuer = name.substring(0, colon);
      account = name.substring(colon + 1);
    }

    OathItem item = OathItem(issuer, account);
    item.length = nameLen + dataLen + 4;
    switch (data[2 + nameLen]) {
      case 0x76: // response
        item.code = _parseResponse(data.sublist(4 + nameLen, 4 + nameLen + dataLen));
        break;
      case 0x77: // hotp
        item.type = OathType.hotp;
        break;
      case 0x7C: // touch
        item.requireTouch = true;
        break;
      default:
        throw Exception('Illegal tag');
    }
    return item;
  }

  String _parseResponse(List<int> resp) {
    assert(resp.length == 5);
    int digits = resp[0];
    int rawCode = (resp[1] << 24) | (resp[2] << 16) | (resp[3] << 8) | resp[4];
    int code = rawCode % _digitsPower[digits];
    return code.toString().padLeft(digits, '0');
  }

  Future<String> _transceive(String capdu) async {
    String rapdu = '';
    do {
      if (rapdu.length >= 4) {
        var remain = rapdu.substring(rapdu.length - 2);
        if (remain != '') {
          if (version == OathVersion.legacy) {
            capdu = '00060000$remain';
          } else {
            capdu = '00A50000$remain';
          }
          rapdu = rapdu.substring(0, rapdu.length - 4);
        }
      }
      rapdu += await FlutterNfcKit.transceive(capdu);
    } while (rapdu.substring(rapdu.length - 4, rapdu.length - 2) == '61');
    return rapdu;
  }

  final List<int> _digitsPower = [1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000];
}
