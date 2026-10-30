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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SmartCard.connectionType = ConnectionType.ccid);
  tearDown(() => SmartCard.connectionType = ConnectionType.none);

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
