import 'dart:typed_data';

import 'package:canokey_console/controller/applets/piv/piv_controller.dart';
import 'package:canokey_console/helper/utils/applet_switches.dart';
import 'package:canokey_console/helper/utils/piv_card.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:flutter_test/flutter_test.dart';

class _Client extends PivCardClient {
  bool fail = false;
  int remaining = 3;
  int slot = 0x9A;

  @override
  Future<void> prepare() async {}
  @override
  Future<PivAlgorithmExtensionConfig?> readAlgorithmExtensions({
    String? managementKey,
    AlgorithmType managementKeyAlgorithm = AlgorithmType.tdes,
  }) async => null;
  @override
  Future<SlotInfo?> readMetadata(int reference) async {
    if (fail && reference == 0x81) throw StateError('read interrupted');
    return SlotInfo(
      reference,
      AlgorithmType.pin,
      PinPolicy.once,
      TouchPolicy.never,
      Origin.generated,
      [],
      false,
      3,
      remaining,
    );
  }

  @override
  Future<Uint8List?> readObject(int objectId) async => Uint8List(0);
  @override
  Future<Uint8List> readMetadataDirectory() async =>
      Uint8List.fromList([1, 1, 1, 2, 6, slot, 3, 0x11, 1, 2, 1]);
}

class _LegacyOccupiedClient extends _Client {
  @override
  Future<SlotInfo?> readMetadata(int reference) async {
    if ([0x80, 0x81, 0x9b].contains(reference)) {
      return super.readMetadata(reference);
    }
    if (reference != 0x9d) return null;
    return SlotInfo(
      reference,
      AlgorithmType.unknown,
      PinPolicy.once,
      TouchPolicy.never,
      Origin.generated,
      [],
      false,
      0,
      0,
      wireAlgorithm: 0x53,
    );
  }

  @override
  Future<Uint8List?> readCertificate(int objectId) async => null;
}

class _AutoConfigurationClient extends _LegacyOccupiedClient {
  _AutoConfigurationClient({
    this.defaultKey = true,
    this.acceptDefault = true,
    this.publicConfiguration = false,
    this.protectedKey = false,
  });
  final bool defaultKey, acceptDefault, publicConfiguration, protectedKey;
  bool authenticated = false;
  final authenticationAttempts = <String>[];
  int pinAttempts = 0;

  @override
  Future<PivAlgorithmExtensionConfig?> readAlgorithmExtensions({
    String? managementKey,
    AlgorithmType managementKeyAlgorithm = AlgorithmType.tdes,
  }) async => publicConfiguration || authenticated
      ? PivAlgorithmExtensionConfig.defaults
      : null;

  @override
  Future<bool> authenticateManagementKey(
    String key,
    AlgorithmType algorithm,
  ) async {
    authenticationAttempts.add(key);
    authenticated = acceptDefault;
    return authenticated;
  }

  @override
  Future<bool> verifyPin(String pin) async {
    pinAttempts++;
    throw StateError('Reading public configuration must not verify a PIN');
  }

  @override
  Future<SlotInfo?> readMetadata(int reference) async {
    if (reference == 0x9b) {
      return SlotInfo(
        reference,
        AlgorithmType.tdes,
        PinPolicy.defaultPolicy,
        TouchPolicy.never,
        Origin.generated,
        [],
        defaultKey,
        0,
        0,
      );
    }
    if (reference == 0x9d && (publicConfiguration || authenticated)) {
      return SlotInfo(
        reference,
        AlgorithmType.secp256k1,
        PinPolicy.once,
        TouchPolicy.never,
        Origin.generated,
        [],
        false,
        0,
        0,
        wireAlgorithm: 0x53,
      );
    }
    return super.readMetadata(reference);
  }

  @override
  Future<Uint8List?> readObject(int id) async => Uint8List.fromList(
    protectedKey && id == 0x5fff00 ? [0x80, 3, 0x81, 1, 2] : [],
  );

  @override
  Future<Uint8List> readMetadataDirectory() async =>
      Uint8List.fromList([1, 1, 1, 2, 6, 0x9d, 1, 0x53, 1, 2, 1]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SmartCard.connectionType = ConnectionType.ccid);
  tearDown(() => SmartCard.connectionType = ConnectionType.none);

