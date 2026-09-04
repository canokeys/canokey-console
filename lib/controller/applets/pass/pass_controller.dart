import 'package:canokey_console/controller/base/admin.dart';
import 'package:canokey_console/controller/base/polling_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/applet_switches.dart';
import 'package:canokey_console/helper/utils/pass_card.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/screenshot_mode.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class PassController extends PollingController with AdminApplet {
  final PassCardClient _client = PassCardClient();
  List<PassSlot> slots = [PassSlot.empty(), PassSlot.empty()];
  PassSlot get slotShort => slots[0];
  PassSlot get slotLong => slots[1];
  bool hmacSha1Supported = false;
  String? disabledMessage;

  @override
  Logger get log => Logging.logger('Pass:Controller');

  @override
  Future<void> doRefreshData() async {
    if (ScreenshotMode.enabled) {
      slots = ScreenshotMode.passSlots();
      hmacSha1Supported = true;
      disabledMessage = null;
      polled = true;
      update();
      return;
    }

    await SmartCard.process((String sn) async {
      SmartCard.assertOK(await SmartCard.transceive('00A4040005F000000000'));

      // read firmware version
      String resp = await SmartCard.transceive('0031000000');
      SmartCard.assertOK(resp);
      String firmwareVersion =
          String.fromCharCodes(hex.decode(SmartCard.dropSW(resp)));

      FunctionSetVersion functionSetVersion =
          CanoKey.functionSetFromFirmwareVersion(firmwareVersion);
      final functionSet = CanoKey.functionSet(functionSetVersion);
      if (!functionSet.contains(Func.pass)) {
        Prompts.showPrompt(
            S.current.passNotSupported, ContentThemeColor.danger);
        return;
      }
      final switchStatus = await AppletSwitches.readStatus();
      if (!switchStatus.passEnabled) {
        disabledMessage = AppletSwitches.disabledMessage('Pass');
        polled = false;
        slots = [PassSlot.empty(), PassSlot.empty()];
        update();
        return;
      }
      disabledMessage = null;
      hmacSha1Supported = functionSet.contains(Func.passHmacSha1);

      if (!await authenticate(sn)) {
        return;
      }

      await _refresh();
    });
  }

  Future<void> setSlot(
      int index, PassSlotType type, String password, bool withEnter) async {
    await SmartCard.process((String sn) async {
      if (!await authenticate(sn)) {
        return;
      }

      if (type == PassSlotType.hmacSha1) {
        if (!hmacSha1Supported) {
          Prompts.showPrompt(
              S.of(Get.context!).notSupported, ContentThemeColor.danger);
          return;
        }
      } else if (type == PassSlotType.oath) {
        log.w('unsupported slot type');
        return;
      }
      final success = await _client.setSlot(index, type, password, withEnter);
      if (!success && Prompts.isStorageFull(_client.lastStatusWord ?? '')) {
        Prompts.showPrompt(
            S.of(Get.context!).storageFull, ContentThemeColor.danger);
        return;
      }
      SmartCard.assertOK(_client.lastStatusWord ?? '');
      log.i('Successfully changed slot');

      Navigator.pop(Get.context!);
      Prompts.showPrompt(
          S.of(Get.context!).successfullyChanged, ContentThemeColor.success,
          forceSnackBar: true);

      await _refresh();
    });
  }

  Future<void> _refresh() async {
    slots = await _client.readSlots();
    assert(slots.length == 2);
    polled = true;

    update();
  }

  static int short = 1;
  static int long = 2;
}
