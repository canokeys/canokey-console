import 'package:logging/logging.dart';

final log = Logger('Console:CanoKey:Model');

enum Applet {
  OpenPGP,
  PIV,
  WebAuthn,
  OATH,
  NDEF,
  PASS,
}

enum Func {
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
  resetWebAuthn,
  resetPass,
  webAuthnSm2Support,
}

enum FunctionSetVersion {
  v1, // led, hotp, ndef readonly, sig/dec/aut touch, touch cache time
  v2, // led, hotp, ndef enabled/readonly, webusb landing page
  v3, // led, hotp, ndef enabled/readonly, webusb landing page, hotp return switch
  v4, // led, ndef enabled/readonly, webusb landing page, nfc switch
}

class WebAuthnSm2Config {
  final bool enabled; // encoding as a byte, 0x01: enabled, 0x00: disabled
  final int curveId; // encoding as four bytes as big endian signed int
  final int algoId; // encoding as four bytes as big endian signed int

  WebAuthnSm2Config({required this.enabled, required this.curveId, required this.algoId});
}

class CanoKey {
  final String model;
  final String sn;
  final String chipId;
  final String firmwareVersion;
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
  WebAuthnSm2Config? webAuthnSm2Config;

  CanoKey(
      {required this.model,
      required this.sn,
      required this.chipId,
      required this.firmwareVersion,
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
      this.webAuthnSm2Config});

  Set<Func> functionSet() {
    switch (functionSetVersion) {
      case FunctionSetVersion.v1:
        return {Func.led, Func.hotp, Func.ndefReadonly, Func.sigTouch, Func.decTouch, Func.autTouch, Func.touchCacheTime};
      case FunctionSetVersion.v2:
        return {Func.led, Func.hotp, Func.webusbLandingPage, Func.ndefEnabled, Func.ndefReadonly};
      case FunctionSetVersion.v3:
        return {Func.led, Func.hotp, Func.webusbLandingPage, Func.ndefEnabled, Func.ndefReadonly, Func.keyboardWithReturn};
      case FunctionSetVersion.v4:
        return {
          Func.led,
          Func.webusbLandingPage,
          Func.ndefEnabled,
          Func.ndefReadonly,
          Func.nfcSwitch,
          Func.resetWebAuthn,
          Func.resetPass,
          Func.webAuthnSm2Support
        };
    }
  }

  static FunctionSetVersion functionSetFromFirmwareVersion(String firmwareVersion) {
    if (firmwareVersion.compareTo('1.5.') < 0) {
      log.info("Function Set: V1");
      return FunctionSetVersion.v1;
    } else if (firmwareVersion.compareTo('1.6.2') < 0) {
      log.info("Function Set: V2");
      return FunctionSetVersion.v2;
    } else if (firmwareVersion.compareTo('3.0.0') < 0) {
      log.info("Function Set: V3");
      return FunctionSetVersion.v3;
    }
    log.info("Function Set: V4");
    return FunctionSetVersion.v4;
  }

  static get pigeon => "CanoKey Pigeon";

  static get penguin => "CanoKey Penguin";
}
