import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/models/keyboard_keymap.dart';

final log = Logging.logger('CanoKey:Model');

enum Applet {
  openpgp(resetApdu: '00030000', name: 'OpenPGP'),
  piv(resetApdu: '00040000', name: 'PIV'),
  webauthn(resetApdu: '00090000', name: 'WebAuthn'),
  oath(resetApdu: '00050000', name: 'TOTP / HOTP'),
  ndef(resetApdu: '00070000', name: 'NDEF'),
  pass(resetApdu: '00130000', name: 'Pass');

  const Applet({required this.resetApdu, required this.name});
  final String resetApdu;
  final String name;
}

enum Func {
  changeAdminPin,
  led,
  hotp,
  ndefEnabled,
  ndefReadonly,
  webusbLandingPage,
  keyboardWithReturn,
  sigTouch,
  decTouch,
  autTouch,
  touchCacheTime,
  nfcSwitch,
  resetOpenPgp,
  resetPiv,
  resetOath,
  resetNdef,
  resetWebAuthn,
  resetPass,
  factoryReset,
  webAuthnSm2Support,
  pass,
  passHmacSha1,
  keyboardKeymap,
  dynamicOathCapacity,
  dynamicWebAuthnCapacity,
  pinRetryConfig,
  passSwitch,
  openPgpCcIdSwitch,
  openPgpNfcSwitch,
  pivCcIdSwitch,
  pivNfcSwitch,
  webAuthnSwitch,
}

enum FunctionSetVersion {
  v1, // led, hotp, ndef readonly, sig/dec/aut touch, touch cache time
  v2, // led, hotp, ndef enabled/readonly, webusb landing page
  v3, // led, hotp, ndef enabled/readonly, webusb landing page, hotp return switch
  v4, // led, ndef enabled/readonly, webusb landing page, nfc switch
  v5, // CanoKey Core 3.1.0 capabilities
}

class FirmwareVersion implements Comparable<FirmwareVersion> {
  final int major;
  final int minor;
  final int patch;

  const FirmwareVersion(this.major, this.minor, this.patch);

  factory FirmwareVersion.parse(String value) {
    final match =
        RegExp(r'^(\d+)(?:\.(\d+))?(?:\.(\d+))?').firstMatch(value.trim());
    if (match == null) {
      log.w('Failed to parse firmware version: $value');
      return const FirmwareVersion(0, 0, 0);
    }
    return FirmwareVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2) ?? '0'),
      int.parse(match.group(3) ?? '0'),
    );
  }

  @override
  int compareTo(FirmwareVersion other) {
    final majorCompare = major.compareTo(other.major);
    if (majorCompare != 0) {
      return majorCompare;
    }
    final minorCompare = minor.compareTo(other.minor);
    if (minorCompare != 0) {
      return minorCompare;
    }
    return patch.compareTo(other.patch);
  }

  bool operator <(FirmwareVersion other) => compareTo(other) < 0;
}

class WebAuthnSm2Config {
  final bool enabled; // encoding as a byte, 0x01: enabled, 0x00: disabled
  final int curveId; // encoding as four bytes as big endian signed int
  final int algoId; // encoding as four bytes as big endian signed int

  WebAuthnSm2Config(
      {required this.enabled, required this.curveId, required this.algoId});
}

class StorageUsage {
  final int usedKiB;
  final int totalKiB;
  final List<AppletStorageUsage> applets;

  StorageUsage({
    required this.usedKiB,
    required this.totalKiB,
    this.applets = const [],
  });
}

class AppletStorageUsage {
  final int id;
  final String name;
  final int logicalBytes;
  final bool hasMissingSources;

  AppletStorageUsage({
    required this.id,
    required this.name,
    required this.logicalBytes,
    required this.hasMissingSources,
  });
}

class CanoKey {
  final String model;
  final String sn;
  final String chipId;
  final String firmwareVersion;
  final String? coreCommit;
  final FunctionSetVersion functionSetVersion;
  final bool ledOn;
  final bool hotpOn;
  final bool ndefReadonly;
  final bool ndefEnabled;
  final bool webusbLandingEnabled;
  final bool keyboardWithReturn;
  final bool sigTouch;
  final bool decTouch;
  final bool autTouch;
  final int touchCacheTime;
  final bool nfcEnabled;
  final bool passEnabled;
  final bool openPgpCcIdEnabled;
  final bool openPgpNfcEnabled;
  final bool pivCcIdEnabled;
  final bool pivNfcEnabled;
  final bool webAuthnEnabled;
  final bool featureSwitchesSupported;
  final StorageUsage? storageUsage;
  final KeyboardKeymapState? keyboardKeymap;
  WebAuthnSm2Config? webAuthnSm2Config;

