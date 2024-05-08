import 'dart:async';

import 'package:canokey_console/controller/base_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:convert/convert.dart';
import 'package:dart_des/dart_des.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';

final log = Logger('Console:PIV:Controller');

class PivController extends Controller {
  bool polled = true;

  @override
  void onClose() {
    try {
      ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
      ScaffoldMessenger.of(Get.context!).hideCurrentMaterialBanner();
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> refreshData(String pin) async {
    SmartCard.process(() async {
      SmartCard.assertOK(await SmartCard.transceive('00A4040005F000000000'));
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
}
