import 'dart:async';
import 'dart:convert';

import 'package:canokey_console/controller/applets/oath/qr_scan_result.dart';
import 'package:canokey_console/controller/base/polling_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/tlv.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/widgets/input_pin_dialog.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:canokey_console/src/rust/api/crypto.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:platform_detector/platform_detector.dart';
import 'package:timer_controller/timer_controller.dart';

class OathController extends PollingController {
  final TimerController timerController = TimerController.seconds(30);
  final Rxn<QrScanResult> qrScanResult = Rxn<QrScanResult>();
  final Map<String, String> _localCodeCache = {};
  final Map<String, OathItem> oathMap = {};
  OathVersion version = OathVersion.v1;

  @override
  Logger get log => Logging.logger('OATH:Controller');

  @override
  void onReady() {
    super.onReady();
    timerController.addListener(() {
      if (timerController.value.remaining == 0) {
        // set codes to empty for TOTP with touch required
        for (var name in oathMap.keys) {
          if (oathMap[name]!.requireTouch || isMobile() && oathMap[name]!.type == OathType.totp) {
            oathMap[name]!.code = '';
          }
        }
        update();
        if (SmartCard.connectionType != ConnectionType.nfc) {
          refreshData();
        }
      }
    });
  }

  @override
  void onClose() {
    timerController.dispose();
    super.onClose();
  }

  @override
  Future<void> doRefreshData() async {
    await SmartCard.process((String sn) async {
      if (!await _authenticate(sn)) {
        return;
      }

      await _refresh();
    });
  }

  Future<void> addAccount(String name, String secretHex, OathType type, OathAlgorithm algo, int digits, bool requireTouch, int initValue) async {
    await SmartCard.process((String sn) async {
      if (!await _authenticate(sn)) {
        return;
      }

      List<int> nameBytes = utf8.encode(name);
      String capduData = '71${nameBytes.length.toRadixString(16).padLeft(2, '0')}${hex.encode(nameBytes)}'; // name 0x71
      // ignore: prefer_interpolation_to_compose_strings
      capduData += '73' + // tag
          (secretHex.length ~/ 2 + 2).toRadixString(16).padLeft(2, '0') + // length
          (type.value | algo.value).toRadixString(16).padLeft(2, '0') + // type & algo
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

      String resp = await _transceive('00010000${(capduData.length ~/ 2).toRadixString(16).padLeft(2, '0')}$capduData');
      if (resp == '6985') {
        Prompts.showPrompt(S.of(Get.context!).oathDuplicated, ContentThemeColor.danger);
        return;
      }
      SmartCard.assertOK(resp);
      log.i('Successfully added $name');

      Navigator.pop(Get.context!);
      Prompts.showPrompt(S.of(Get.context!).oathAdded, ContentThemeColor.success, forceSnackBar: true);

      await _refresh();
    });
  }

  Future<void> setCode(String newCode, bool saveCode) async {
    await SmartCard.process((String sn) async {
      String resp = await _transceive('00A4040007A0000005272101');
      SmartCard.assertOK(resp);
      if (resp == '9000') {
        log.w('Code not supported');
        return;
      } else {
        if (!await _authenticate(sn)) {
          return;
        }

        Map info = TLV.parse(hex.decode(SmartCard.dropSW(resp)));
        if (newCode.isEmpty) {
          // clear code
          resp = await _transceive('00030000027300');
        } else {
          final key = pbkdf2HmacSha1(password: newCode, salt: info[0x71], iterations: 1000, keyLen: 16);
          final mac = hmacSha1(key: key, data: List.of([0, 0, 0, 0]));
          resp = await _transceive('000300002F731101${hex.encode(key)}7404000000007514${hex.encode(mac)}');
        }

        SmartCard.assertOK(resp);
        log.i('Successfully changed code');

        _localCodeCache[sn] = newCode;
        if (saveCode) {
          await LocalStorage.setPinCache(sn, _tag, newCode);
        }

        Navigator.pop(Get.context!);
        Prompts.showPrompt(S.of(Get.context!).oathCodeChanged, ContentThemeColor.success, forceSnackBar: true);
      }
    });
  }

  Future<String> calculate(String name, OathType type) async {
    late String code;
    await SmartCard.process((String sn) async {
      if (!await _authenticate(sn)) {
        return;
      }

      List<int> nameBytes = utf8.encode(name);
      String capduData = '71${nameBytes.length.toRadixString(16).padLeft(2, '0')}${hex.encode(nameBytes)}';
      if (type == OathType.totp) {
        int challenge = DateTime.now().millisecondsSinceEpoch ~/ 30000;
        String challengeStr = challenge.toRadixString(16).padLeft(16, '0');
        capduData += '7408$challengeStr';
      }
      String resp;
      if (version == OathVersion.legacy) {
        resp = await _transceive('00040000${(capduData.length ~/ 2).toRadixString(16).padLeft(2, '0')}$capduData');
      } else {
        resp = await _transceive('00A20001${(capduData.length ~/ 2).toRadixString(16).padLeft(2, '0')}$capduData');
      }
      SmartCard.assertOK(resp);

      List<int> data = hex.decode(SmartCard.dropSW(resp));
      code = _parseResponse(data.sublist(2));
      oathMap[name]!.code = code;

      _startTimer();
      update();
    });
    return code;
  }

