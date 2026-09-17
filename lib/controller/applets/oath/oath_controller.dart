import 'dart:async';

import 'package:canokey_console/controller/applets/oath/qr_scan_result.dart';
import 'package:canokey_console/controller/base/polling_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/oath_card.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/widgets/input_pin_dialog.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:platform_detector/platform_detector.dart';
import 'package:timer_controller/timer_controller.dart';

class OathController extends PollingController {
  final OathCardClient _client = OathCardClient();
  final TimerController timerController = TimerController.seconds(30);
  final Rxn<QrScanResult> qrScanResult = Rxn<QrScanResult>();
  final _localCodeCache = CredentialCache('OATH');
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
          if (oathMap[name]!.requireTouch ||
              isMobile() && oathMap[name]!.type == OathType.totp) {
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
    _client.cancelPendingOperations();
    timerController.dispose();
    super.onClose();
  }

  @override
  Future<void> doRefreshData() async {
    log.t('Call OathController.doRefreshData');
    await SmartCard.process((String sn) async {
      final (authenticated, key) = await _authenticate(sn);
      try {
        if (!authenticated) {
          return;
        }

        await _refresh(key);
      } finally {
        key?.fillRange(0, key.length, 0);
      }
    });
  }

  Future<void> addAccount(String name, String secretHex, OathType type,
      OathAlgorithm algo, int digits, bool requireTouch, int initValue) async {
    log.t('Call OathController.addAccount');
    await SmartCard.process((String sn) async {
      final (authenticated, key) = await _authenticate(sn);
      try {
        if (!authenticated) {
          return;
        }

        try {
          await _client.put(
            name: name,
            secretHex: secretHex,
            type: type,
            algorithm: algo,
            digits: digits,
            requireTouch: requireTouch,
            initialValue: initValue,
            key: key,
          );
        } on ProtocolException catch (e) {
          if (e.details.statusWord == 0x6985) {
            Prompts.showPrompt(
                S.of(Get.context!).oathDuplicated, ContentThemeColor.danger);
            return;
          }
          final sw = _client.lastStatusWord;
          if (sw != null && Prompts.isStorageFull(sw)) {
            Prompts.showPrompt(
                S.of(Get.context!).storageFull, ContentThemeColor.danger);
            return;
          }
          rethrow;
        }
        log.i('Successfully added $name');

        Navigator.pop(Get.context!);
        Prompts.showPrompt(
            S.of(Get.context!).oathAdded, ContentThemeColor.success,
            forceSnackBar: true);

        await _refresh(key);
      } finally {
        key?.fillRange(0, key.length, 0);
      }
    });
  }

  Future<void> setCode(String newCode, bool saveCode) async {
    log.t('Call OathController.setCode');
    await SmartCard.process((String sn) async {
      await _client.prepare();
      final selection = await _client.select();
      version = selection.version;
      if (version == OathVersion.legacy) {
        log.w('Code not supported');
        return;
      }
      final salt = selection.salt!;
      Uint8List? oldKey;
      if (selection.requiresCode) {
        final (authenticated, key) = await _authenticate(sn);
        if (!authenticated) {
          return;
        }
        oldKey = key;
      }

      try {
        if (newCode.isEmpty) {
          await _client.clearCode(key: oldKey);
        } else {
          final newKey = OathCardClient.deriveKey(newCode, salt);
          try {
            await _client.setCode(newKey: newKey, oldKey: oldKey);
          } finally {
            newKey.fillRange(0, newKey.length, 0);
          }
        }
      } finally {
        oldKey?.fillRange(0, oldKey.length, 0);
      }
      log.i('Successfully changed code');

      // Drop any stale persisted code first; this also bumps the credential
      // generation so page-level CredentialCache copies are invalidated.
      await LocalStorage.setPinCache(sn, _tag, null);
      _localCodeCache[sn] = newCode;
      if (saveCode) {
        await LocalStorage.setPinCache(sn, _tag, newCode);
      }

      Navigator.pop(Get.context!);
      Prompts.showPrompt(
          S.of(Get.context!).oathCodeChanged, ContentThemeColor.success,
          forceSnackBar: true);
    });
  }

