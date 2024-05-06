import 'package:canokey_console/controller/my_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';

final log = Logger('Console:Pass:Controller');

class PassController extends MyController {
  PassSlot get slotShort => slots[0];

  PassSlot get slotLong => slots[1];

  late List<PassSlot> slots;
  bool polled = false;
  String pinCache = '';

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

      String resp = await SmartCard.transceive('0031000000');
      SmartCard.assertOK(resp);
      String firmwareVersion = String.fromCharCodes(hex.decode(SmartCard.dropSW(resp)));
      FunctionSetVersion functionSetVersion = CanoKey.functionSetFromFirmwareVersion(firmwareVersion);
      if (!CanoKey.functionSet(functionSetVersion).contains(Func.pass)) {
        Prompts.showPrompt('Not supported', ContentThemeColor.danger);
        return;
      }
      if (!await _verifyPin(pin)) return;
      pinCache = pin;

      // read pass configurations
      resp = await SmartCard.transceive('0043000000');
      SmartCard.assertOK(resp);

      slots = PassSlot.fromData(SmartCard.dropSW(resp));
      assert(slots.length == 2);
      polled = true;

      update();
    });
  }

  void setSlot(int index, PassSlotType type, String password, bool withEnter) {
    SmartCard.process(() async {
      SmartCard.assertOK(await SmartCard.transceive('00A4040005F000000000'));
      if (!await _verifyPin(pinCache)) return;
      Navigator.pop(Get.context!);

      String capduData = '';
      if (type == PassSlotType.none) {
        capduData = '00';
      } else if (type == PassSlotType.static) {
        capduData = '02${password.length.toRadixString(16).padLeft(2, '0')}${hex.encode(password.codeUnits)}${withEnter ? '01' : '00'}';
      } else {
        log.warning('unsupported slot type');
        return;
      }
      await SmartCard.transceive('0044${index == short ? '01' : '02'}00${(capduData.length ~/ 2).toRadixString(16).padLeft(2, '0')}$capduData');
      Prompts.showPrompt(S.of(Get.context!).successfullyChanged, ContentThemeColor.success);
      refreshData(pinCache);
      update();
    });
  }

  Future<bool> _verifyPin(String pin) async {
    String resp = await SmartCard.transceive('00200000${pin.length.toRadixString(16).padLeft(2, '0')}${hex.encode(pin.codeUnits)}');
    if (SmartCard.isOK(resp)) return true;
    Prompts.promptPinFailureResult(resp);
    return false;
  }

  static int short = 1;
  static int long = 2;
}
