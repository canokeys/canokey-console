import 'package:canokey_console/controller/base/admin_controller.dart';
import 'package:canokey_console/controller/base/polling_controller.dart';
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

class PassController extends PollingController with AdminApplet {
  late List<PassSlot> slots;
  PassSlot get slotShort => slots[0];
  PassSlot get slotLong => slots[1];

  @override
  Logger get log => Logger('Console:Pass:Controller');

  @override
  Future<void> refreshData() async {
    SmartCard.process((String sn) async {
      SmartCard.assertOK(await SmartCard.transceive('00A4040005F000000000'));

      // read firmware version
      String resp = await SmartCard.transceive('0031000000');
      SmartCard.assertOK(resp);
      String firmwareVersion = String.fromCharCodes(hex.decode(SmartCard.dropSW(resp)));

      FunctionSetVersion functionSetVersion = CanoKey.functionSetFromFirmwareVersion(firmwareVersion);
      if (!CanoKey.functionSet(functionSetVersion).contains(Func.pass)) {
        Prompts.showPrompt(S.current.passNotSupported, ContentThemeColor.danger);
        return;
      }

      if (!await authenticate(sn)) {
        return;
      }

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
    SmartCard.process((String sn) async {
      if (!await authenticate(sn)) {
        return;
      }
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

      refreshData();
    });
  }

  static int short = 1;
  static int long = 2;
}
