import 'package:canokey_console/models/piv_macos_setup.dart';
import 'package:canokey_console/models/piv_self_sign_options.dart';
import 'dart:async';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show PlatformInt64Util;
import 'dart:math';
import 'dart:typed_data';

import 'package:canokey_console/controller/base/polling_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/tlv.dart';
import 'package:canokey_console/helper/utils/applet_switches.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/piv_card.dart';
import 'package:canokey_console/helper/utils/piv_pin_retries.dart';
import 'package:canokey_console/helper/utils/piv_csr.dart';
import 'package:canokey_console/helper/utils/piv_metadata_directory.dart';
import 'package:canokey_console/helper/utils/piv_signature.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:canokey_console/src/rust/api/crypto.dart';
import 'package:canokey_console/src/rust/api/piv_crypto.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class PivController extends PollingController {
  PivController({PivCardClient? client}) : _client = client ?? PivCardClient();

  final PivCardClient _client;

  @override
  void onClose() {
    _client.cancelPendingOperations();
    super.onClose();
  }

  Map<int, SlotInfo> slots = {};
  final Set<int> certificateSlots = {};
  final Map<int, Uint8List> certificateBytes = {};
  final Map<int, X509CertData> certificates = {};
  FirmwareVersion firmwareVersion = const FirmwareVersion(0, 0, 0);
  FunctionSetVersion functionSetVersion = FunctionSetVersion.v1;
  bool extendedRetiredSlots = false;
  SlotInfo? pinInfo;
  int? legacyPinRetriesRemaining;
  int? get pinRetriesRemaining =>
      pinInfo?.remainingCount ?? legacyPinRetriesRemaining;
  SlotInfo? pukInfo;
  SlotInfo? managementKeyInfo;
  bool pinOnlyMode = false;
  String? disabledMessage;
  PivAlgorithmExtensionConfig algorithmExtensionConfig =
      PivAlgorithmExtensionConfig.defaults;

  @override
  Logger get log => Logging.logger('PIV:Controller');

  bool get supportsCurrentDevelopmentFeatures =>
      functionSetVersion == FunctionSetVersion.v5;

  bool get supportsMetadata =>
      firmwareVersion.compareTo(const FirmwareVersion(2, 0, 0)) >= 0;

  bool get supportsPinOnlyMode => supportsCurrentDevelopmentFeatures;

  bool get supportsPinRetryConfig => supportsCurrentDevelopmentFeatures;

  bool get supportsMetadataDirectory =>
      functionSetVersion == FunctionSetVersion.v5;

  bool supportsAlgorithm(AlgorithmType algorithm) {
    switch (algorithm) {
      case AlgorithmType.eccp256:
      case AlgorithmType.eccp384:
      case AlgorithmType.rsa2048:
        return true;
      case AlgorithmType.eccp521:
        return supportsCurrentDevelopmentFeatures &&
            algorithmExtensionConfig.enabled;
      case AlgorithmType.ed25519:
      case AlgorithmType.rsa3072:
      case AlgorithmType.rsa4096:
      case AlgorithmType.x25519:
      case AlgorithmType.secp256k1:
      case AlgorithmType.sm2:
        return supportsMetadata && algorithmExtensionConfig.enabled;
      case AlgorithmType.mldsa65:
      case AlgorithmType.mlkem768:
        return supportsCurrentDevelopmentFeatures &&
            algorithmExtensionConfig.enabled;
      case AlgorithmType.pin:
      case AlgorithmType.tdes:
      case AlgorithmType.aes128:
      case AlgorithmType.aes192:
      case AlgorithmType.aes256:
      case AlgorithmType.rsa1024:
        return false;
    }
  }

  @override
  Future<void> doRefreshData() async {
    log.t('Call PivController.doRefreshData');
    await SmartCard.process((String sn) async {
      final switchStatus = await AppletSwitches.readStatus();
      firmwareVersion = switchStatus.firmwareVersion;
      functionSetVersion = switchStatus.functionSetVersion;
      extendedRetiredSlots = supportsCurrentDevelopmentFeatures;
      if (!switchStatus.pivEnabled) {
        disabledMessage = AppletSwitches.disabledMessage('PIV');
        polled = false;
        slots.clear();
        certificateSlots.clear();
        certificateBytes.clear();
        certificates.clear();
        pinInfo = null;
        legacyPinRetriesRemaining = null;
        pukInfo = null;
        managementKeyInfo = null;
        update();
        return;
      }
      disabledMessage = null;

      await _client.prepare();
      await _refreshCapabilities();
      slots.clear();
      certificateSlots.clear();
      certificateBytes.clear();
      certificates.clear();
      pinInfo = supportsMetadata ? await _client.readMetadata(0x80) : null;
      legacyPinRetriesRemaining = null;
      if (!supportsMetadata) {
        legacyPinRetriesRemaining = await _client.readRemainingPinRetries();
      }
      pukInfo = supportsMetadata ? await _client.readMetadata(0x81) : null;
      managementKeyInfo = supportsMetadata
          ? await _client.readMetadata(0x9B)
          : null;
      pinOnlyMode = supportsPinOnlyMode
          ? await _readPinOnlyModeInSession()
          : false;
      final directory = await _readMetadataDirectory();
      if (directory == null) {
        await _refreshSlotsLegacy();
      } else {
        _refreshSlotsFromDirectory(directory);
      }

      polled = true;
      update();
    });
  }

  Future<void> _refreshCapabilities() async {
    PivAlgorithmExtensionConfig? config;
    try {
      config = await _client.readAlgorithmExtensions();
    } on ProtocolException catch (error) {
      // Console reads capabilities before any authentication; on 3.0.x the
      // read sits behind management-key authentication (upstream capability
      // PivProtectedAlgorithmConfigRead), so the card rejects it with 6982.
      // That security rejection alone permits the firmware-defaults fallback;
      // every other failure remains visible.
      if (error.details.kind != 'SecurityStatusNotSatisfied') rethrow;
    }
    if (config != null) {
      algorithmExtensionConfig = config;
      return;
    }
    final isLegacyV2 =
        firmwareVersion.compareTo(const FirmwareVersion(2, 0, 0)) >= 0 &&
        firmwareVersion.compareTo(const FirmwareVersion(3, 0, 0)) < 0;
    algorithmExtensionConfig = isLegacyV2
        ? PivAlgorithmExtensionConfig.legacyV2
        : PivAlgorithmExtensionConfig.defaults;
  }

  Future<PivMetadataDirectory?> _readMetadataDirectory() async {
    if (!supportsMetadataDirectory) {
      return null;
    }
    try {
      return PivMetadataDirectory.parse(await _client.readMetadataDirectory());
    } on ProtocolException catch (error) {
      if (error.details.kind == 'NotFound' ||
          error.details.kind == 'UnsupportedFeature') {
        return null;
      }
      rethrow;
    } catch (error) {
      log.w('Failed to parse PIV metadata directory', error: error);
      return null;
    }
  }

  void _refreshSlotsFromDirectory(PivMetadataDirectory directory) {
    for (final entry in directory.entries) {
      if (entry.hasKey) {
        slots[entry.slot] = entry.toSlotInfo(algorithmExtensionConfig);
      }
      if (entry.hasCertificate) {
        certificateSlots.add(entry.slot);
      }
    }
  }

  bool hasCertificate(int slot) =>
      certificateSlots.contains(slot) || certificateBytes.containsKey(slot);

  Future<SlotInfo?> loadSlotDetails(int slot) async {
    log.t('Call PivController.loadSlotDetails');
    final current = slots[slot];
    final needsKeyMetadata = current != null && current.public.isEmpty;
    final needsCertificate =
        hasCertificate(slot) && !certificateBytes.containsKey(slot);
    if (!needsKeyMetadata && !needsCertificate) {
      return current;
    }

    SlotInfo? loaded = current;
    await SmartCard.process((String sn) async {
      await _client.prepare();
      if (needsKeyMetadata) {
        loaded = await _readKeyMetadata(slot) ?? current;
      }
      if (needsCertificate) {
        await _readSlotCertificate(slot, loaded);
      }
      final metadata = loaded;
      if (metadata != null) {
        metadata.cert = certificates[slot];
        metadata.certBytes = certificateBytes[slot];
        slots[slot] = metadata;
      }
      update();
    });
    return loaded;
  }

  Future<void> _refreshSlotsLegacy() async {
    for (final slot in _keySlots) {
      SlotInfo? slotInfo;
      if (supportsMetadata) {
        slotInfo = await _readKeyMetadata(slot);
        if (slotInfo != null) {
          slots[slot] = slotInfo;
        }
      }
      if (_certDO.containsKey(slot)) {
        await _readSlotCertificate(slot, slotInfo);
      }
    }
  }

  Future<SlotInfo?> _readKeyMetadata(int slot) async {
    return _client.readMetadata(
      slot,
      algorithmExtensionConfig: algorithmExtensionConfig,
    );
  }

  Future<void> _readSlotCertificate(int slot, SlotInfo? slotInfo) async {
    final certObject = _certDO[slot];
    if (certObject == null) {
      return;
    }
    Uint8List? bytes;
    try {
      bytes = await _client.readCertificate(certObject);
    } catch (error) {
      if (error is! FormatException &&
          !(error is ProtocolException && error.details.phase == 'Parsing')) {
        rethrow;
      }
      // An unreadable object still occupies the slot: replacement needs consent.
      certificateSlots.add(slot);
      log.w(
        'Unable to decode PIV certificate object in slot '
        '${slot.toRadixString(16)}',
        error: error,
      );
      return;
    }
    if (bytes == null) return;
    certificateSlots.add(slot);
    certificateBytes[slot] = bytes;
    slotInfo?.certBytes = bytes;
    try {
      final cert = parseX509CertFromDer(der: bytes);
      certificates[slot] = cert;
      slotInfo?.cert = cert;
    } on String catch (error) {
      // The Rust Result<X509CertData, String> bridge throws decoding errors.
      log.w(
        'Unable to parse PIV certificate in slot '
        '${slot.toRadixString(16)}',
        error: error,
      );
    }
  }

  PivPublicKey? publicKeyForSlot(SlotInfo slot) {
    try {
      return PivSignatureTest.publicKeyFromSlot(slot);
    } catch (error) {
      log.w(
        'Unable to parse PIV public key in slot '
        '${slot.number.toRadixString(16)} (${slot.algorithm.name})',
        error: error,
      );
      return null;
    }
  }

  /// Export certificate public keys even when firmware cannot read key metadata.
  /// A certificate does not establish that the corresponding private key exists.
  Uint8List? publicKeyDerForSlot(int slot) {
    final metadata = slots[slot];
    if (metadata != null) {
      return publicKeyForSlot(metadata)?.encodedSubjectPublicKeyInfo;
    }
    final spki = certificates[slot]?.subjectPublicKeyInfo;
    return spki == null || spki.isEmpty ? null : spki;
  }

  void changePin(String oldPin, String newPin) {
    log.t('Call PivController.changePin');
    _runPinChange(() => _client.changePin(oldPin, newPin));
  }

  void changePUK(String oldPin, String newPin) {
    log.t('Call PivController.changePUK');
    _runPinChange(() => _client.changePuk(oldPin, newPin));
  }

  void unblockPin(String puk, String newPin) {
    log.t('Call PivController.unblockPin');
    _runPinChange(() => _client.unblockPin(puk, newPin), refresh: true);
  }

  void _runPinChange(
    Future<bool> Function() operation, {
    bool refresh = false,
  }) async {
    var changed = false;
    await SmartCard.process((String sn) async {
      await _client.prepare();
      if (!await operation()) {
        Prompts.promptPinFailureResult(_client.lastStatusWord ?? '');
        return;
      }
      Navigator.pop(Get.context!);
      changed = true;
      Prompts.showPrompt(
        S.of(Get.context!).successfullyChanged,
        ContentThemeColor.success,
      );
    });
    if (changed && refresh) await refreshData();
  }

  Future<bool> changeManagementKey(
    String currentKey,
    String newKey, {
    String pin = '',
    bool usePinOnly = false,
    bool storeOnDevice = false,
    TouchPolicy? touchPolicy,
  }) async {
    log.t('Call PivController.changeManagementKey');
    final c = Completer<bool>();
    if ((usePinOnly || storeOnDevice) && !supportsPinOnlyMode) {
      return false;
    }
    await SmartCard.process((String sn) async {
      await _client.prepare();
      if ((usePinOnly || storeOnDevice) && !await _verifyPinInSession(pin)) {
        c.complete(false);
        return;
      }
      if (!await _authenticateManagementKeyOrPinOnly(
        pin,
        currentKey,
        usePinOnly,
      )) {
        c.complete(false);
        return;
      }
      if (storeOnDevice && !await _client.blockPuk()) {
        c.complete(false);
        return;
      }
      if (!await _setManagementKeyInSession(
        newKey,
        touchPolicy: touchPolicy ?? managementKeyTouchPolicy,
      )) {
        c.complete(false);
        return;
      }
      if (storeOnDevice) {
        if (!await _authenticateManagementKey(newKey)) {
          c.complete(false);
          return;
        }
        if (!await _writePinOnlyObjects(newKey, enabled: true)) {
          // Roll back to the previous key; otherwise the on-card key and the
          // stored protected key disagree and the user is locked out.
          await _setManagementKeyInSession(
            currentKey,
            touchPolicy: touchPolicy ?? managementKeyTouchPolicy,
          );
          c.complete(false);
          return;
        }
      } else if (pinOnlyMode) {
        if (!await _authenticateManagementKey(newKey)) {
          c.complete(false);
          return;
        }
        await _writePinOnlyObjects(newKey, enabled: false);
      }
      c.complete(true);
    });
    if (!c.isCompleted) c.complete(false);
    return c.future;
  }

  Future<String?> generateCsr(
    String slot,
    AlgorithmType algorithm,
    PinPolicy pinPolicy,
    TouchPolicy touchPolicy,
    String pin,
    String managementKey,
    Map<String, String> subject,
    List<String> subjectAlternativeNames,
    bool usePinOnly,
  ) async {
    log.t('Call PivController.generateCsr');
    final c = Completer<String?>();
    await SmartCard.process((String sn) async {
      await _client.prepare();
      if (!await _verifyPinInSession(pin)) {
        c.complete(null);
        return;
      }
      if (!await _authenticateManagementKeyOrPinOnly(
        pin,
        managementKey,
        usePinOnly,
      )) {
        c.complete(null);
        return;
      }
      Uint8List spki;
      try {
        spki = await _client.generateKey(
          slot: int.parse(slot, radix: 16),
          algorithm: algorithm.value,
          pinPolicy: pinPolicy.value,
          touchPolicy: touchPolicy.value,
        );
      } catch (_) {
        c.complete(null);
        return;
      }
      final publicKey = PivPublicKey.fromSubjectPublicKeyInfo(algorithm, spki);
      final certificationRequestInfo =
          PivCsrBuilder.buildCertificationRequestInfo(
            subject: subject,
            publicKey: publicKey,
            subjectAlternativeNames: subjectAlternativeNames,
          );

      final signature = await _signInSession(
        slot,
        algorithm,
        certificationRequestInfo,
        publicKey,
      );
      if (signature == null) {
        c.complete(null);
        return;
      }
      c.complete(
        PivCsrBuilder.buildPem(
          certificationRequestInfo: certificationRequestInfo,
          algorithm: algorithm,
          signature: signature,
        ),
      );
    });
    if (!c.isCompleted) c.complete(null);
    return c.future;
  }

  Future<PivMacOsSetupSlot> _readMacOsSetupSlotInSession(
    String slotNumber,
  ) async {
    final id = int.parse(slotNumber, radix: 16);
    final key = await _readKeyMetadata(id);
    if (key == null && _client.lastStatusWord?.toUpperCase() != '6A88') {
      throw StateError('Unable to inspect PIV key metadata');
    }
    final cert = await _client.readCertificate(_certDO[id]!);
    if (cert == null &&
        !{'6A82', '6A88'}.contains(_client.lastStatusWord?.toUpperCase())) {
      throw StateError('Unable to inspect PIV certificate');
    }
    final supported =
        key != null &&
        key.public.isNotEmpty &&
        (key.algorithm == AlgorithmType.eccp256 ||
            key.algorithm == AlgorithmType.rsa2048);
    final compatible =
        supported &&
        cert != null &&
        pivCertificateSupportsMacos(
          der: cert,
          expectedPublicKey: PivPublicKey.fromSlotMetadata(
            key.algorithm,
            key.public,
          ).encodedSubjectPublicKeyInfo,
          slot: id,
          nowUnix: PlatformInt64Util.from(
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
        );
    return PivMacOsSetupSlot(
      slotNumber: slotNumber,
      key: key,
      certificate: cert,
      compatible: compatible,
    );
  }

  Future<PivMacOsSetupPlan?> inspectMacOsSetup() async {
    if (!supportsMetadata) return null;
    PivMacOsSetupPlan? plan;
    await SmartCard.process((_) async {
      await _client.prepare();
      final serial = await _client.readSerial();
      final entries = <PivMacOsSetupSlot>[];
      for (final slot in ['9A', '9D']) {
        entries.add(await _readMacOsSetupSlotInSession(slot));
      }
      plan = PivMacOsSetupPlan(serial: serial, slots: entries);
      for (final entry in entries) {
        final id = int.parse(entry.slotNumber, radix: 16);
        if (entry.key == null) {
          slots.remove(id);
        } else {
          slots[id] = entry.key!;
        }
        certificates.remove(id);
        certificateBytes.remove(id);
        certificateSlots.remove(id);
        if (entry.certificate != null) {
          certificateSlots.add(id);
          certificateBytes[id] = entry.certificate!;
          try {
            certificates[id] = parseX509CertFromDer(der: entry.certificate!);
          } catch (_) {
            /* Invalid certificates remain visible for replacement. */
          }
        }
      }
      update();
    });
    return plan;
  }

  /// Configure both roles, checking the reviewed card state again before writes.
  /// A failed second slot leaves the first intact; a fresh inspection can resume.
  Future<bool> configureMacOsLogin({
    required PivMacOsSetupPlan plan,
    required String pin,
    required String managementKey,
    required bool usePinOnly,
    required bool allowReplacement,
    required void Function(String slot, bool done) onProgress,
  }) async {
    if (plan.slots.length != 2 ||
        plan.slots[0].slotNumber != '9A' ||
        plan.slots[1].slotNumber != '9D')
      return false;
    if (plan.needsReplacementConsent && !allowReplacement) return false;
    final actual = await inspectMacOsSetup();
    if (actual == null || !plan.sameContents(actual)) return false;
    for (final slot in actual.slots) {
      if (slot.compatible) {
        onProgress(slot.slotNumber, true);
        continue;
      }
      onProgress(slot.slotNumber, false);
      final options = PivSelfSignOptions(
        slotNumber: slot.slotNumber,
        pinPolicy: PinPolicy.once,
      );
      if (slot.canReuseKey) options.algorithm = slot.key!.algorithm;
      options.applyMacOsLogin();
      final cert = await generateSelfSignedCertificate(
        slot.slotNumber,
        options.algorithm,
        slot.canReuseKey ? slot.key!.pinPolicy : options.pinPolicy,
        slot.canReuseKey ? slot.key!.touchPolicy : TouchPolicy.never,
        pin,
        managementKey,
        {'CN': 'CanoKey Mac ${slot.slotNumber}'},
        const [],
        365,
        usePinOnly,
        keyUsage: options.keyUsage,
        keyUsageCritical: options.keyUsageCritical,
        extendedKeyUsage: options.extendedKeyUsage.toList(),
        includeBasicConstraints: true,
        reuseExistingKey: slot.canReuseKey,
        expectedState: slot,
        expectedSerial: plan.serial,
      );
      if (cert == null) return false;
      onProgress(slot.slotNumber, true);
    }
    final verified = await inspectMacOsSetup();
    return verified != null &&
        verified.serial == plan.serial &&
        verified.complete;
  }

  Future<Uint8List?> generateSelfSignedCertificate(
    String slot,
    AlgorithmType algorithm,
    PinPolicy pinPolicy,
    TouchPolicy touchPolicy,
    String pin,
    String managementKey,
    Map<String, String> subject,
    List<String> subjectAlternativeNames,
    int validityDays,
    bool usePinOnly, {
    int keyUsage = 0,
    bool keyUsageCritical = true,
    List<String> extendedKeyUsage = const [],
    bool includeBasicConstraints = false,
    bool reuseExistingKey = false,
    PivMacOsSetupSlot? expectedState,
    String? expectedSerial,
  }) async {
    log.t('Call PivController.generateSelfSignedCertificate');
    final c = Completer<Uint8List?>();
    await SmartCard.process((String sn) async {
      await _client.prepare();
      if (expectedSerial != null &&
          expectedSerial != await _client.readSerial()) {
        return;
      }
      if (expectedState != null) {
        final actual = await _readMacOsSetupSlotInSession(slot);
        if (!expectedState.sameContents(actual)) return;
      }
      if (!await _verifyPinInSession(pin)) {
        c.complete(null);
        return;
      }
      if (!await _authenticateManagementKeyOrPinOnly(
        pin,
        managementKey,
        usePinOnly,
      )) {
        c.complete(null);
        return;
      }
      PivPublicKey publicKey;
      if (reuseExistingKey) {
        final existing = await _readKeyMetadata(int.parse(slot, radix: 16));
        if (existing == null ||
            existing.algorithm != algorithm ||
            existing.public.isEmpty)
          return;
        publicKey = PivPublicKey.fromSlotMetadata(
          existing.algorithm,
          existing.public,
        );
      } else {
        try {
          final spki = await _client.generateKey(
            slot: int.parse(slot, radix: 16),
            algorithm: algorithm.value,
            pinPolicy: pinPolicy.value,
            touchPolicy: touchPolicy.value,
          );
          publicKey = PivPublicKey.fromSubjectPublicKeyInfo(algorithm, spki);
        } catch (_) {
          return;
        }
      }
      final now = DateTime.now().toUtc();
      final tbsCertificate = PivCertificateBuilder.buildTbsCertificate(
        subject: subject,
        publicKey: publicKey,
        serialNumber: _randomSerialNumber(),
        notBefore: now.subtract(Duration(minutes: 5)),
        notAfter: now.add(Duration(days: validityDays)),
        subjectAlternativeNames: subjectAlternativeNames,
        keyUsage: keyUsage,
        keyUsageCritical: keyUsageCritical,
        extendedKeyUsage: extendedKeyUsage,
        includeBasicConstraints: includeBasicConstraints,
      );
      final signature = await _signInSession(
        slot,
        algorithm,
        tbsCertificate,
        publicKey,
      );
      if (signature == null) {
        c.complete(null);
        return;
      }
      final cert = PivCertificateBuilder.buildCertificate(
        tbsCertificate: tbsCertificate,
        algorithm: algorithm,
        signature: signature,
      );
      if (!await _importCertInSession(slot, cert)) {
        c.complete(null);
        return;
      }
      c.complete(cert);
    });
    if (!c.isCompleted) c.complete(null);
    return c.future;
  }

  Future<bool> generateKey(
    String slot,
    AlgorithmType algorithm,
    PinPolicy pinPolicy,
    TouchPolicy touchPolicy,
    String pin,
    String managementKey,
    bool usePinOnly,
  ) async {
    log.t('Call PivController.generateKey');
    final c = Completer<bool>();
    await SmartCard.process((String sn) async {
      await _client.prepare();
      if (usePinOnly && !await _verifyPinInSession(pin)) {
        c.complete(false);
        return;
      }
      if (!await _authenticateManagementKeyOrPinOnly(
        pin,
        managementKey,
        usePinOnly,
      )) {
        c.complete(false);
        return;
      }
      final publicKey = await _client.generateKey(
        slot: int.parse(slot, radix: 16),
        algorithm: algorithm.value,
        pinPolicy: pinPolicy.value,
        touchPolicy: touchPolicy.value,
      );
      c.complete(publicKey.isNotEmpty);
    });
    if (!c.isCompleted) c.complete(false);
    return c.future;
  }

  Future<PivPinRetryResetResult> setPinRetries(
    String pin,
    String managementKey,
    int pinRetries,
    int pukRetries,
    bool usePinOnly,
  ) async {
    log.t('Call PivController.setPinRetries');
    if (!supportsPinRetryConfig || pinOnlyMode || usePinOnly) {
      return PivPinRetryResetResult.failed;
    }
    final c = Completer<PivPinRetryResetResult>();
    await SmartCard.process((String sn) async {
      await _client.prepare();
      // Read the card as well: the UI state may be stale or the card changed.
      if (await _readPinOnlyModeInSession()) {
        c.complete(PivPinRetryResetResult.failed);
        return;
      }
      if (!await _verifyPinInSession(pin)) {
        c.complete(PivPinRetryResetResult.failed);
        return;
      }
      if (!await _authenticateManagementKeyOrPinOnly(
        pin,
        managementKey,
        usePinOnly,
      )) {
        c.complete(PivPinRetryResetResult.failed);
        return;
      }
      c.complete(
        await resetPivPinRetries(
          reset: () async {
            try {
              await _client.resetPinPukRetries(pinRetries, pukRetries);
              return true;
            } catch (_) {
              return false;
            }
          },
          authenticateManagementKey: () =>
              _authenticateManagementKey(managementKey),
          updateMetadata: () async {
            final adminData = await _getDataObject(_pivmanDataObject);
            if (adminData == null) return false;
            final flags = _pivmanFlags(adminData);
            if (flags & _pivmanPukBlockedFlag == 0) return true;
            return _putDataObject(
              _pivmanDataObject,
              _buildPivmanData(adminData, flags & ~_pivmanPukBlockedFlag),
            );
          },
        ),
      );
    });
    if (!c.isCompleted) c.complete(PivPinRetryResetResult.failed);
    return c.future;
  }

  Future<bool> enablePinOnlyMode(
    String pin,
    String currentManagementKey,
  ) async {
    log.t('Call PivController.enablePinOnlyMode');
    if (!supportsPinOnlyMode) {
      return false;
    }
    final c = Completer<bool>();
    await SmartCard.process((String sn) async {
      await _client.prepare();
      if (!await _verifyPinInSession(pin)) {
        c.complete(false);
        return;
      }
      if (!await _authenticateManagementKey(currentManagementKey)) {
        c.complete(false);
        return;
      }
      if (!await _client.blockPuk()) {
        c.complete(false);
        return;
      }
      final random = Random.secure();
      final newKey = hex.encode(
        List<int>.generate(24, (_) => random.nextInt(256)),
      );
      if (!await _setManagementKeyInSession(
        newKey,
        touchPolicy: managementKeyTouchPolicy,
      )) {
        c.complete(false);
        return;
      }
      if (!await _authenticateManagementKey(newKey)) {
        c.complete(false);
        return;
      }
      if (!await _writePinOnlyObjects(newKey, enabled: true)) {
        // Roll back the random management key; otherwise the card keeps an
        // unknown key with pin-only mode off and is locked out until reset.
        await _setManagementKeyInSession(
          currentManagementKey,
          touchPolicy: managementKeyTouchPolicy,
        );
        c.complete(false);
        return;
      }
      c.complete(true);
    });
    if (!c.isCompleted) c.complete(false);
    return c.future;
  }

  Future<bool> disablePinOnlyMode(
    String pin,
    String currentManagementKey,
    String newManagementKey,
    bool usePinOnly,
  ) async {
    log.t('Call PivController.disablePinOnlyMode');
    if (!supportsPinOnlyMode) {
      return false;
    }
    final c = Completer<bool>();
    await SmartCard.process((String sn) async {
      await _client.prepare();
      if (usePinOnly && !await _verifyPinInSession(pin)) {
        c.complete(false);
        return;
      }
      if (!await _authenticateManagementKeyOrPinOnly(
        pin,
        currentManagementKey,
        usePinOnly,
      )) {
        c.complete(false);
        return;
      }
      if (!await _setManagementKeyInSession(
        newManagementKey,
        touchPolicy: managementKeyTouchPolicy,
      )) {
        c.complete(false);
        return;
      }
      if (!await _authenticateManagementKey(newManagementKey)) {
        c.complete(false);
        return;
      }
      c.complete(await _writePinOnlyObjects(newManagementKey, enabled: false));
    });
    if (!c.isCompleted) c.complete(false);
    return c.future;
  }

  Future<Uint8List?> deriveX25519Secret(
    String slot,
    String pin,
    Uint8List peerPublicKey,
  ) async {
    log.t('Call PivController.deriveX25519Secret');
    final c = Completer<Uint8List?>();
    await SmartCard.process((String sn) async {
      await _client.prepare();
      if (!await _verifyPinInSession(pin)) {
        c.complete(null);
        return;
      }
      try {
        c.complete(
          await _client.derive(
            int.parse(slot, radix: 16),
            algorithmExtensionConfig.idFor(AlgorithmType.x25519),
            peerPublicKey,
          ),
        );
      } on ProtocolException {
        c.complete(null);
      }
    });
    if (!c.isCompleted) c.complete(null);
    return c.future;
  }

  Future<Uint8List?> decapsulateMlKem768(
    String slot,
    String pin,
    Uint8List ciphertext,
  ) async {
    log.t('Call PivController.decapsulateMlKem768');
    if (!supportsAlgorithm(AlgorithmType.mlkem768)) {
      return null;
    }
    final c = Completer<Uint8List?>();
    try {
      await SmartCard.process((String sn) async {
        await _client.prepare();
        if (!await _verifyPinInSession(pin)) {
          c.complete(null);
          return;
        }
        try {
          c.complete(
            await _client.decapsulate(int.parse(slot, radix: 16), ciphertext),
          );
        } on ProtocolException {
          c.complete(null);
        }
      });
    } catch (_) {
      if (!c.isCompleted) {
        c.complete(null);
      }
    }
    if (!c.isCompleted) {
      c.complete(null);
    }
    return c.future;
  }

  Future<Uint8List?> signData(
    String slot,
    SlotInfo slotInfo,
    String pin,
    Uint8List data,
  ) async {
    log.t('Call PivController.signData');
    final publicKey = publicKeyForSlot(slotInfo);
    if (publicKey == null) {
      return null;
    }
    final c = Completer<Uint8List?>();
    try {
      await SmartCard.process((String sn) async {
        try {
          await _client.prepare();
          if (!await _verifyPinInSession(pin)) {
            c.complete(null);
            return;
          }
          final signature = await _signInSession(
            slot,
            slotInfo.algorithm,
            data,
            publicKey,
          );
          c.complete(signature);
        } catch (_) {
          if (!c.isCompleted) {
            c.complete(null);
          }
        }
      });
    } catch (_) {
      if (!c.isCompleted) {
        c.complete(null);
      }
    }
    if (!c.isCompleted) {
      c.complete(null);
    }
    return c.future;
  }

  Future<bool> verifySignature(
    SlotInfo slotInfo,
    Uint8List data,
    Uint8List signature,
  ) async {
    log.t('Call PivController.verifySignature');
    final publicKey = publicKeyForSlot(slotInfo);
    if (publicKey == null) {
      return false;
    }
    try {
      return await PivSignatureTest.verify(
        publicKey: publicKey,
        data: data,
        signature: signature,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> importPostQuantumSeed(
    String slotNumber,
    AlgorithmType algorithm,
    Uint8List seed,
    PinPolicy pinPolicy,
    TouchPolicy touchPolicy,
  ) async {
    log.t('Call PivController.importPostQuantumSeed');
    if (!supportsAlgorithm(algorithm) ||
        !_isValidPostQuantumSeed(algorithm, seed)) {
      return false;
    }
    final c = Completer<bool>();
    try {
      await SmartCard.process((String sn) async {
        await _client.prepare();
        c.complete(
          await _importPostQuantumSeedInSession(
            slotNumber,
            algorithm,
            seed,
            pinPolicy,
            touchPolicy,
          ),
        );
      });
    } catch (_) {
      if (!c.isCompleted) {
        c.complete(false);
      }
    }
    if (!c.isCompleted) {
      c.complete(false);
    }
    return c.future;
  }

  Future<bool> changeAlgorithmExtensionConfigAuthenticated({
    required PivAlgorithmExtensionConfig config,
    required String pin,
    required String managementKey,
    required bool usePinOnly,
  }) async {
    log.t('Call PivController.changeAlgorithmExtensionConfigAuthenticated');
    final c = Completer<bool>();
    await SmartCard.process((String sn) async {
      await _client.prepare();
      if (usePinOnly && !await _verifyPinInSession(pin)) {
        c.complete(false);
        return;
      }
      if (!await _authenticateManagementKeyOrPinOnly(
        pin,
        managementKey,
        usePinOnly,
      )) {
        c.complete(false);
        return;
      }
      try {
        await _client.setAlgorithmConfig(Uint8List.fromList(config.encode()));
      } on ProtocolException {
        c.complete(false);
        return;
      }
      algorithmExtensionConfig = config;
      c.complete(true);
    });
    if (!c.isCompleted) c.complete(false);
    return c.future;
  }

  Future<bool> importAuthenticated({
    required String slot,
    required String pin,
    required String managementKey,
    required bool usePinOnly,
    PivPrivateKeyData? privateKey,
    Uint8List? mlDsaSeed,
    Uint8List? mlKemSeed,
    Uint8List? cert,
    required PinPolicy pinPolicy,
    required TouchPolicy touchPolicy,
  }) async {
    log.t('Call PivController.importAuthenticated');
    if ((mlDsaSeed != null && !supportsAlgorithm(AlgorithmType.mldsa65)) ||
        (mlKemSeed != null && !supportsAlgorithm(AlgorithmType.mlkem768)) ||
        (mlDsaSeed != null &&
            !_isValidPostQuantumSeed(AlgorithmType.mldsa65, mlDsaSeed)) ||
        (mlKemSeed != null &&
            !_isValidPostQuantumSeed(AlgorithmType.mlkem768, mlKemSeed))) {
      return false;
    }
    final c = Completer<bool>();
    await SmartCard.process((String sn) async {
      await _client.prepare();
      if (usePinOnly && !await _verifyPinInSession(pin)) {
        c.complete(false);
        return;
      }
      if (!await _authenticateManagementKeyOrPinOnly(
        pin,
        managementKey,
        usePinOnly,
      )) {
        c.complete(false);
        return;
      }
      if (privateKey != null &&
          !await _importPrivateKeyInSession(
            slot,
            privateKey,
            pinPolicy,
            touchPolicy,
          )) {
        c.complete(false);
        return;
      }
      if (mlDsaSeed != null &&
          !await _importPostQuantumSeedInSession(
            slot,
            AlgorithmType.mldsa65,
            mlDsaSeed,
            pinPolicy,
            touchPolicy,
          )) {
        c.complete(false);
        return;
      }
      if (mlKemSeed != null &&
          !await _importPostQuantumSeedInSession(
            slot,
            AlgorithmType.mlkem768,
            mlKemSeed,
            pinPolicy,
            touchPolicy,
          )) {
        c.complete(false);
        return;
      }
      if (cert != null && !await _importCertInSession(slot, cert)) {
        c.complete(false);
        return;
      }
      c.complete(true);
    });
    if (!c.isCompleted) c.complete(false);
    return c.future;
  }

  Future<bool> _importPrivateKeyInSession(
    String slotNumber,
    PivPrivateKeyData key,
    PinPolicy pinPolicy,
    TouchPolicy touchPolicy,
  ) async {
    final algorithm = AlgorithmType.fromValue(key.algorithm);
    final slot = int.parse(slotNumber, radix: 16);
    final wireId = algorithmExtensionConfig.idFor(algorithm);
    final components = TLV.parse(key.importData);
    final copies = <Uint8List>[];
    Uint8List component(int tag) {
      final value = components[tag];
      if (value is! List<int>) {
        throw FormatException(
          'PIV import data lacks component ${tag.toRadixString(16)}',
        );
      }
      final copy = Uint8List.fromList(value);
      copies.add(copy);
      return copy;
    }

    try {
      switch (algorithm) {
        case AlgorithmType.rsa1024 ||
        AlgorithmType.rsa2048 ||
        AlgorithmType.rsa3072 ||
        AlgorithmType.rsa4096:
          await _client.importRsaKey(
            slot: slot,
            algorithm: wireId,
            p: component(0x01),
            q: component(0x02),
            dp: component(0x03),
            dq: component(0x04),
            qinv: component(0x05),
            pinPolicy: pinPolicy.value,
            touchPolicy: touchPolicy.value,
          );
        case AlgorithmType.ed25519:
          await _client.importEd25519Key(
            slot: slot,
            seed: component(0x06),
            pinPolicy: pinPolicy.value,
            touchPolicy: touchPolicy.value,
          );
        default:
          await _client.importEcKey(
            slot: slot,
            algorithm: wireId,
            scalar: component(0x06),
            pinPolicy: pinPolicy.value,
            touchPolicy: touchPolicy.value,
          );
      }
      return true;
    } on ProtocolException {
      return false;
    } on FormatException {
      return false;
    } finally {
      for (final copy in copies) {
        copy.fillRange(0, copy.length, 0);
      }
    }
  }

  Future<bool> _importPostQuantumSeedInSession(
    String slotNumber,
    AlgorithmType algorithm,
    Uint8List seed,
    PinPolicy pinPolicy,
    TouchPolicy touchPolicy,
  ) async {
    final kind = switch (algorithm) {
      AlgorithmType.mldsa65 => 0,
      AlgorithmType.mlkem768 => 1,
      _ => null,
    };
    if (kind == null || !_isValidPostQuantumSeed(algorithm, seed)) {
      return false;
    }
    final copy = Uint8List.fromList(seed);
    try {
      await _client.importPqSeed(
        slot: int.parse(slotNumber, radix: 16),
        kind: kind,
        seed: copy,
        pinPolicy: pinPolicy.value,
        touchPolicy: touchPolicy.value,
      );
      return true;
    } on ProtocolException {
      return false;
    } finally {
      copy.fillRange(0, copy.length, 0);
    }
  }

  /// Normalized certificate object value; libcanokey adds the outer 53
  /// container and the PUT DATA framing/segmentation.
  Uint8List buildPivCert(Uint8List cert) {
    return Uint8List.fromList([
      0x70, 0x82, (cert.length >> 8) & 0xFF, cert.length & 0xFF,
      ...cert,
      0x71, 0x01, 0x00, // uncompressed
      0xFE, 0x00, // empty LRC
    ]);
  }

  Future<bool> _importCertInSession(String slot, Uint8List cert) async {
    final objectId = _certDO[int.parse(slot, radix: 16)];
    if (objectId == null) {
      return false;
    }
    try {
      await _client.writeObject(
        0x5FC100 + objectId,
        cert.isEmpty ? Uint8List(0) : buildPivCert(cert),
      );
      return true;
    } on ProtocolException {
      return false;
    }
  }

  Future<bool> clearSlotAuthenticated({
    required String slot,
    required String pin,
    required String managementKey,
    required bool usePinOnly,
  }) async {
    log.t('Call PivController.clearSlotAuthenticated');
    if (!supportsCurrentDevelopmentFeatures) {
      return false;
    }
    final c = Completer<bool>();
    await SmartCard.process((String sn) async {
      await _client.prepare();
      if (usePinOnly && !await _verifyPinInSession(pin)) {
        c.complete(false);
        return;
      }
      if (!await _authenticateManagementKeyOrPinOnly(
        pin,
        managementKey,
        usePinOnly,
      )) {
        c.complete(false);
        return;
      }
      try {
        await _client.deleteKey(int.parse(slot, radix: 16));
      } catch (_) {
        c.complete(false);
        return;
      }
      c.complete(await _importCertInSession(slot, Uint8List(0)));
    });
    if (!c.isCompleted) c.complete(false);
    return c.future;
  }

  Future<bool> moveKeyAuthenticated({
    required String sourceSlot,
    required String targetSlot,
    required String pin,
    required String managementKey,
    required bool usePinOnly,
  }) async {
    log.t('Call PivController.moveKeyAuthenticated');
    if (!supportsCurrentDevelopmentFeatures) {
      return false;
    }
    final c = Completer<bool>();
    await SmartCard.process((String sn) async {
      await _client.prepare();
      if (usePinOnly && !await _verifyPinInSession(pin)) {
        c.complete(false);
        return;
      }
      if (!await _authenticateManagementKeyOrPinOnly(
        pin,
        managementKey,
        usePinOnly,
      )) {
        c.complete(false);
        return;
      }
      try {
        await _client.moveKey(
          int.parse(sourceSlot, radix: 16),
          int.parse(targetSlot, radix: 16),
        );
        c.complete(true);
      } catch (_) {
        c.complete(false);
      }
    });
    if (!c.isCompleted) c.complete(false);
    return c.future;
  }

  Future<Uint8List?> attestKey(String slot) async {
    log.t('Call PivController.attestKey');
    if (!supportsCurrentDevelopmentFeatures) {
      return null;
    }
    final c = Completer<Uint8List?>();
    await SmartCard.process((String sn) async {
      await _client.prepare();
      try {
        c.complete(await _client.attest(int.parse(slot, radix: 16)));
      } on ProtocolException {
        c.complete(null);
      }
    });
    if (!c.isCompleted) c.complete(null);
    return c.future;
  }

  BigInt _randomSerialNumber() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[0] &= 0x7F;
    bytes[0] |= 0x01;
    return BigInt.parse(hex.encode(bytes), radix: 16);
  }

  /// Sign through libcanokey; host-side digest/padding stays here. ML-DSA-65
  /// messages and Ed25519 messages outside the classic input budget use the
  /// firmware streaming modes; SM2 keeps the host-computed ZA digest.
  Future<Uint8List?> _signInSession(
    String slot,
    AlgorithmType algorithm,
    Uint8List data,
    PivPublicKey? publicKey,
  ) async {
    final slotId = int.parse(slot, radix: 16);
    try {
      if (algorithm == AlgorithmType.mldsa65) {
        return await _client.signStreaming(slot: slotId, mode: 0, message: data);
      }
      if (algorithm == AlgorithmType.ed25519 &&
          (data.isEmpty || data.length > 512)) {
        // Randomized Ed25519; the signature still verifies as plain Ed25519.
        return await _client.signStreaming(slot: slotId, mode: 1, message: data);
      }
      return await _client.sign(
        slot: slotId,
        algorithm: algorithmExtensionConfig.idFor(algorithm),
        input: preparePivSigningInput(
          algorithm: algorithm.value,
          data: data,
          publicKey: publicKey?.rawPublicKey,
        ),
        inputKind: switch (algorithm) {
          AlgorithmType.rsa1024 ||
          AlgorithmType.rsa2048 ||
          AlgorithmType.rsa3072 ||
          AlgorithmType.rsa4096 => 0,
          AlgorithmType.ed25519 => 2,
          _ => 1,
        },
      );
    } on ProtocolException {
      return null;
    } on String {
      return null;
    }
  }

  bool _isValidPostQuantumSeed(AlgorithmType algorithm, Uint8List seed) =>
      (algorithm == AlgorithmType.mldsa65 && seed.length == 32) ||
      (algorithm == AlgorithmType.mlkem768 && seed.length == 64);

  Future<bool> _verifyPinInSession(String pin) async {
    final ok = await _client.verifyPin(pin);
    if (!ok) {
      Prompts.promptPinFailureResult(_client.lastStatusWord ?? '');
    }
    return ok;
  }

  Future<bool> _authenticateManagementKeyOrPinOnly(
    String pin,
    String managementKey,
    bool usePinOnly,
  ) async {
    if (usePinOnly) {
      final protectedKey = await _readProtectedManagementKeyInSession();
      if (protectedKey == null) {
        return false;
      }
      final ok = await _authenticateManagementKey(protectedKey);
      if (ok && pin.isNotEmpty) {
        // Match YubiKey tooling: when the protected key path is used, leave PIN
        // verification as the most recent successful authentication state.
        await _verifyPinInSession(pin);
      }
      return ok;
    }
    return _authenticateManagementKey(managementKey);
  }

  Future<bool> _authenticateManagementKey(String key) async {
    if (key.length != 48 || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(key)) {
      return false;
    }
    return _client.authenticateManagementKey(key, managementKeyAlgorithm);
  }

  Future<bool> _setManagementKeyInSession(
    String key, {
    required TouchPolicy touchPolicy,
  }) async {
    if (key.length != 48 || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(key)) {
      return false;
    }
    final bytes = Uint8List.fromList(hex.decode(key));
    try {
      await _client.setManagementKey(
        algorithm: managementKeyAlgorithm.value,
        key: bytes,
        touch: managementKeyAlgorithm == AlgorithmType.aes192 &&
                touchPolicy == TouchPolicy.always
            ? 1
            : 0,
      );
      return true;
    } on ProtocolException {
      return false;
    } finally {
      bytes.fillRange(0, bytes.length, 0);
    }
  }

  AlgorithmType get managementKeyAlgorithm =>
      managementKeyInfo?.algorithm ?? AlgorithmType.tdes;

  TouchPolicy get managementKeyTouchPolicy =>
      managementKeyInfo?.touchPolicy ?? TouchPolicy.never;

  bool get supportsManagementKeyTouchPolicy =>
      managementKeyAlgorithm == AlgorithmType.aes192;

  Future<bool> _readPinOnlyModeInSession() async {
    final data = await _getDataObject(_pivmanDataObject);
    if (data == null || data.isEmpty) {
      return false;
    }
    return _pivmanFlags(data) & _pivmanManagementKeyProtectedFlag != 0;
  }

  Future<String?> _readProtectedManagementKeyInSession() async {
    final data = await _getDataObject(_pivmanProtectedDataObject);
    if (data == null || data.isEmpty) {
      return null;
    }
    try {
      final parsed = TLV.parse(data);
      final inner = parsed[_pivmanProtectedDataTag];
      if (inner is List<int>) {
        final innerMap = TLV.parse(inner);
        final key = innerMap[_pivmanProtectedKeyTag];
        if (key is List<int> && key.length == 24) {
          return hex.encode(key);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<bool> _writePinOnlyObjects(
    String managementKey, {
    required bool enabled,
  }) async {
    final adminData = await _getDataObject(_pivmanDataObject);
    final newFlags = enabled
        ? _pivmanFlags(adminData) |
              _pivmanManagementKeyProtectedFlag |
              _pivmanPukBlockedFlag
        : _pivmanFlags(adminData) & ~_pivmanManagementKeyProtectedFlag;
    final adminOk = await _putDataObject(
      _pivmanDataObject,
      _buildPivmanData(adminData, newFlags),
    );
    if (!adminOk) {
      return false;
    }
    final protectedData = enabled
        ? Uint8List.fromList([
            _pivmanProtectedDataTag,
            0x1A,
            _pivmanProtectedKeyTag,
            0x18,
            ...hex.decode(managementKey),
          ])
        : Uint8List(0);
    return _putDataObject(_pivmanProtectedDataObject, protectedData);
  }

  int _pivmanFlags(List<int>? data) {
    if (data == null || data.isEmpty) {
      return 0;
    }
    try {
      final parsed = TLV.parse(data);
      final inner = parsed[_pivmanDataTag];
      if (inner is List<int>) {
        final innerMap = TLV.parse(inner);
        final flags = innerMap[_pivmanFlagsTag];
        if (flags is List<int> && flags.isNotEmpty) {
          return flags.first;
        }
      }
    } catch (_) {
      return 0;
    }
    return 0;
  }

  Uint8List _buildPivmanData(List<int>? existing, int flags) {
    List<int>? salt;
    List<int>? pinTimestamp;
    if (existing != null && existing.isNotEmpty) {
      try {
        final parsed = TLV.parse(existing);
        final inner = parsed[_pivmanDataTag];
        if (inner is List<int>) {
          final innerMap = TLV.parse(inner);
          final parsedSalt = innerMap[_pivmanSaltTag];
          final parsedPinTimestamp = innerMap[_pivmanPinTimestampTag];
          if (parsedSalt is List<int>) {
            salt = parsedSalt;
          }
          if (parsedPinTimestamp is List<int>) {
            pinTimestamp = parsedPinTimestamp;
          }
        }
      } catch (_) {}
    }
    final inner = <int>[];
    if (flags != 0) {
      inner.addAll([_pivmanFlagsTag, 0x01, flags]);
    }
    if (salt != null) {
      inner.addAll(hex.decode(_tlv(_pivmanSaltTag, salt)));
    }
    if (pinTimestamp != null) {
      inner.addAll(hex.decode(_tlv(_pivmanPinTimestampTag, pinTimestamp)));
    }
    if (inner.isEmpty) {
      return Uint8List(0);
    }
    return Uint8List.fromList(hex.decode(_tlv(_pivmanDataTag, inner)));
  }

  Future<List<int>?> _getDataObject(int objectId) =>
      _client.readObject(objectId);

  Future<bool> _putDataObject(int objectId, Uint8List data) async {
    await _client.writeObject(objectId, data);
    return true;
  }

  String _tlv(int tag, List<int> value) {
    return tag.toRadixString(16).padLeft(2, '0') +
        _hexLength(value.length) +
        hex.encode(value);
  }

  String _hexLength(int length) {
    if (length <= 0x7F) {
      return length.toRadixString(16).padLeft(2, '0');
    }
    if (length <= 0xFF) {
      return '81${length.toRadixString(16).padLeft(2, '0')}';
    }
    return '82${length.toRadixString(16).padLeft(4, '0')}';
  }

  final Map<int, int> _certDO = {
    0x9A: 0x05,
    0x9C: 0x0A,
    0x9D: 0x0B,
    0x9E: 0x01,
    for (var slot = 0x82; slot <= 0x95; slot++) slot: slot - 0x75,
  };

  List<int> get _keySlots => [
    0x9A,
    0x9C,
    0x9D,
    0x9E,
    ...(extendedRetiredSlots ? _extendedRetiredSlots : _legacyRetiredSlots),
  ];

  final List<int> _legacyRetiredSlots = [0x82, 0x83];

  final List<int> _extendedRetiredSlots = [
    for (var slot = 0x82; slot <= 0x95; slot++) slot,
  ];

  static const int _pivmanDataObject = 0x5FFF00;
  static const int _pivmanProtectedDataObject = 0x5FC109;
  static const int _pivmanDataTag = 0x80;
  static const int _pivmanFlagsTag = 0x81;
  static const int _pivmanSaltTag = 0x82;
  static const int _pivmanPinTimestampTag = 0x83;
  static const int _pivmanProtectedDataTag = 0x88;
  static const int _pivmanProtectedKeyTag = 0x89;
  static const int _pivmanPukBlockedFlag = 0x01;
  static const int _pivmanManagementKeyProtectedFlag = 0x02;
}
