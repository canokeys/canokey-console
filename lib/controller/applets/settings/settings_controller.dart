import 'package:canokey_console/src/rust/api/protocol.dart';
import 'package:canokey_console/helper/utils/applet_switches.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
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
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/helper/utils/screenshot_mode.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/models/keyboard_keymap.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class SettingsController extends PollingController with AdminApplet {
  SettingsController({AdminCardClient? client})
    : _client = client ?? AdminCardClient();

  final AdminCardClient _client;
  @override
  AdminCardClient get adminCardClient => _client;

  @override
  bool get refreshWebOnReady => false;

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

      final pin = adminPinForCurrentLease;
      final featureValues = <Func, bool>{};
      final standard = {
        Func.led,
        Func.ndefReadonly,
        Func.ndefEnabled,
        Func.webusbLandingPage,
      };
      final known = {
        ...standard,
        ...AppletSwitches.featureBits.keys,
        Func.hotp,
        Func.keyboardWithReturn,
        Func.sigTouch,
        Func.decTouch,
        Func.autTouch,
        Func.nfcSwitch,
      };
      if (values.keys.any((key) => !known.contains(key))) {
        throw ArgumentError('Unsupported Admin switch');
      }
      for (final entry in values.entries) {
        if (AppletSwitches.featureBits.containsKey(entry.key)) {
          featureValues[entry.key] = entry.value;
        }
      }
      if (values.keys.any(standard.contains) || featureValues.isNotEmpty) {
        final mask = featureValues.keys.fold(
          0,
          (mask, key) => mask | AppletSwitches.featureBits[key]!,
        );
        await _client.configure(
          pin: pin,
          ledOn: values[Func.led],
          ndefReadOnly: values[Func.ndefReadonly],
          ndefEnabled: values[Func.ndefEnabled],
          webusbLanding: values[Func.webusbLandingPage],
          featureMask: mask,
          featureValues: AppletSwitches.updateFeatureMask(0, featureValues),
        );
        await _client.prepare();
      }
      for (final entry in values.entries) {
        switch (entry.key) {
          case Func.hotp:
            await _client.setKeyboardInterface(entry.value, pin: pin);
          case Func.keyboardWithReturn:
            await _client.setKeyboardReturn(entry.value, pin: pin);
          case Func.sigTouch:
            await _client.setLegacyTouch(0, entry.value ? 1 : 0, pin: pin);
          case Func.decTouch:
            await _client.setLegacyTouch(1, entry.value ? 1 : 0, pin: pin);
          case Func.autTouch:
            await _client.setLegacyTouch(2, entry.value ? 1 : 0, pin: pin);
          case Func.nfcSwitch:
            await _client.setNfcEnabled(entry.value, pin: pin);
          default:
            continue;
        }
        // Every successful profile-affecting operation ends its own auth/target
        // sequence. Explicitly discover before the next operation, never inside it.
        await _client.prepare();
      }

      log.i(
        'Successfully changed switches: ${values.keys.map((e) => e.name).join(', ')}',
      );
      Navigator.pop(Get.context!);

      Prompts.showPrompt(
        S.of(Get.context!).successfullyChanged,
        ContentThemeColor.success,
        forceSnackBar: true,
      );
      await _refresh(sn);
    });
  }

  Future<void> changePin(String newPin, bool savePin) async {
    log.t('Call SettingsController.changePin');
    await SmartCard.process((String sn) async {
      if (!await authenticate(sn)) {
        return;
      }

      final oldPin = adminPinForCurrentLease;
      // A lost acknowledgment may mean the new PIN is already committed.
      await forgetAdminPin(sn);
      await _client.changePin(newPin, currentPin: oldPin);
      log.i('Successfully changed PIN');

      Navigator.pop(Get.context!);
      Prompts.showPrompt(
        S.of(Get.context!).pinChanged,
        ContentThemeColor.success,
        forceSnackBar: true,
      );

      await updatePinCache(sn, newPin, savePin);
    });
  }

  Future<void> resetApplet(Applet applet) async {
    log.t('Call SettingsController.resetApplet');
    await SmartCard.process((String sn) async {
      if (!await authenticate(sn)) {
        return;
      }

      // Clearing first covers committed resets with lost acknowledgments too.
      if (applet == Applet.oath) {
        await LocalStorage.setPinCache(sn, 'OATH', null);
      }
      if (applet == Applet.webauthn) {
        await LocalStorage.setPinCache(sn, 'webauthn', null);
      }
      await _client.resetApplet(applet, pin: adminPinForCurrentLease);
      log.i('Successfully reset ${applet.name}');

      Navigator.pop(Get.context!);
      Prompts.showPrompt(
        S.of(Get.context!).settingsResetSuccess,
        ContentThemeColor.success,
        forceSnackBar: true,
      );
    });
  }

  void resetCanokey() async {
    log.t('Call SettingsController.resetCanokey');
    await SmartCard.process((String sn) async {
      await _client.prepare();
      AppLoaderOverlay.show();
      int? status;
      try {
        await LocalStorage.clearPinCacheForDevice(sn);
        await _client.factoryReset();
        status = 0x9000;
      } on ProtocolException catch (error) {
        status = error.details.statusWord;
      } finally {
        AppLoaderOverlay.hide();
        await forgetAdminPin(sn);
      }
      Navigator.pop(Get.context!);
      if (status == 0x9000) {
        Prompts.showPrompt(
          S.of(Get.context!).settingsResetSuccess,
          ContentThemeColor.success,
        );
      } else if (status == 0x6985) {
        Prompts.showPrompt(
          S.of(Get.context!).settingsResetConditionNotSatisfying,
          ContentThemeColor.danger,
        );
      } else if (status == 0x6982) {
        Prompts.showPrompt(
          S.of(Get.context!).settingsResetPresenceTestFailed,
          ContentThemeColor.danger,
        );
      } else {
        Prompts.showPrompt(
          S.current.settingsResetFailed,
          ContentThemeColor.danger,
        );
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
        await _client.clearKeyboardKeymap(pin: adminPinForCurrentLease);
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
        await _client.writeKeyboardKeymap(
          id,
          entries,
          pin: adminPinForCurrentLease,
        );
      }
      log.i('Successfully changed keyboard layout');
      Navigator.pop(Get.context!);

      Prompts.showPrompt(
        S.of(Get.context!).successfullyChanged,
        ContentThemeColor.success,
        forceSnackBar: true,
      );
      await _refresh(sn);
    });
  }

  Future<void> _refresh(String sn) async {
    // Authentication already discovered and verified this lease; re-probe only
    // when writes invalidated the profile evidence.
    await _client.prepareIfStale();
    final pin = adminPinForCurrentLease;
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
    final config = await _client.readConfig(pin: pin);
    final switches = AppletSwitchStatus.fromConfig(
      firmwareVersion: FirmwareVersion.parse(firmwareVersion),
      functionSetVersion: functionSetVersion,
      config: config,
    );
    final legacy = functionSetVersion == FunctionSetVersion.v1;
    final ledOn = config[0] == 1;
    final hotpOn =
        functionSetVersion.index <= FunctionSetVersion.v3.index &&
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
      nfcEnabled = await _client.readNfcEnabled(pin: pin);
    }
    if (functionSet.contains(Func.dynamicOathCapacity) ||
        functionSet.contains(Func.dynamicWebAuthnCapacity)) {
      final totalUsage = await _client.readStorageUsage(pin: pin);
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
      keyboardKeymap = await _readKeyboardKeymap(pin);
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
      keyboardKeymap: keyboardKeymap,
    );

    polled = true;

    update();
  }

  Future<List<AppletStorageUsage>> _tryReadAppletStorageUsage(
    Set<Func> functionSet,
  ) async {
    List<AdminAppletUsage> data;
    try {
      data = await _client.readAppletStorageUsage();
    } on ProtocolException catch (error) {
      if (error.details.kind == 'UnsupportedFeature') return [];
      rethrow;
    }

    final usages = <AppletStorageUsage>[];
    for (final entry in data) {
      final id = entry.appletId;
      final name = _appletUsageNames[id];
      if (name == null || !_hasAppletStorageUsage(id, functionSet)) {
        continue;
      }
      usages.add(
        AppletStorageUsage(
          id: id,
          name: name,
          logicalBytes: entry.logicalBytes,
          hasMissingSources: entry.flags & 0x01 != 0,
        ),
      );
    }
    return usages;
  }

  Future<KeyboardKeymapState> _readKeyboardKeymap(String pin) async {
    final int? layoutId;
    try {
      layoutId = await _client.readKeyboardLayout(pin: pin);
    } on ProtocolException catch (error) {
      if (error.details.kind == 'NotFound') {
        return const KeyboardKeymapState(
          layoutId: null,
          entries: null,
          preset: KeyboardKeymapPresets.defaultPreset,
          isDefault: true,
        );
      }
      // A one-off read failure degrades the keymap UI instead of failing the
      // whole settings refresh.
      log.w('Failed to read keyboard layout id', error: error);
      return const KeyboardKeymapState(
        layoutId: null,
        entries: null,
        preset: null,
        isDefault: false,
      );
    }
    final Uint8List entries;
    try {
      entries = await _client.readKeyboardKeymap(pin: pin);
    } on ProtocolException catch (error) {
      log.w('Failed to read keyboard keymap', error: error);
      return KeyboardKeymapState(
        layoutId: layoutId,
        entries: null,
        preset: KeyboardKeymapPresets.findById(layoutId),
        isDefault: false,
      );
    }
    return KeyboardKeymapState(
      layoutId: layoutId,
      entries: entries,
      preset: KeyboardKeymapPresets.findMatching(layoutId, entries),
      isDefault: false,
    );
  }

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
}
