import 'package:canokey_console/helper/utils/applet_switches.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:canokey_console/controller/base/admin.dart';
import 'package:canokey_console/controller/base/polling_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/app_loader_overlay.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/admin_card.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/screenshot_mode.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/models/keyboard_keymap.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class SettingsController extends PollingController with AdminApplet {
  SettingsController({AdminCardClient? client})
      : _client = client ?? AdminCardClient();

  final AdminCardClient _client;
  late CanoKey key;

  @override
  Logger get log => Logging.logger('Settings:Controller');

  @override
  Future<void> doRefreshData() async {
    log.t('Call SettingsController.doRefreshData');
    if (ScreenshotMode.enabled) {
      key = ScreenshotMode.canoKey();
      polled = true;
      update();
      return;
    }

    await SmartCard.process((String sn) async {
      if (!await authenticate(sn)) {
        return;
      }

      await _refresh(sn);
    });
  }

  Future<void> changeSwitch(Func func, bool value) =>
      changeSwitches({func: value});

  Future<void> changeSwitches(Map<Func, bool> values) async {
    log.t('Call SettingsController.changeSwitches');
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
        if (AppletSwitches.featureBits.containsKey(entry.key)) {
          featureValues[entry.key] = entry.value;
        } else {
          SmartCard.assertOK(await SmartCard.transceive(
              _changeSwitchAPDUs[entry.key]![entry.value]!));
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
    log.t('Call SettingsController.changePin');
    await SmartCard.process((String sn) async {
      if (!await authenticate(sn)) {
        return;
      }

      await _client.changePin(newPin);
      log.i('Successfully changed PIN');

      Navigator.pop(Get.context!);
      Prompts.showPrompt(
          S.of(Get.context!).pinChanged, ContentThemeColor.success,
          forceSnackBar: true);

      await updatePinCache(sn, newPin, savePin);
    });
  }

  Future<void> resetApplet(Applet applet) async {
    log.t('Call SettingsController.resetApplet');
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
    log.t('Call SettingsController.resetCanokey');
    SmartCard.process((String sn) async {
      await _client.select();
      AppLoaderOverlay.show();
      String resp = await SmartCard.transceive('00500000055245534554');
      AppLoaderOverlay.hide();
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
        Prompts.showPrompt(S.current.settingsResetFailed, ContentThemeColor.danger);
      }
    });
  }

  void changeKeyboardKeymap(KeyboardKeymapPreset preset) async {
    log.t('Call SettingsController.changeKeyboardKeymap');
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
    final firmwareVersion = await _client.readFirmwareVersion();
    String? coreCommit;
    final model = await _client.readModel();
    final chipId = await _client.readChipId();

    // read configurations
    FunctionSetVersion functionSetVersion =
        CanoKey.functionSetFromFirmwareVersion(firmwareVersion);
    final functionSet = CanoKey.functionSet(functionSetVersion);
    if (functionSetVersion == FunctionSetVersion.v5) {
      coreCommit = await _client.readCoreCommit();
    }
    final config = await _client.readConfig();
    final switches = AppletSwitchStatus.fromConfig(
      firmwareVersion: FirmwareVersion.parse(firmwareVersion),
      functionSetVersion: functionSetVersion,
      config: config,
    );
    final legacy = functionSetVersion == FunctionSetVersion.v1;
    final ledOn = config[0] == 1;
    final hotpOn = functionSetVersion.index <= FunctionSetVersion.v3.index &&
        config[1] == 1;
    final ndefReadonly = config[2] == 1;
    final ndefEnabled = !legacy && config[3] == 1;
    final webusbLandingEnabled = !legacy && config[4] == 1;
    final keyboardWithReturn =
        functionSetVersion == FunctionSetVersion.v3 && config[5] == 1;
    final sigTouch = legacy && config[3] == 1;
    final decTouch = legacy && config[4] == 1;
    final autTouch = legacy && config[5] == 1;
    final cacheTime = legacy ? config[6] : 0;
    var nfcEnabled = true;
    StorageUsage? storageUsage;
    KeyboardKeymapState? keyboardKeymap;
    if (functionSet.contains(Func.nfcSwitch)) {
      nfcEnabled = await _client.readNfcEnabled();
    }
    if (functionSet.contains(Func.dynamicOathCapacity) ||
        functionSet.contains(Func.dynamicWebAuthnCapacity)) {
      final totalUsage = await _client.readStorageUsage();
      storageUsage = StorageUsage(
        usedKiB: totalUsage.usedKiB,
        totalKiB: totalUsage.totalKiB,
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
        passEnabled: switches.passEnabled,
        openPgpCcIdEnabled: switches.openPgpUsbEnabled,
        openPgpNfcEnabled: switches.openPgpNfcEnabled,
        pivCcIdEnabled: switches.pivUsbEnabled,
        pivNfcEnabled: switches.pivNfcEnabled,
        webAuthnEnabled: switches.webAuthnEnabled,
        featureSwitchesSupported: switches.featureSwitchesSupported,
        storageUsage: storageUsage,
        keyboardKeymap: keyboardKeymap);

    polled = true;

    update();
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
    0x04: 'OTP',
    0x05: 'WebAuthn',
    0x06: 'NFC Tag',
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

  int _currentFeatureMask() => AppletSwitches.updateFeatureMask(0, {
    Func.passSwitch: key.passEnabled,
    Func.openPgpCcIdSwitch: key.openPgpCcIdEnabled,
    Func.openPgpNfcSwitch: key.openPgpNfcEnabled,
    Func.pivCcIdSwitch: key.pivCcIdEnabled,
    Func.pivNfcSwitch: key.pivNfcEnabled,
    Func.webAuthnSwitch: key.webAuthnEnabled,
  });

  String _changeFeatureSwitchesAPDU(Map<Func, bool> values) {
    final newMask =
        AppletSwitches.updateFeatureMask(_currentFeatureMask(), values);
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
