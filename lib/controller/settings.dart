import 'package:canokey_console/controller/my_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/apdu.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:convert/convert.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:get/get.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:logging/logging.dart';

final log = Logger('Console:Settings:Controller');

class SettingsController extends MyController {
  String _uid = '';

  late CanoKey key;
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

  /// Returns true if pin is verified
  ///
  /// If [skipClear] is true, the pin cache will not be cleared when the uid changes.
  /// This is used for the first time when the uid is never set.
  Future<bool> selectAndVerifyPin({bool skipClear = false}) async {
    if (_uid != Apdu.currentId) {
      _uid = Apdu.currentId;
      if (!skipClear) {
        pinCache = '';
      }
    }

    String resp = await FlutterNfcKit.transceive('00A4040005F000000000');
    Apdu.assertOK(resp);

    if (pinCache.isEmpty) {
      Prompts.showInputPinDialog(
        title: S.of(Get.context!).settingsInputPin,
        label: 'PIN',
        prompt: S.of(Get.context!).settingsInputPinPrompt,
      ).then((value) {
        pinCache = value;
        refreshData();
      }).onError((error, stackTrace) => null); // User canceled
      return false;
    } else {
      String resp = await FlutterNfcKit.transceive(
          '00200000${pinCache.length.toRadixString(16).padLeft(2, '0')}${hex.encode(pinCache.codeUnits)}');
      if (Apdu.isOK(resp)) {
        return true;
      }
      Prompts.promptPinFailureResult(resp);
      return false;
    }
  }

  Future<void> refreshData() async {
    await Apdu.process(() async {
      if (!await selectAndVerifyPin()) {
        return;
      }

      String resp = await FlutterNfcKit.transceive('0031000000');
      Apdu.assertOK(resp);
      String firmwareVersion =
          String.fromCharCodes(hex.decode(Apdu.dropSW(resp)));
      resp = await FlutterNfcKit.transceive('0031010000');
      Apdu.assertOK(resp);
      String model = String.fromCharCodes(hex.decode(Apdu.dropSW(resp)));
      resp = await FlutterNfcKit.transceive('0032000000');
      Apdu.assertOK(resp);
      String sn = Apdu.dropSW(resp).toUpperCase();
      resp = await FlutterNfcKit.transceive('0032010000');
      Apdu.assertOK(resp);
      String chipId = Apdu.dropSW(resp).toUpperCase();

      // read configurations
      FunctionSetVersion functionSetVersion =
          CanoKey.functionSetFromFirmwareVersion(firmwareVersion);
      bool ledOn = false;
      bool hotpOn = false;
      bool ndefReadonly = false;
      bool ndefEnabled = false;
      bool webusbLandingEnabled = false;
      bool keyboardWithReturn = false;
      bool sigTouch = false;
      bool decTouch = false;
      bool autTouch = false;
      int cacheTime = 0;
      bool nfcEnabled = true;
      resp = await FlutterNfcKit.transceive('0042000000');
      Apdu.assertOK(resp);
      switch (functionSetVersion) {
        case FunctionSetVersion.v1:
          ledOn = resp.substring(0, 2) == '01';
          hotpOn = resp.substring(2, 4) == '01';
          ndefReadonly = resp.substring(4, 6) == '01';
          sigTouch = resp.substring(6, 8) == '01';
          decTouch = resp.substring(8, 10) == '01';
          autTouch = resp.substring(10, 12) == '01';
          cacheTime = int.parse(resp.substring(12, 14), radix: 16);
          break;
        case FunctionSetVersion.v2:
          ledOn = resp.substring(0, 2) == '01';
          hotpOn = resp.substring(2, 4) == '01';
          ndefReadonly = resp.substring(4, 6) == '01';
          ndefEnabled = resp.substring(6, 8) == '01';
          webusbLandingEnabled = resp.substring(8, 10) == '01';
          break;
        case FunctionSetVersion.v3:
          ledOn = resp.substring(0, 2) == '01';
          hotpOn = resp.substring(2, 4) == '01';
          ndefReadonly = resp.substring(4, 6) == '01';
          ndefEnabled = resp.substring(6, 8) == '01';
          webusbLandingEnabled = resp.substring(8, 10) == '01';
          keyboardWithReturn = resp.substring(10, 12) == '01';
          break;
        case FunctionSetVersion.v4:
          ledOn = resp.substring(0, 2) == '01';
          hotpOn = resp.substring(2, 4) == '01';
          ndefReadonly = resp.substring(4, 6) == '01';
          ndefEnabled = resp.substring(6, 8) == '01';
          webusbLandingEnabled = resp.substring(8, 10) == '01';
          keyboardWithReturn = resp.substring(10, 12) == '01';
          // TODO: NFC
          break;
      }

      key = CanoKey(
          model: model,
          sn: sn,
          chipId: chipId,
          firmwareVersion: firmwareVersion,
          functionSetVersion: functionSetVersion,
          ledOn: ledOn,
          hotpOn: hotpOn,
          ndefReadonly: ndefReadonly,
          ndefEnabled: ndefEnabled,
          webusbLandingEnabled: webusbLandingEnabled,
          keyboardWithReturn: keyboardWithReturn,
          sigTouch: sigTouch,
          decTouch: decTouch,
          autTouch: autTouch,
          touchCacheTime: cacheTime,
          nfcEnabled: nfcEnabled);

      if (key.getFunctionSet().contains(Func.webAuthnSm2Support)) {
        resp = await FlutterNfcKit.transceive('0011000000');
        Apdu.assertOK(resp);
        key.webAuthnSm2Config = WebAuthnSm2Config(
          enabled: resp.substring(0, 2) == '01',
          curveId: Int32.parseHex(resp.substring(2, 10)).toInt(),
          algoId: Int32.parseHex(resp.substring(10, 18)).toInt(),
        );
      }

      polled = true;

      update();
    });
  }

