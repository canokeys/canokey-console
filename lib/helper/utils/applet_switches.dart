import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/helper/utils/admin_card.dart';
import 'package:get/get.dart';

class AppletSwitchStatus {
  final FirmwareVersion firmwareVersion;
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
    required this.firmwareVersion,
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

  factory AppletSwitchStatus.fromConfig({
    required FirmwareVersion firmwareVersion,
    required FunctionSetVersion functionSetVersion,
    required List<int> config,
  }) {
    final supported =
        functionSetVersion == FunctionSetVersion.v5 && config.length >= 6;
    bool enabled(Func feature) =>
        !supported || config[5] & AppletSwitches.featureBits[feature]! != 0;
    return AppletSwitchStatus(
      firmwareVersion: firmwareVersion,
      functionSetVersion: functionSetVersion,
      functionSet: CanoKey.functionSet(functionSetVersion),
      featureSwitchesSupported: supported,
      passEnabled: enabled(Func.passSwitch),
      openPgpUsbEnabled: enabled(Func.openPgpCcIdSwitch),
      openPgpNfcEnabled: enabled(Func.openPgpNfcSwitch),
      pivUsbEnabled: enabled(Func.pivCcIdSwitch),
      pivNfcEnabled: enabled(Func.pivNfcSwitch),
      webAuthnEnabled: enabled(Func.webAuthnSwitch),
    );
  }

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
  static const featureBits = <Func, int>{
    Func.passSwitch: 1 << 0,
    Func.openPgpCcIdSwitch: 1 << 1,
    Func.openPgpNfcSwitch: 1 << 2,
    Func.pivCcIdSwitch: 1 << 3,
    Func.pivNfcSwitch: 1 << 4,
    Func.webAuthnSwitch: 1 << 5,
  };

  static int updateFeatureMask(int mask, Map<Func, bool> values) {
    for (final entry in values.entries) {
      final bit = featureBits[entry.key]!;
      mask = entry.value ? mask | bit : mask & ~bit;
    }
    return mask;
  }

  static Future<AppletSwitchStatus> readStatus({
    AdminCardClient? client,
  }) async {
    final card = client ?? AdminCardClient();
    await card.select();
    final firmware = await card.readFirmwareVersion();
    final functionSetVersion = CanoKey.functionSetFromFirmwareVersion(firmware);
    final config = functionSetVersion == FunctionSetVersion.v5
        ? await card.readConfig()
        : const <int>[];
    return AppletSwitchStatus.fromConfig(
      firmwareVersion: FirmwareVersion.parse(firmware),
      functionSetVersion: functionSetVersion,
      config: config,
    );
  }

  static String disabledMessage(String appletName) {
    return S.of(Get.context!).appletDisabled(appletName);
  }
}
