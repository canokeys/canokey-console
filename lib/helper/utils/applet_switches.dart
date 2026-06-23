import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:convert/convert.dart';
import 'package:get/get.dart';

class AppletSwitchStatus {
  final FunctionSetVersion functionSetVersion;
  final Set<Func> functionSet;
  final bool featureSwitchesSupported;
  final bool passEnabled;
  final bool openPgpUsbEnabled;
  final bool openPgpNfcEnabled;
  final bool pivUsbEnabled;
  final bool pivNfcEnabled;
  final bool webAuthnEnabled;

  const AppletSwitchStatus({
    required this.functionSetVersion,
    required this.functionSet,
    required this.featureSwitchesSupported,
    required this.passEnabled,
    required this.openPgpUsbEnabled,
    required this.openPgpNfcEnabled,
    required this.pivUsbEnabled,
    required this.pivNfcEnabled,
    required this.webAuthnEnabled,
  });

  bool get supportsNfc => functionSet.contains(Func.nfcSwitch);

  bool get openPgpEnabled =>
      SmartCard.connectionType == ConnectionType.nfc && supportsNfc
          ? openPgpNfcEnabled
          : openPgpUsbEnabled;

  bool get pivEnabled =>
      SmartCard.connectionType == ConnectionType.nfc && supportsNfc
          ? pivNfcEnabled
          : pivUsbEnabled;
}

class AppletSwitches {
  static const int _featurePass = 1 << 0;
  static const int _featureOpenPgpUsb = 1 << 1;
  static const int _featureOpenPgpNfc = 1 << 2;
  static const int _featurePivUsb = 1 << 3;
  static const int _featurePivNfc = 1 << 4;
  static const int _featureWebAuthn = 1 << 5;

  static Future<AppletSwitchStatus> readStatus() async {
    SmartCard.assertOK(await SmartCard.transceive('00A4040005F000000000'));

    final firmwareResp = await SmartCard.transceive('0031000000');
    SmartCard.assertOK(firmwareResp);
    final firmwareVersion =
        String.fromCharCodes(hex.decode(SmartCard.dropSW(firmwareResp)));
    final functionSetVersion =
        CanoKey.functionSetFromFirmwareVersion(firmwareVersion);
    final functionSet = CanoKey.functionSet(functionSetVersion);

    var featureSwitchesSupported = false;
    var passEnabled = true;
    var openPgpUsbEnabled = true;
    var openPgpNfcEnabled = true;
    var pivUsbEnabled = true;
    var pivNfcEnabled = true;
    var webAuthnEnabled = true;

    if (functionSetVersion == FunctionSetVersion.v5) {
      final configResp = await SmartCard.transceive('0042000000');
      SmartCard.assertOK(configResp);
      final configData = SmartCard.dropSW(configResp);
      if (configData.length >= 12) {
        featureSwitchesSupported = true;
        final featureMask = int.parse(configData.substring(10, 12), radix: 16);
        passEnabled = featureMask & _featurePass != 0;
        openPgpUsbEnabled = featureMask & _featureOpenPgpUsb != 0;
        openPgpNfcEnabled = featureMask & _featureOpenPgpNfc != 0;
        pivUsbEnabled = featureMask & _featurePivUsb != 0;
        pivNfcEnabled = featureMask & _featurePivNfc != 0;
        webAuthnEnabled = featureMask & _featureWebAuthn != 0;
      }
    }

    return AppletSwitchStatus(
      functionSetVersion: functionSetVersion,
      functionSet: functionSet,
      featureSwitchesSupported: featureSwitchesSupported,
      passEnabled: passEnabled,
      openPgpUsbEnabled: openPgpUsbEnabled,
      openPgpNfcEnabled: openPgpNfcEnabled,
      pivUsbEnabled: pivUsbEnabled,
      pivNfcEnabled: pivNfcEnabled,
      webAuthnEnabled: webAuthnEnabled,
    );
  }

  static String disabledMessage(String appletName) {
    return S.of(Get.context!).appletDisabled(appletName);
  }
}