  Future<void> delete(String name) async {
    await SmartCard.process((String sn) async {
      if (!await _authenticate(sn)) {
        return;
      }

      List<int> nameBytes = utf8.encode(name);
      String capduData = '71${nameBytes.length.toRadixString(16).padLeft(2, '0')}${hex.encode(nameBytes)}';
      SmartCard.assertOK(await _transceive('00020000${(capduData.length ~/ 2).toRadixString(16).padLeft(2, '0')}$capduData'));
      log.i('Successfully deleted $name');

      Navigator.pop(Get.context!);
      Prompts.showPrompt(S.of(Get.context!).deleted, ContentThemeColor.success, forceSnackBar: true);
      await _refresh();
    });
  }

  Future<void> setDefault(String name, int slot, bool withEnter) async {
    await SmartCard.process((String sn) async {
      if (!await _authenticate(sn)) {
        return;
      }

      List<int> nameBytes = utf8.encode(name);
      String capduData = '71${nameBytes.length.toRadixString(16).padLeft(2, '0')}${hex.encode(nameBytes)}';
      SmartCard.assertOK(await _transceive('00550$slot${withEnter ? '01' : '00'}${(capduData.length ~/ 2).toRadixString(16).padLeft(2, '0')}$capduData'));
      log.i('Successfully changed default');

      Navigator.pop(Get.context!);
      Prompts.showPrompt(S.of(Get.context!).successfullyChanged, ContentThemeColor.success, forceSnackBar: true);
    });
  }

  void setDefaultLegacy(String name) {
    SmartCard.process((String sn) async {
      if (!await _authenticate(sn)) {
        return;
      }

      List<int> nameBytes = utf8.encode(name);
      String capduData = '71${nameBytes.length.toRadixString(16).padLeft(2, '0')}${hex.encode(nameBytes)}';
      SmartCard.assertOK(await _transceive('00550000${(capduData.length ~/ 2).toRadixString(16).padLeft(2, '0')}$capduData'));
      Prompts.showPrompt(S.of(Get.context!).successfullyChanged, ContentThemeColor.success);
    });
  }

  void parseUri(String keyUri) {
    final uri = Uri.parse(keyUri);
    if (uri.scheme != 'otpauth') {
      return;
    }
    final query = uri.queryParameters;
    if (!query.containsKey('secret')) {
      return;
    }
    final String secret = query['secret']!;
    final algorithm = query['algorithm'] ?? 'SHA1';
    if (algorithm != 'SHA1' && algorithm != 'SHA256' && algorithm != 'SHA512') {
      return;
    }
    int digits = int.parse(query['digits'] ?? '6');
    if (digits < 6 || digits > 12) {
      return;
    }
    final account = Uri.decodeComponent(uri.path.substring(1));
    final issuer = Uri.decodeComponent(query['issuer'] ?? '');
    final algo = OathAlgorithm.fromName(algorithm);
    final type = OathType.fromName(uri.host.toLowerCase());
    if (type == OathType.hotp && !query.containsKey('counter')) {
      return;
    }
    final counter = int.parse(query['counter'] ?? '0');

    qrScanResult.value = QrScanResult(issuer: issuer, account: account, secret: secret, type: type, algo: algo, digits: digits, initValue: counter);
  }

  Future<bool> _verifyCode(String code) async {
    String resp = await _transceive('00A4040007A0000005272101');
    SmartCard.assertOK(resp);
    Map info = TLV.parse(hex.decode(SmartCard.dropSW(resp)));
    if (!info.containsKey(0x74)) {
      // no code set
      return true;
    }
    List<int> nonce = info[0x71];
    List<int> challenge = info[0x74];
    final key = pbkdf2HmacSha1(password: code, salt: nonce, iterations: 1000, keyLen: 16);
    final mac = hmacSha1(key: key, data: challenge);
    resp = await _transceive('00A300001C7514${hex.encode(mac)}740400000000');
    if (resp == '6a80') {
      Prompts.showPrompt(S.of(Get.context!).pinIncorrect, ContentThemeColor.danger);
      return false;
    }
    SmartCard.assertOK(resp);
    return true;
  }

