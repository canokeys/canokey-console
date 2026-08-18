import 'dart:async';
import 'dart:typed_data';

import 'package:canokey_console/controller/base/admin.dart';
import 'package:canokey_console/controller/base/polling_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/models/keyboard_keymap.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:logger/logger.dart';

class SettingsController extends PollingController with AdminApplet {
  late CanoKey key;

  @override
  Logger get log => Logging.logger('Settings:Controller');

  @override
  Future<void> doRefreshData() async {
    await SmartCard.process((String sn) async {
      if (!await authenticate(sn)) {
        return;
      }

      await _refresh(sn);
    });
  }

  void changeSwitch(Func func, bool value) async {
    await SmartCard.process((String sn) async {
      if (!await authenticate(sn)) {
        return;
      }

      SmartCard.assertOK(
          await SmartCard.transceive(_changeSwitchAPDU(func, value)));
      log.i('Successfully changed ${func.name}');
      Navigator.pop(Get.context!);

      Prompts.showPrompt(
          S.of(Get.context!).successfullyChanged, ContentThemeColor.success,
          forceSnackBar: true);
      await _refresh(sn);
    });
  }

  Future<void> changeSwitches(Map<Func, bool> values) async {
    if (values.isEmpty) {
      Navigator.pop(Get.context!);
      return;
    }

    await SmartCard.process((String sn) async {
      if (!await authenticate(sn)) {
        return;
      }

      final featureValues = <Func, bool>{};
      for (final entry in values.entries) {
        if (_featureSwitchBits.containsKey(entry.key)) {
          featureValues[entry.key] = entry.value;
        } else {
          SmartCard.assertOK(await SmartCard.transceive(
              _changeSwitchAPDU(entry.key, entry.value)));
        }
      }

      if (featureValues.isNotEmpty) {
        SmartCard.assertOK(await SmartCard.transceive(
            _changeFeatureSwitchesAPDU(featureValues)));
      }

      log.i(
          'Successfully changed switches: ${values.keys.map((e) => e.name).join(', ')}');
      Navigator.pop(Get.context!);

      Prompts.showPrompt(
          S.of(Get.context!).successfullyChanged, ContentThemeColor.success,
          forceSnackBar: true);
      await _refresh(sn);
    });
  }

  Future<void> changePin(String newPin, bool savePin) async {
    await SmartCard.process((String sn) async {
      if (!await authenticate(sn)) {
        return;
      }

      SmartCard.assertOK(await SmartCard.transceive(
          '00210000${newPin.length.toRadixString(16).padLeft(2, '0')}${hex.encode(newPin.codeUnits)}'));
      log.i('Successfully changed PIN');

      Navigator.pop(Get.context!);
      Prompts.showPrompt(
          S.of(Get.context!).pinChanged, ContentThemeColor.success,
          forceSnackBar: true);

      await updatePinCache(sn, newPin, savePin);
    });
  }

  Future<void> resetApplet(Applet applet) async {
    await SmartCard.process((String sn) async {
      if (!await authenticate(sn)) {
        return;
      }

      SmartCard.assertOK(await SmartCard.transceive(applet.resetApdu));
      log.i('Successfully reset ${applet.name}');

      Navigator.pop(Get.context!);
      Prompts.showPrompt(
          S.of(Get.context!).settingsResetSuccess, ContentThemeColor.success,
          forceSnackBar: true);
    });
  }