  Future<String> calculate(String name, OathType type) async {
    log.t('Call OathController.calculate');
    String code = '';
    await SmartCard.process((String sn) async {
      final (authenticated, key) = await _authenticate(sn);
      try {
        if (!authenticated) {
          return;
        }

        String? challengeHex;
        if (type == OathType.totp) {
          int challenge = DateTime.now().millisecondsSinceEpoch ~/ 30000;
          challengeHex = challenge.toRadixString(16).padLeft(16, '0');
        }
        final (digits, rawCode) = await _client.calculate(
          name: name,
          type: type,
          challengeHex: challengeHex,
          key: key,
        );
        code = formatOathCode(
            rawCode: rawCode, digits: digits, format: oathMap[name]!.format);
        oathMap[name]!.code = code;

        _startTimer();
        update();
      } finally {
        key?.fillRange(0, key.length, 0);
      }
    });
    return code;
  }

  Future<void> delete(String name) async {
    log.t('Call OathController.delete');
    await SmartCard.process((String sn) async {
      final (authenticated, key) = await _authenticate(sn);
      try {
        if (!authenticated) {
          return;
        }

        await _client.delete(name, key: key);
        log.i('Successfully deleted $name');

        Navigator.pop(Get.context!);
        Prompts.showPrompt(
            S.of(Get.context!).deleted, ContentThemeColor.success,
            forceSnackBar: true);
        await _refresh(key);
      } finally {
        key?.fillRange(0, key.length, 0);
      }
    });
  }

  Future<void> setDefault(String name, int slot, bool withEnter) async {
    log.t('Call OathController.setDefault');
    await SmartCard.process((String sn) async {
      final (authenticated, key) = await _authenticate(sn);
      try {
        if (!authenticated) {
          return;
        }

        try {
          // The dialog numbers slots from 1; the protocol numbers from 0.
          await _client.setDefault(
            name: name,
            slot: slot - 1,
            appendEnter: withEnter,
            key: key,
          );
        } on ProtocolException catch (e) {
          // Legacy single-slot firmware rejects a long slot or an appended
          // Enter before any I/O; the nameless 6984 reply maps to NotFound.
          if (e.details.kind == 'InvalidArgument' &&
              e.details.phase == 'Construction') {
            Prompts.showPrompt(
                S.of(Get.context!).notSupported, ContentThemeColor.warning);
            return;
          }
          if (e.details.kind == 'NotFound') {
            Prompts.showPrompt(
                S.of(Get.context!).operationFailed, ContentThemeColor.danger);
            return;
          }
          rethrow;
        }
        log.i('Successfully changed default');

        Navigator.pop(Get.context!);
        Prompts.showPrompt(
            S.of(Get.context!).successfullyChanged, ContentThemeColor.success,
            forceSnackBar: true);
      } finally {
        key?.fillRange(0, key.length, 0);
      }
    });
  }

  void parseUri(String keyUri) {
    log.t('Call OathController.parseUri');
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
    final issuer = Uri.decodeComponent(query['issuer'] ?? '');
    final label = Uri.decodeComponent(uri.path.substring(1));
    final account = issuer.isNotEmpty && label.startsWith('$issuer:')
        ? label.substring(issuer.length + 1)
        : label;
    final isSteam = OathCodeFormat.fromIssuer(issuer) == OathCodeFormat.steam;
    int digits = int.parse(query['digits'] ?? '6');
    if ((!isSteam && digits < 6) || digits > 12) {
      return;
    }
    if (isSteam) {
      digits = 6;
    }
    final algo = OathAlgorithm.fromName(algorithm);
    final type = OathType.fromName(uri.host.toLowerCase());
    if (type == OathType.hotp && !query.containsKey('counter')) {
      return;
    }
    final counter = int.parse(query['counter'] ?? '0');

    qrScanResult.value = QrScanResult(
        issuer: issuer,
        account: account,
        secret: secret,
        type: type,
        algo: algo,
        digits: digits,
        initValue: counter);
  }

  /// Validate a candidate code against the card. An incorrect code returns
  /// null; protocol and transport failures propagate. When [report] is true,
  /// an incorrect code also shows a pinIncorrect prompt — silent candidates
  /// (caches tried before prompting the user) pass false.
  Future<Uint8List?> _verifyCode(String code, List<int> salt,
      {bool report = true}) async {
    final key = OathCardClient.deriveKey(code, salt);
    try {
      await _client.validate(key);
      return key;
    } on ProtocolException catch (e) {
      key.fillRange(0, key.length, 0);
      if (e.details.kind == 'AuthenticationFailed' ||
          e.details.kind == 'DeviceAuthenticationFailed') {
        if (report) {
          Prompts.showPrompt(
              S.of(Get.context!).pinIncorrect, ContentThemeColor.danger);
        }
        return null;
      }
      rethrow;
    }
  }