  void changeSwitch(Func func, bool value) {
    Navigator.pop(Get.context!);

    Apdu.process(() async {
      if (!await selectAndVerifyPin()) {
        return;
      }

      Apdu.assertOK(
          await FlutterNfcKit.transceive(_changeSwitchAPDUs[func][value]));
      Prompts.showPrompt(
          S.of(Get.context!).successfullyChanged, ContentThemeColor.success);
      await refreshData();
    });
  }

  void changePin(String newPin) {
    Apdu.process(() async {
      if (!await selectAndVerifyPin()) {
        return;
      }

      Apdu.assertOK(await FlutterNfcKit.transceive(
          '00210000${newPin.length.toRadixString(16).padLeft(2, '0')}${hex.encode(newPin.codeUnits)}'));
      Prompts.showPrompt(
          S.of(Get.context!).pinChanged, ContentThemeColor.success);
      pinCache = newPin;
    });
  }

  void resetApplet(Applet applet) {
    Navigator.pop(Get.context!);

    Apdu.process(() async {
      if (!await selectAndVerifyPin()) {
        return;
      }

      Apdu.assertOK(await FlutterNfcKit.transceive(applet.resetApdu));
      Prompts.showPrompt(
          S.of(Get.context!).settingsResetSuccess, ContentThemeColor.success);
    });
  }

  void resetCanokey() {
    Apdu.process(() async {
      Apdu.assertOK(await FlutterNfcKit.transceive('00A4040005F000000000'));
      Get.context!.loaderOverlay.show();
      String resp = await FlutterNfcKit.transceive('00500000055245534554');
      Get.context!.loaderOverlay.hide();
      Navigator.pop(Get.context!);
      if (resp == '9000') {
        Prompts.showPrompt(
            S.of(Get.context!).settingsResetSuccess, ContentThemeColor.success);
      } else if (resp == '6985') {
        Prompts.showPrompt(
            S.of(Get.context!).settingsResetConditionNotSatisfying,
            ContentThemeColor.danger);
      } else if (resp == '6982') {
        Prompts.showPrompt(S.of(Get.context!).settingsResetPresenceTestFailed,
            ContentThemeColor.danger);
      } else {
        Prompts.showPrompt('Unknown error', ContentThemeColor.danger);
      }
    });
  }

  void fixNfc() {
    Apdu.process(() async {
      if (!await selectAndVerifyPin()) {
        return;
      }

      Apdu.assertOK(await FlutterNfcKit.transceive('00FF01000603A044000420'));
      Apdu.assertOK(
          await FlutterNfcKit.transceive('00FF01000903B005720300B39900'));
      Prompts.showPrompt(
          S.of(Get.context!).settingsFixNFCSuccess, ContentThemeColor.success);
    });
  }

  void changeWebAuthnSm2Config(bool enabled, int curveId, int algoId) {
    Navigator.pop(Get.context!);

    String cmdData = (enabled ? '01' : '00') +
        hex.encode(Int32(curveId).toBytes().reversed.toList()) +
        hex.encode(Int32(algoId).toBytes().reversed.toList());
    Apdu.process(() async {
      if (!await selectAndVerifyPin()) {
        return;
      }

      Apdu.assertOK(await FlutterNfcKit.transceive('0012000009$cmdData'));
      Prompts.showPrompt(
          S.of(Get.context!).successfullyChanged, ContentThemeColor.success);
      await refreshData();
    });
  }

  final Map _changeSwitchAPDUs = {
    Func.led: {true: '00400101', false: '00400100'},
    Func.hotp: {true: '00400301', false: '00400300'},
    Func.ndefEnabled: {true: '00400401', false: '00400400'},
    Func.ndefReadonly: {true: '00080100', false: '00080000'},
    Func.webusbLandingPage: {true: '00400501', false: '00400500'},
    Func.keyboardWithReturn: {true: '00400601', false: '00400600'},
    Func.sigTouch: {true: '00090001', false: '00090000'},
    Func.decTouch: {true: '00090101', false: '00090100'},
    Func.autTouch: {true: '00090201', false: '00090200'},
    Func.nfcSwitch: {true: '00400101', false: '00400100'}, // TODO: update this
  };
}