  CanoKey(
      {required this.model,
      required this.sn,
      required this.chipId,
      required this.firmwareVersion,
      this.coreCommit,
      required this.functionSetVersion,
      required this.ledOn,
      required this.hotpOn,
      required this.ndefReadonly,
      required this.ndefEnabled,
      required this.webusbLandingEnabled,
      required this.keyboardWithReturn,
      required this.sigTouch,
      required this.decTouch,
      required this.autTouch,
      required this.touchCacheTime,
      required this.nfcEnabled,
      this.passEnabled = true,
      this.openPgpCcIdEnabled = true,
      this.openPgpNfcEnabled = true,
      this.pivCcIdEnabled = true,
      this.pivNfcEnabled = true,
      this.webAuthnEnabled = true,
      this.featureSwitchesSupported = false,
      this.storageUsage,
      this.keyboardKeymap,
      this.webAuthnSm2Config});

  Set<Func> getFunctionSet() {
    return functionSet(functionSetVersion);
  }

  bool get canChangeWebAuthnSm2Enabled =>
      functionSetVersion != FunctionSetVersion.v5;

  static Set<Func> functionSet(FunctionSetVersion functionSetVersion) {
    switch (functionSetVersion) {
      case FunctionSetVersion.v1:
        return {
          ..._baseAdminFunctions,
          Func.led,
          Func.hotp,
          Func.ndefReadonly,
          Func.resetNdef,
          Func.sigTouch,
          Func.decTouch,
          Func.autTouch,
          Func.touchCacheTime
        };
      case FunctionSetVersion.v2:
        return {
          ..._baseAdminFunctions,
          Func.led,
          Func.hotp,
          Func.webusbLandingPage,
          Func.ndefEnabled,
          Func.ndefReadonly,
          Func.resetNdef,
        };
      case FunctionSetVersion.v3:
        return {
          ..._baseAdminFunctions,
          Func.led,
          Func.hotp,
          Func.webusbLandingPage,
          Func.ndefEnabled,
          Func.ndefReadonly,
          Func.keyboardWithReturn,
          Func.resetNdef,
        };
      case FunctionSetVersion.v4:
        return {
          ..._baseAdminFunctions,
          Func.led,
          Func.webusbLandingPage,
          Func.ndefEnabled,
          Func.ndefReadonly,
          Func.resetNdef,
          Func.nfcSwitch,
          Func.resetWebAuthn,
          Func.resetPass,
          Func.webAuthnSm2Support,
          Func.pass,
        };
      case FunctionSetVersion.v5:
        return {
          ..._baseAdminFunctions,
          Func.led,
          Func.webusbLandingPage,
          Func.ndefEnabled,
          Func.ndefReadonly,
          Func.resetNdef,
          Func.nfcSwitch,
          Func.resetWebAuthn,
          Func.resetPass,
          Func.webAuthnSm2Support,
          Func.pass,
          Func.passHmacSha1,
          Func.keyboardKeymap,
          Func.dynamicOathCapacity,
          Func.dynamicWebAuthnCapacity,
          Func.pinRetryConfig,
          Func.passSwitch,
          Func.openPgpCcIdSwitch,
          Func.openPgpNfcSwitch,
          Func.pivCcIdSwitch,
          Func.pivNfcSwitch,
          Func.webAuthnSwitch,
        };
    }
  }

  static const Set<Func> _baseAdminFunctions = {
    Func.changeAdminPin,
    Func.resetOpenPgp,
    Func.resetPiv,
    Func.resetOath,
    Func.factoryReset,
  };

  static FunctionSetVersion functionSetFromFirmwareVersion(
      String firmwareVersion) {
    final version = FirmwareVersion.parse(firmwareVersion);
    if (version < const FirmwareVersion(1, 5, 0)) {
      log.i("Function Set: V1");
      return FunctionSetVersion.v1;
    } else if (version < const FirmwareVersion(1, 6, 2)) {
      log.i("Function Set: V2");
      return FunctionSetVersion.v2;
    } else if (version < const FirmwareVersion(3, 0, 0)) {
      log.i("Function Set: V3");
      return FunctionSetVersion.v3;
    } else if (version < const FirmwareVersion(3, 1, 0)) {
      log.i("Function Set: V4");
      return FunctionSetVersion.v4;
    }
    log.i("Function Set: V5");
    return FunctionSetVersion.v5;
  }

  static String get pigeon => "CanoKey Pigeon";

  static String get canary => "CanoKey Canary";
}