  /// Returns true if CanoKey is authenticated.
  ///
  /// We first try to use the local cache. If not cached, try LocalStorage.
  /// Finally, prompt the user for code.
  Future<bool> _authenticate(String sn) async {
    // First check if authentication is required
    String resp = await _transceive('00A4040007A0000005272101');
    SmartCard.assertOK(resp);
    if (resp == '9000') {
      version = OathVersion.legacy; // no code support
      return true;
    }
    Map info = TLV.parse(hex.decode(SmartCard.dropSW(resp)));
    if (hex.encode(info[0x79]) == '050505') {
      version = OathVersion.v1;
    } else if (hex.encode(info[0x79]) == '060000') {
      version = OathVersion.v2;
    }
    if (!info.containsKey(0x74)) {
      // no code set
      return true;
    }

    // Try local cache first
    if (_localCodeCache.containsKey(sn)) {
      if (await _verifyCode(_localCodeCache[sn]!)) {
        return true;
      }
      _localCodeCache.remove(sn);
    }

    // Try LocalStorage
    String? codeToTry = LocalStorage.getPinCache(sn, _tag);
    if (codeToTry != null) {
      if (await _verifyCode(codeToTry)) {
        _localCodeCache[sn] = codeToTry;
        return true;
      } else {
        await LocalStorage.setPinCache(sn, _tag, null);
      }
    }

    // Finally, prompt user
    // When using NFC, we need to finish NFC before showing the dialog
    SmartCard.stopPollingNfc(withInput: true);
    final completer = Completer<bool>();
    InputPinDialog.show(
      title: S.of(Get.context!).oathInputCode,
      label: S.of(Get.context!).oathCode,
      prompt: S.of(Get.context!).oathInputCodePrompt,
      showSaveOption: true,
      onSubmit: (code, saveCode) async {
        // When using NFC, we need to poll NFC again
        SmartCard.nfcState = NfcState.processWithInput;
        if (!await SmartCard.pollNfcOrWebUsb()) {
          Prompts.stopPromptAndroidPolling();
          Prompts.showPrompt(S.of(Get.context!).noCard, ContentThemeColor.warning, level: 'W');
        }
        Prompts.stopPromptAndroidPolling();
        bool verified = false;
        try {
          verified = await _verifyCode(code);
        } on PlatformException catch (e) {
          SmartCard.stopPollingNfc(withInput: true);
          log.e('_verifyCode failed', error: e);
          if (e.code == '500') {
            Prompts.showPrompt(S.of(Get.context!).interrupted, ContentThemeColor.danger);
          }
        }
        if (verified) {
          log.t('PIN verified');
          _localCodeCache[sn] = code;
          if (saveCode) {
            await LocalStorage.setPinCache(sn, _tag, code);
          }
          completer.complete(true);
          // Since PIN has been cached, if error happens, we don't need to re-prompt
          SmartCard.nfcState = NfcState.processWithoutInput;
          // Close the dialog
          Navigator.pop(Get.context!);
        }
      },
      onCancel: () async {
        SmartCard.nfcState = NfcState.idle;
        completer.complete(false);
      },
    );
    return await completer.future;
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
    bool isListCommand = (version == OathVersion.legacy && capdu.startsWith('000500')) || (version != OathVersion.legacy && capdu.startsWith('00A400'));
    if (!isListCommand) {
      return await SmartCard.transceive(capdu);
    }

    // Handle list command
    String rapdu = await SmartCard.transceive(capdu);
    String result = '';

    while (true) {
      String sw = rapdu.substring(rapdu.length - 4);
      result += SmartCard.dropSW(rapdu);

      if (sw.startsWith('61') || sw == '9000') {
        String getResponseCommand = version == OathVersion.legacy ? '00060000FF' : '00A50000FF';
        rapdu = await SmartCard.transceive(getResponseCommand);
        if (rapdu.endsWith('6985')) {
          return '${result}9000';
        }
      } else {
        return result + sw;
      }
    }
  }

  Future<void> _refresh() async {
    String resp;
    int challenge = DateTime.now().millisecondsSinceEpoch ~/ 30000;
    String challengeStr = challenge.toRadixString(16).padLeft(16, '0');
    if (version == OathVersion.legacy) {
      resp = await _transceive('000500000A7408$challengeStr');
    } else {
      resp = await _transceive('00A400010A7408$challengeStr');
    }
    SmartCard.assertOK(resp);
    List<int> data = hex.decode(SmartCard.dropSW(resp));
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

    _startTimer();
    update();
  }

  _startTimer() {
    int running = DateTime.now().millisecondsSinceEpoch ~/ 1000 % 30;
    timerController.reset();
    timerController.value = new TimerValue(remaining: 30 - running, unit: TimerUnit.second);
    timerController.start();
  }

  final List<int> _digitsPower = [1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000];

  final String _tag = 'OATH';
}
