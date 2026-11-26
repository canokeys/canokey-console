import 'package:canokey_console/helper/utils/piv_pin_retries.dart';
import 'package:canokey_console/controller/applets/piv/piv_controller.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PivController controllerFor(String version) {
    final controller = PivController();
    controller.firmwareVersion = FirmwareVersion.parse(version);
    controller.functionSetVersion =
        CanoKey.functionSetFromFirmwareVersion(version);
    controller.algorithmExtensionConfig = version.startsWith('2.')
        ? PivAlgorithmExtensionConfig.legacyV2
        : PivAlgorithmExtensionConfig.defaults;
    return controller;
  }

  test('maps development and documented 3.1 versions to the same features', () {
    for (final version in ['3.1.0-28-gd2820836', '3.1.1']) {
      final controller = controllerFor(version);
      expect(controller.supportsCurrentDevelopmentFeatures, isTrue);
      expect(controller.supportsPinOnlyMode, isTrue);
      expect(controller.supportsPinRetryConfig, isTrue);
      expect(controller.supportsMetadataDirectory, isTrue);
      expect(controller.supportsAlgorithm(AlgorithmType.eccp521), isTrue);
      expect(controller.supportsAlgorithm(AlgorithmType.mldsa65), isTrue);
      expect(controller.supportsAlgorithm(AlgorithmType.mlkem768), isTrue);
    }
  });

  test('hides current development features from released firmware', () {
    for (final version in ['1.6.2', '2.0.1', '3.0.3']) {
      final controller = controllerFor(version);
      expect(controller.supportsCurrentDevelopmentFeatures, isFalse);
      expect(controller.supportsPinOnlyMode, isFalse);
      expect(controller.supportsPinRetryConfig, isFalse);
      expect(controller.supportsMetadataDirectory, isFalse);
      expect(controller.supportsAlgorithm(AlgorithmType.eccp521), isFalse);
      expect(controller.supportsAlgorithm(AlgorithmType.mldsa65), isFalse);
      expect(controller.supportsAlgorithm(AlgorithmType.mlkem768), isFalse);
    }
  });

  test('requires enabled, observed 4.0 IDs for the new PIV algorithms', () {
    final raw = [...PivAlgorithmExtensionConfig.defaults.encode(), 0x67, 0x68];
    final controller = controllerFor('4.0.0');
    for (final algorithm in [AlgorithmType.mldsa44, AlgorithmType.mlkem512]) {
      expect(controller.supportsAlgorithm(algorithm), isFalse);
    }

    final config = PivAlgorithmExtensionConfig.decode(raw);
    controller.algorithmExtensionConfig = config;
    expect(config.encode(), raw);
    expect(config.toAlgorithmMap()[0x67], AlgorithmType.mldsa44);
    expect(config.toAlgorithmMap()[0x68], AlgorithmType.mlkem512);
    expect(controller.supportsAlgorithm(AlgorithmType.mldsa44), isTrue);
    expect(controller.supportsAlgorithm(AlgorithmType.mlkem512), isTrue);

    controller.algorithmExtensionConfig = PivAlgorithmExtensionConfig.decode([
      0,
      ...raw.skip(1),
    ]);
    expect(controller.supportsAlgorithm(AlgorithmType.mldsa44), isFalse);
    expect(controller.supportsAlgorithm(AlgorithmType.mlkem512), isFalse);

    final legacy = controllerFor('3.1.2')..algorithmExtensionConfig = config;
    expect(legacy.supportsAlgorithm(AlgorithmType.mldsa44), isFalse);
    expect(legacy.supportsAlgorithm(AlgorithmType.mlkem512), isFalse);
  });

  test('limits algorithms on firmware without metadata support', () {
    final controller = controllerFor('1.6.2');

    expect(controller.supportsMetadata, isFalse);
    expect(controller.supportsAlgorithm(AlgorithmType.eccp256), isTrue);
    expect(controller.supportsAlgorithm(AlgorithmType.eccp384), isTrue);
    expect(controller.supportsAlgorithm(AlgorithmType.rsa2048), isTrue);
    expect(controller.supportsAlgorithm(AlgorithmType.ed25519), isFalse);
    expect(controller.supportsAlgorithm(AlgorithmType.rsa3072), isFalse);
    expect(controller.supportsAlgorithm(AlgorithmType.x25519), isFalse);
  });

  test('uses the legacy extension algorithm IDs for firmware 2.x', () {
    const config = PivAlgorithmExtensionConfig.legacyV2;

    expect(config.idFor(AlgorithmType.ed25519), 0x22);
    expect(config.idFor(AlgorithmType.rsa3072), 0x50);
    expect(config.idFor(AlgorithmType.rsa4096), 0x51);
    expect(config.idFor(AlgorithmType.x25519), 0x52);
    expect(config.idFor(AlgorithmType.mldsa65), 0xE2);
    expect(config.idFor(AlgorithmType.mlkem768), 0xE3);
  });

  test(
    'rejects retry resets in PIN-only mode before contacting the card',
    () async {
      final controller = controllerFor('3.1.1');
      controller.pinOnlyMode = true;
      expect(await controller.setPinRetries('', '', 3, 3, false), PivPinRetryResetResult.failed);
      controller.pinOnlyMode = false;
      expect(await controller.setPinRetries('', '', 3, 3, true), PivPinRetryResetResult.failed);
    },
  );

  test('rejects current development commands before contacting old firmware',
      () async {
    final controller = controllerFor('3.0.3');

    expect(await controller.setPinRetries('', '', 3, 3, false), PivPinRetryResetResult.failed);
    expect(await controller.enablePinOnlyMode('', ''), isFalse);
    expect(
      await controller.clearSlotAuthenticated(
        slot: '9A',
        pin: '',
        managementKey: '',
        usePinOnly: false,
      ),
      isFalse,
    );
    expect(await controller.attestKey('9A'), isNull);
  });
}