  for (final scenario in [
    (name: 'default key', defaultKey: true, accepted: true),
    (name: 'custom key', defaultKey: false, accepted: true),
    (name: 'rejected default key', defaultKey: true, accepted: false),
  ]) {
    test('3.0.3 page loads with ${scenario.name}', () async {
      final client = _AutoConfigurationClient(
        defaultKey: scenario.defaultKey,
        acceptDefault: scenario.accepted,
      );
      final controller = PivController(
        client: client,
        readAppletStatus: () async => AppletSwitchStatus.fromConfig(
          firmwareVersion: const FirmwareVersion(3, 0, 3),
          functionSetVersion: FunctionSetVersion.v4,
          config: [0, 0, 0, 0, 0, 0xff],
        ),
      );
      try {
        await controller.refreshData();
        expect(controller.hasLoadedData, isTrue);
        expect(controller.dataRefreshFailed, isFalse);
        expect(
          client.authenticationAttempts,
          scenario.defaultKey
              ? ['010203040506070801020304050607080102030405060708']
              : isEmpty,
        );
        expect(client.pinAttempts, 0);
        expect(
          controller.slots[0x9d]!.algorithm,
          scenario.defaultKey && scenario.accepted
              ? AlgorithmType.secp256k1
              : AlgorithmType.unknown,
        );
      } finally {
        controller.onClose();
      }
    });
  }

  test(
    'PIN-protected 3.1 configuration loads without PIN or management authentication',
    () async {
      final client = _AutoConfigurationClient(
        defaultKey: false,
        publicConfiguration: true,
        protectedKey: true,
      );
      final controller = PivController(
        client: client,
        readAppletStatus: () async => AppletSwitchStatus.fromConfig(
          firmwareVersion: const FirmwareVersion(3, 1, 0),
          functionSetVersion: FunctionSetVersion.v5,
          config: [0, 0, 0, 0, 0, 0xff],
        ),
      );
      try {
        await controller.refreshData();
        expect(controller.hasLoadedData, isTrue);
        expect(controller.pinOnlyMode, isTrue);
        expect(controller.slots[0x9d]!.algorithm, AlgorithmType.secp256k1);
        expect(client.authenticationAttempts, isEmpty);
        expect(client.pinAttempts, 0);
      } finally {
        controller.onClose();
      }
    },
  );

  test('3.0.3 page refresh keeps an unresolved key occupied', () async {
    final controller = PivController(
      client: _LegacyOccupiedClient(),
      readAppletStatus: () async => AppletSwitchStatus.fromConfig(
        firmwareVersion: const FirmwareVersion(3, 0, 3),
        functionSetVersion: FunctionSetVersion.v4,
        config: [0, 0, 0, 0, 0, 0xff],
      ),
    );
    try {
      await controller.refreshData();
      expect(controller.hasLoadedData, isTrue);
      expect(controller.polled, isTrue);
      expect(controller.dataRefreshFailed, isFalse);
      expect(controller.slots.keys, [0x9d]);
      final slot = controller.slots[0x9d]!;
      expect(slot.algorithm, AlgorithmType.unknown);
      expect(slot.wireAlgorithm, 0x53);
      expect(controller.publicKeyForSlot(slot), isNull);
      expect(controller.supportsAlgorithm(AlgorithmType.unknown), isFalse);
    } finally {
      controller.onClose();
    }
  });

  test(
    'failed refresh retains a complete snapshot and next read replaces it',
    () async {
      final client = _Client();
      final controller = PivController(
        client: client,
        readAppletStatus: () async => AppletSwitchStatus.fromConfig(
          firmwareVersion: const FirmwareVersion(3, 1, 1),
          functionSetVersion: FunctionSetVersion.v5,
          config: [0, 0, 0, 0, 0, 0xff],
        ),
      );
      await controller.refreshData();
      expect(controller.hasLoadedData, isTrue);
      expect(controller.slots.keys, [0x9A]);
      expect(controller.certificateSlots, {0x9A});
      expect(controller.pinRetriesRemaining, 3);
      // Cache a certificate as though the user opened slot details.
      controller.certificateBytes[0x9A] = Uint8List.fromList([1, 2]);
      client
        ..fail = true
        ..remaining = 1
        ..slot = 0x9C;
      await SmartCard.processSequence(controller.refreshAfterMutation);
      expect(controller.polled, isFalse);
      expect(controller.hasLoadedData, isTrue);
      expect(controller.dataRefreshFailed, isTrue);
      expect(controller.slots.keys, [0x9A]);
      expect(controller.certificateSlots, {0x9A});
      expect(controller.certificateBytes[0x9A], [1, 2]);
      expect(controller.pinRetriesRemaining, 3);
      client.fail = false;
      await controller.refreshData();
      expect(controller.polled, isTrue);
      expect(controller.dataRefreshFailed, isFalse);
      expect(controller.slots.keys, [0x9C]);
      expect(controller.certificateSlots, {0x9C});
      expect(controller.certificateBytes, isEmpty);
      expect(controller.pinRetriesRemaining, 1);
      // The polling timer can flag a lost transport without hiding this data.
      controller.polled = false;
      expect(controller.hasLoadedData, isTrue);
      controller.onClose();
    },
  );
}