  void resetCanokey() {
    SmartCard.process((String sn) async {
      SmartCard.assertOK(await SmartCard.transceive('00A4040005F000000000'));
      Get.context!.loaderOverlay.show();
      String resp = await SmartCard.transceive('00500000055245534554');
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

  void changeKeyboardKeymap(KeyboardKeymapPreset preset) async {
    await SmartCard.process((String sn) async {
      if (!await authenticate(sn)) {
        return;
      }

      if (preset.isDefault) {
        SmartCard.assertOK(await SmartCard.transceive('00470000'));
      } else {
        final entries = preset.entries;
        final id = preset.id;
        if (entries == null || id == null) {
          throw Exception('Invalid keyboard layout preset');
        }
        final validationError = KeyboardKeymapPresets.validateEntries(entries);
        if (validationError != null) {
          throw Exception(validationError);
        }
        SmartCard.assertOK(await SmartCard.transceive(
            '004500${id.toRadixString(16).padLeft(2, '0')}000100${hex.encode(entries)}'));
      }
      log.i('Successfully changed keyboard layout');
      Navigator.pop(Get.context!);

      Prompts.showPrompt(
          S.of(Get.context!).successfullyChanged, ContentThemeColor.success,
          forceSnackBar: true);
      await _refresh(sn);
    });
  }

  Future<void> _refresh(String sn) async {
    String resp = await SmartCard.transceive('0031000000');
    SmartCard.assertOK(resp);
    String firmwareVersion =
        String.fromCharCodes(hex.decode(SmartCard.dropSW(resp)));
    String? coreCommit;
    resp = await SmartCard.transceive('0031010000');
    SmartCard.assertOK(resp);
    String model = String.fromCharCodes(hex.decode(SmartCard.dropSW(resp)));
    resp = await SmartCard.transceive('0032010000');
    SmartCard.assertOK(resp);
    String chipId = SmartCard.dropSW(resp).toUpperCase();

    // read configurations
    FunctionSetVersion functionSetVersion =
        CanoKey.functionSetFromFirmwareVersion(firmwareVersion);
    final functionSet = CanoKey.functionSet(functionSetVersion);
    if (functionSetVersion == FunctionSetVersion.v5) {
      coreCommit = await _tryReadCoreCommit();
    }
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
    bool passEnabled = true;
    bool openPgpCcIdEnabled = true;
    bool openPgpNfcEnabled = true;
    bool pivCcIdEnabled = true;
    bool pivNfcEnabled = true;
    bool webAuthnEnabled = true;
    bool featureSwitchesSupported = false;
    StorageUsage? storageUsage;
    KeyboardKeymapState? keyboardKeymap;
    resp = await SmartCard.transceive('0042000000');
    SmartCard.assertOK(resp);
    final configData = SmartCard.dropSW(resp);
    switch (functionSetVersion) {
      case FunctionSetVersion.v1:
        ledOn = configData.substring(0, 2) == '01';
        hotpOn = configData.substring(2, 4) == '01';
        ndefReadonly = configData.substring(4, 6) == '01';
        sigTouch = configData.substring(6, 8) == '01';
        decTouch = configData.substring(8, 10) == '01';
        autTouch = configData.substring(10, 12) == '01';
        cacheTime = int.parse(configData.substring(12, 14), radix: 16);
        break;
      case FunctionSetVersion.v2:
        ledOn = configData.substring(0, 2) == '01';
        hotpOn = configData.substring(2, 4) == '01';
        ndefReadonly = configData.substring(4, 6) == '01';
        ndefEnabled = configData.substring(6, 8) == '01';
        webusbLandingEnabled = configData.substring(8, 10) == '01';
        break;
      case FunctionSetVersion.v3:
        ledOn = configData.substring(0, 2) == '01';
        hotpOn = configData.substring(2, 4) == '01';
        ndefReadonly = configData.substring(4, 6) == '01';
        ndefEnabled = configData.substring(6, 8) == '01';
        webusbLandingEnabled = configData.substring(8, 10) == '01';
        keyboardWithReturn = configData.substring(10, 12) == '01';
        break;
      case FunctionSetVersion.v4:
        ledOn = configData.substring(0, 2) == '01';
        ndefReadonly = configData.substring(4, 6) == '01';
        ndefEnabled = configData.substring(6, 8) == '01';
        webusbLandingEnabled = configData.substring(8, 10) == '01';
        break;
      case FunctionSetVersion.v5:
        ledOn = configData.substring(0, 2) == '01';
        ndefReadonly = configData.substring(4, 6) == '01';
        ndefEnabled = configData.substring(6, 8) == '01';
        webusbLandingEnabled = configData.substring(8, 10) == '01';
        if (configData.length >= 12) {
          featureSwitchesSupported = true;
          final featureMask =
              int.parse(configData.substring(10, 12), radix: 16);
          passEnabled = featureMask & _featurePass != 0;
          openPgpCcIdEnabled = featureMask & _featureOpenPgpCcId != 0;
          openPgpNfcEnabled = featureMask & _featureOpenPgpNfc != 0;
          pivCcIdEnabled = featureMask & _featurePivCcId != 0;
          pivNfcEnabled = featureMask & _featurePivNfc != 0;
          webAuthnEnabled = featureMask & _featureWebAuthn != 0;
        }
        break;
    }
    if (functionSet.contains(Func.nfcSwitch)) {
      resp = await SmartCard.transceive('0014000000');
      SmartCard.assertOK(resp);
      nfcEnabled = resp.substring(0, 2) == '01';
    }
    if (functionSet.contains(Func.dynamicOathCapacity) ||
        functionSet.contains(Func.dynamicWebAuthnCapacity)) {
      resp = await SmartCard.transceive('0041000002');
      SmartCard.assertOK(resp);
      final totalUsage = SmartCard.dropSW(resp);
      storageUsage = StorageUsage(
        usedKiB: int.parse(totalUsage.substring(0, 2), radix: 16),
        totalKiB: int.parse(totalUsage.substring(2, 4), radix: 16),
      );
      final appletUsage = await _tryReadAppletStorageUsage(functionSet);
      if (appletUsage.isNotEmpty) {
        storageUsage = StorageUsage(
          usedKiB: storageUsage.usedKiB,
          totalKiB: storageUsage.totalKiB,
          applets: appletUsage,
        );
      }
    }
    if (functionSet.contains(Func.keyboardKeymap)) {
      keyboardKeymap = await _tryReadKeyboardKeymap();
    }

    key = CanoKey(
        model: model,
        sn: sn,
        chipId: chipId,
        firmwareVersion: firmwareVersion,
        coreCommit: coreCommit,
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
        nfcEnabled: nfcEnabled,
        passEnabled: passEnabled,
        openPgpCcIdEnabled: openPgpCcIdEnabled,
        openPgpNfcEnabled: openPgpNfcEnabled,
        pivCcIdEnabled: pivCcIdEnabled,
        pivNfcEnabled: pivNfcEnabled,
        webAuthnEnabled: webAuthnEnabled,
        featureSwitchesSupported: featureSwitchesSupported,
        storageUsage: storageUsage,
        keyboardKeymap: keyboardKeymap);

    polled = true;

    update();
  }

  Future<String?> _tryReadCoreCommit() async {
    final resp = await SmartCard.transceive('0031020000');
    if (!SmartCard.isOK(resp)) {
      log.w('Failed to read canokey-core commit: $resp');
      return null;
    }
    final data = SmartCard.dropSW(resp);
    if (data.isEmpty) {
      return null;
    }
    return String.fromCharCodes(hex.decode(data));
  }

  Future<List<AppletStorageUsage>> _tryReadAppletStorageUsage(
      Set<Func> functionSet) async {
    final resp = await SmartCard.transceive('0041010030');
    if (!SmartCard.isOK(resp)) {
      log.w('Failed to read applet flash usage: $resp');
      return [];
    }

    final data = SmartCard.dropSW(resp);
    if (data.length < _appletUsageMinResponseLengthHex ||
        data.length % _appletUsageRecordLengthHex != 0) {
      log.w('Invalid applet flash usage length: ${data.length ~/ 2}');
      return [];
    }

    final usages = <AppletStorageUsage>[];
    final recordCount = data.length ~/ _appletUsageRecordLengthHex;
    for (var i = 0; i < recordCount; i++) {
      final offset = i * _appletUsageRecordLengthHex;
      final id = int.parse(data.substring(offset, offset + 2), radix: 16);
      final flags =
          int.parse(data.substring(offset + 2, offset + 4), radix: 16);
      final name = _appletUsageNames[id];
      if (name == null || !_hasAppletStorageUsage(id, functionSet)) {
        continue;
      }
      usages.add(AppletStorageUsage(
        id: id,
        name: name,
        logicalBytes:
            int.parse(data.substring(offset + 4, offset + 12), radix: 16),
        hasMissingSources: flags & 0x01 != 0,
      ));
    }
    return usages;
  }

  Future<KeyboardKeymapState> _tryReadKeyboardKeymap() async {
    var resp = await SmartCard.transceive('0046000001');
    if (SmartCard.sw(resp) == '6A88') {
      return const KeyboardKeymapState(
        layoutId: null,
        entries: null,
        preset: KeyboardKeymapPresets.defaultPreset,
        isDefault: true,
      );
    }
    if (!SmartCard.isOK(resp)) {
      log.w('Failed to read keyboard layout id: $resp');
      return const KeyboardKeymapState(
        layoutId: null,
        entries: null,
        preset: null,
        isDefault: false,
      );
    }
    final layoutId = int.parse(SmartCard.dropSW(resp), radix: 16);

    resp = await SmartCard.transceive('0046000100');
    if (!SmartCard.isOK(resp)) {
      log.w('Failed to read keyboard keymap: $resp');
      return KeyboardKeymapState(
        layoutId: layoutId,
        entries: null,
        preset: KeyboardKeymapPresets.findById(layoutId),
        isDefault: false,
      );
    }

    final entries = Uint8List.fromList(hex.decode(SmartCard.dropSW(resp)));
    final preset = KeyboardKeymapPresets.findMatching(layoutId, entries);
    return KeyboardKeymapState(
      layoutId: layoutId,
      entries: entries,
      preset: preset,
      isDefault: false,
    );
  }

  static const int _appletUsageRecordLengthBytes = 6;
  static const int _appletUsageRecordLengthHex =
      _appletUsageRecordLengthBytes * 2;
  static const int _appletUsageMinRecordCount = 7;
  static const int _appletUsageMinResponseLengthHex =
      _appletUsageRecordLengthHex * _appletUsageMinRecordCount;

  static const Map<int, String> _appletUsageNames = {
    0x00: 'System',
    0x01: 'Admin',
    0x02: 'OpenPGP',
    0x03: 'PIV',
    0x04: 'TOTP / HOTP',
    0x05: 'WebAuthn',
    0x06: 'NDEF',
    0x07: 'Pass',
  };

  bool _hasAppletStorageUsage(int id, Set<Func> functionSet) {
    switch (id) {
      case 0x00: // System
      case 0x01: // Admin
      case 0x02: // OpenPGP
      case 0x03: // PIV
      case 0x04: // OATH
      case 0x05: // CTAP / WebAuthn
        return true;
      case 0x06: // NDEF
        return functionSet.contains(Func.ndefEnabled) ||
            functionSet.contains(Func.ndefReadonly) ||
            functionSet.contains(Func.resetNdef);
      case 0x07: // Pass
        return functionSet.contains(Func.pass);
      default:
        return false;
    }
  }

  static const int _featurePass = 1 << 0;
  static const int _featureOpenPgpCcId = 1 << 1;
  static const int _featureOpenPgpNfc = 1 << 2;
  static const int _featurePivCcId = 1 << 3;
  static const int _featurePivNfc = 1 << 4;
  static const int _featureWebAuthn = 1 << 5;

  static const Map<Func, int> _featureSwitchBits = {
    Func.passSwitch: _featurePass,
    Func.openPgpCcIdSwitch: _featureOpenPgpCcId,
    Func.openPgpNfcSwitch: _featureOpenPgpNfc,
    Func.pivCcIdSwitch: _featurePivCcId,
    Func.pivNfcSwitch: _featurePivNfc,
    Func.webAuthnSwitch: _featureWebAuthn,
  };

  int _currentFeatureMask() {
    return (key.passEnabled ? _featurePass : 0) |
        (key.openPgpCcIdEnabled ? _featureOpenPgpCcId : 0) |
        (key.openPgpNfcEnabled ? _featureOpenPgpNfc : 0) |
        (key.pivCcIdEnabled ? _featurePivCcId : 0) |
        (key.pivNfcEnabled ? _featurePivNfc : 0) |
        (key.webAuthnEnabled ? _featureWebAuthn : 0);
  }

  String _changeSwitchAPDU(Func func, bool value) {
    final featureBit = _featureSwitchBits[func];
    if (featureBit != null) {
      final currentMask = _currentFeatureMask();
      final newMask =
          value ? currentMask | featureBit : currentMask & ~featureBit;
      return '004006${newMask.toRadixString(16).padLeft(2, '0')}';
    }
    return _changeSwitchAPDUs[func]![value]!;
  }

  String _changeFeatureSwitchesAPDU(Map<Func, bool> values) {
    var newMask = _currentFeatureMask();
    for (final entry in values.entries) {
      final bit = _featureSwitchBits[entry.key]!;
      newMask = entry.value ? newMask | bit : newMask & ~bit;
    }
    return '004006${newMask.toRadixString(16).padLeft(2, '0')}';
  }

  final Map<Func, Map<bool, String>> _changeSwitchAPDUs = {
    Func.led: {true: '00400101', false: '00400100'},
    Func.hotp: {true: '00400301', false: '00400300'},
    Func.ndefEnabled: {true: '00400401', false: '00400400'},
    Func.ndefReadonly: {true: '00080100', false: '00080000'},
    Func.webusbLandingPage: {true: '00400501', false: '00400500'},
    Func.keyboardWithReturn: {true: '00400601', false: '00400600'},
    Func.sigTouch: {true: '00090001', false: '00090000'},
    Func.decTouch: {true: '00090101', false: '00090100'},
    Func.autTouch: {true: '00090201', false: '00090200'},
    Func.nfcSwitch: {true: '00140101', false: '00140100'},
  };
}
