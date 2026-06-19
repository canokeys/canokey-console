import 'package:canokey_console/controller/base/polling_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/openpgp_card.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class OpenPgpController extends PollingController {
  final OpenPgpCardClient _client = OpenPgpCardClient();
  OpenPgpCardInfo? cardInfo;

  @override
  Logger get log => Logging.logger('OpenPGP:Controller');

  @override
  Future<void> doRefreshData() async {
    await SmartCard.process((String sn) async {
      cardInfo = await _client.readCardInfo();
      polled = true;
      update();
    });
  }

  Future<void> changeUserPin(String oldPin, String newPin) async {
    await _runPinOperation(() => _client.changeUserPin(oldPin, newPin));
  }

  Future<void> changeAdminPin(String oldPin, String newPin) async {
    await _runPinOperation(() => _client.changeAdminPin(oldPin, newPin));
  }

  Future<void> unblockUserPinWithAdmin(String adminPin, String newPin) async {
    await _runPinOperation(
        () => _client.unblockUserPinWithAdmin(adminPin, newPin));
  }

  Future<void> unblockUserPinWithResetCode(
      String resetCode, String newPin) async {
    await _runPinOperation(
        () => _client.unblockUserPinWithResetCode(resetCode, newPin));
  }

  Future<void> setResetCode(String adminPin, String resetCode) async {
    await _runPinOperation(() => _client.setResetCode(adminPin, resetCode));
  }

  Future<void> setPinRetries(String adminPin, int userRetries, int resetRetries,
      int adminRetries) async {
    await _runPinOperation(() => _client.setPinRetries(
        adminPin, userRetries, resetRetries, adminRetries));
  }

  Future<void> setSignaturePinPolicy(
      String adminPin, bool verifyForEverySignature) async {
    await _runPinOperation(
        () => _client.setSignaturePinPolicy(adminPin, verifyForEverySignature));
  }

  Future<void> setTouchPolicy(OpenPgpKeyType keyType, OpenPgpTouchPolicy policy,
      String adminPin) async {
    await SmartCard.process((String sn) async {
      final ok = await _client.setTouchPolicy(keyType, policy, adminPin);
      if (!ok) {
        Prompts.promptPinFailureResult(_client.lastStatusWord ?? '');
        return;
      }
      Navigator.pop(Get.context!);
      Prompts.showPrompt(
        S.of(Get.context!).openpgpUifChanged,
        ContentThemeColor.success,
        forceSnackBar: true,
      );
      cardInfo = await _client.readCardInfo();
      update();
    });
  }

  Future<void> setTouchCacheTime(String adminPin, int seconds) async {
    await SmartCard.process((String sn) async {
      final ok = await _client.setTouchCacheTime(adminPin, seconds);
      if (!ok) {
        Prompts.promptPinFailureResult(_client.lastStatusWord ?? '');
        return;
      }
      Navigator.pop(Get.context!);
      Prompts.showPrompt(
        S.of(Get.context!).successfullyChanged,
        ContentThemeColor.success,
        forceSnackBar: true,
      );
      cardInfo = await _client.readCardInfo();
      update();
    });
  }

  Future<void> _runPinOperation(Future<bool> Function() operation) async {
    await SmartCard.process((String sn) async {
      final ok = await operation();
      if (!ok) {
        Prompts.promptPinFailureResult(_client.lastStatusWord ?? '');
        return;
      }
      Navigator.pop(Get.context!);
      Prompts.showPrompt(
        S.of(Get.context!).successfullyChanged,
        ContentThemeColor.success,
        forceSnackBar: true,
      );
      cardInfo = await _client.readCardInfo();
      update();
    });
  }
}