  /// Prepares and selects the applet, then returns the validated access key
  /// for this use case, or null when the applet requires no code.
  /// `(false, null)` means the user cancelled or no candidate matched.
  ///
  /// We first try to use the local cache. If not cached, try LocalStorage.
  /// Finally, prompt the user for code.
  Future<(bool, Uint8List?)> _authenticate(String sn) async {
    // First check if authentication is required
    await _client.prepare();
    final selection = await _client.select();
    version = selection.version;
    if (version == OathVersion.legacy || !selection.requiresCode) {
      return (true, null);
    }
    final salt = selection.salt!;

    // Try local cache first
    if (_localCodeCache.containsKey(sn)) {
      final key = await _verifyCode(_localCodeCache[sn]!, salt, report: false);
      if (key != null) {
        return (true, key);
      }
      _localCodeCache.remove(sn);
    }

    // Try LocalStorage
    String? codeToTry = LocalStorage.getPinCache(sn, _tag);
    if (codeToTry != null) {
      final key = await _verifyCode(codeToTry, salt, report: false);
      if (key != null) {
        _localCodeCache[sn] = codeToTry;
        return (true, key);
      } else {
        await LocalStorage.setPinCache(sn, _tag, null);
      }
    }

    // Finally, prompt user
    // When using NFC, we need to finish NFC before showing the dialog
    await SmartCard.stopPollingNfc(withInput: true);
    final completer = Completer<(bool, Uint8List?)>();
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
          Prompts.showPrompt(
              S.of(Get.context!).noCard, ContentThemeColor.warning,
              level: 'W');
          return;
        }
        Prompts.stopPromptAndroidPolling();
        Uint8List? key;
        try {
          // The poll above bound a new lease; rediscover before validating.
          await _client.prepare();
          key = await _verifyCode(code, salt);
        } on ProtocolException catch (e) {
          await SmartCard.stopPollingNfc(withInput: true);
          log.e('_verifyCode failed', error: e);
          Prompts.showPrompt(
              S.of(Get.context!).operationFailed, ContentThemeColor.danger);
        } on StateError catch (e) {
          await SmartCard.stopPollingNfc(withInput: true);
          log.e('_verifyCode failed', error: e);
          Prompts.showPrompt(
              S.of(Get.context!).operationFailed, ContentThemeColor.danger);
        } on PlatformException catch (e) {
          await SmartCard.stopPollingNfc(withInput: true);
          log.e('_verifyCode failed', error: e);
          if (e.code == '500') {
            Prompts.showPrompt(
                S.of(Get.context!).interrupted, ContentThemeColor.danger);
          }
        }
        if (key != null) {
          log.t('PIN verified');
          _localCodeCache[sn] = code;
          if (saveCode) {
            await LocalStorage.setPinCache(sn, _tag, code);
          }
          if (!completer.isCompleted) {
            completer.complete((true, key));
          }
          // Since PIN has been cached, if error happens, we don't need to re-prompt
          SmartCard.nfcState = NfcState.processWithoutInput;
          // Close the dialog
          Navigator.pop(Get.context!);
        }
      },
      onCancel: () async {
        SmartCard.nfcState = NfcState.idle;
        if (!completer.isCompleted) {
          completer.complete((false, null));
        }
      },
    );
    return await completer.future;
  }

  OathItem _itemOf(OathCalculatedEntry entry) {
    final name = entry.name!;
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
    if (entry.isHotp) {
      item.type = OathType.hotp;
    }
    if (entry.requiresTouch) {
      item.requireTouch = true;
    }
    final rawCode = entry.rawCode;
    if (rawCode != null) {
      item.code = formatOathCode(
          rawCode: rawCode, digits: entry.digits, format: item.format);
    }
    return item;
  }

  Future<void> _refresh(Uint8List? key) async {
    int challenge = DateTime.now().millisecondsSinceEpoch ~/ 30000;
    String challengeStr = challenge.toRadixString(16).padLeft(16, '0');
    final entries = await _client.calculateAll(challengeStr, key: key);
    polled = true;

    var items = entries.map(_itemOf).toList();
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

  void _startTimer() {
    int running = DateTime.now().millisecondsSinceEpoch ~/ 1000 % 30;
    timerController.reset();
    timerController.value =
        new TimerValue(remaining: 30 - running, unit: TimerUnit.second);
    timerController.start();
  }

  final String _tag = 'OATH';
}
