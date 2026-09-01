import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/models/keyboard_keymap.dart';
import 'package:canokey_console/models/ndef.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:ndef/ndef.dart';

/// Deterministic data used only by App Store screenshot builds.
class ScreenshotMode {
  static const bool enabled =
      bool.fromEnvironment('SCREENSHOT_MODE', defaultValue: false);

  static const String initialRoute = String.fromEnvironment(
    'SCREENSHOT_ROUTE',
    defaultValue: '/applets/pass',
  );

  static List<PassSlot> passSlots() => [
        PassSlot(
          type: PassSlotType.static,
          name: '',
          withEnter: true,
        ),
        PassSlot(
          type: PassSlotType.hmacSha1,
          name: '',
          withEnter: false,
        ),
      ];

  static List<NDEFRecord> ndefRecords() => [
        NdefDocument.uriRecord('https://canokeys.com'),
        NdefDocument.textRecord(
          '用 CanoKey 安全保护你的数字身份',
          language: 'zh',
        ),
        NdefDocument.contactRecord(
          name: 'CanoKey Support',
          phone: '+86 400 000 0000',
          email: 'support@canokeys.com',
          organization: 'CanoKeys',
        ),
      ];

  static CanoKey canoKey() => CanoKey(
        model: 'CanoKey Canary',
        sn: 'FFFFFFFF',
        chipId: '230A454D4D313633202018694B',
        firmwareVersion: '3.1.0+127.g0629be46',
        coreCommit: '58da9a85',
        functionSetVersion: FunctionSetVersion.v5,
        ledOn: true,
        hotpOn: true,
        ndefReadonly: false,
        ndefEnabled: true,
        webusbLandingEnabled: false,
        keyboardWithReturn: true,
        sigTouch: false,
        decTouch: false,
        autTouch: false,
        touchCacheTime: 15,
        nfcEnabled: true,
        passEnabled: true,
        openPgpCcIdEnabled: true,
        openPgpNfcEnabled: true,
        pivCcIdEnabled: true,
        pivNfcEnabled: true,
        webAuthnEnabled: true,
        featureSwitchesSupported: true,
        storageUsage: StorageUsage(usedKiB: 14, totalKiB: 124),
        keyboardKeymap: const KeyboardKeymapState(
          layoutId: null,
          entries: null,
          preset: KeyboardKeymapPresets.defaultPreset,
          isDefault: true,
        ),
      );
}
