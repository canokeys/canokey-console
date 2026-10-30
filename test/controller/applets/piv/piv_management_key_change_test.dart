import 'dart:async';
import 'package:canokey_console/controller/applets/piv/piv_controller.dart';
import 'package:canokey_console/helper/utils/piv_card.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/tlv.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

const _oldKey = '010203040506070801020304050607080102030405060708';
const _newKey = '080706050403020108070605040302010807060504030201';
const _adminId = 0x5fff00;
const _protectedId = 0x5fc109;

class _ManagementClient extends PivCardClient {
  final events = <String>[];
  Uint8List admin = Uint8List.fromList([0x80, 3, 0x81, 1, 3]);
  Uint8List protected = Uint8List.fromList([
    0x88,
    26,
    0x89,
    24,
    ...hex.decode(_oldKey),
  ]);
  String actualKey = _oldKey;
  bool refreshFails = false,
      readFails = false,
      writeSetLost = false,
      setApplied = true;
  bool writeProtectedFails = false,
      writeProtectedLost = false,
      writeAdminLost = false;
  bool newAuthLost = false, newAuthRejected = false;

  @override
  Future<void> prepare() async {
    events.add('prepare');
  }

  @override
  Future<void> prepareIfStale() async {
    events.add('prepare-if-stale');
  }

  @override
  Future<bool> verifyPin(String pin) async {
    events.add('verify');
    return pin == '123456';
  }

  @override
  Future<bool> authenticateManagementKey(
    String key,
    AlgorithmType algorithm,
  ) async {
    events.add(key == _newKey ? 'authenticate-new' : 'authenticate-old');
    if (key == _newKey && newAuthLost) throw PlatformException(code: '500');
    if (key == _newKey && newAuthRejected) return false;
    return key == actualKey;
  }

  @override
  Future<bool> blockPuk() async {
    events.add('block-puk');
    return true;
  }

  @override
  Future<void> setManagementKey({
    required int algorithm,
    required Uint8List key,
    int touch = 0,
    bool updateProtected = false,
  }) async {
    events.add('set-key');
    if (setApplied) actualKey = hex.encode(key);
    if (writeSetLost) throw PlatformException(code: '500');
  }

  @override
  Future<Uint8List?> readObject(int objectId) async {
    events.add(objectId == _adminId ? 'read-admin' : 'read-protected');
    if (objectId == _protectedId && readFails) {
      throw PlatformException(code: '500');
    }
    return Uint8List.fromList(objectId == _adminId ? admin : protected);
  }

  @override
  Future<void> writeObject(int objectId, Uint8List data) async {
    events.add(objectId == _adminId ? 'write-admin' : 'write-protected');
    if (objectId == _protectedId) {
      if (writeProtectedFails) throw PlatformException(code: '500');
      protected = Uint8List.fromList(data);
      if (writeProtectedLost) throw PlatformException(code: '500');
    } else {
      admin = Uint8List.fromList(data);
      if (writeAdminLost) throw PlatformException(code: '500');
    }
  }

  @override
  Future<SlotInfo?> readMetadata(int reference) async {
    SmartCard.currentLease.check();
    events.add('metadata');
    if (refreshFails) throw StateError('read interrupted after commit');
    return SlotInfo(
      reference,
      AlgorithmType.aes192,
      PinPolicy.once,
      TouchPolicy.never,
      Origin.generated,
      [],
      false,
      3,
      3,
    );
  }
}

class _RefreshController extends PivController {
  final leases = <Object>[];
  bool fail = false;
  @override
  Future<void> doRefreshData() => SmartCard.process((_) async {
    leases.add(SmartCard.currentLease);
    if (fail) throw StateError('refresh interrupted after commit');
  });
}

PivController _controller(_ManagementClient client) =>
    PivController(client: client)
      ..firmwareVersion = const FirmwareVersion(3, 1, 1)
      ..functionSetVersion = FunctionSetVersion.v5
      ..pinOnlyMode = true
      ..polled = true;
Future<PivManagementKeyChangeResult> _change(
  PivController controller, {
  bool store = true,
  bool usePinOnly = true,
}) => controller.changeManagementKey(
  usePinOnly ? '' : _oldKey,
  _newKey,
  pin: '123456',
  usePinOnly: usePinOnly,
  storeOnDevice: store,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SmartCard.connectionType = ConnectionType.ccid);
  tearDown(() => SmartCard.connectionType = ConnectionType.none);
  test(
    'post-write refresh bypasses a queued page refresh and marks stale data',
    () async {
      final controller = _RefreshController()..polled = true;
      final ready = Completer<void>();
      final proceed = Completer<void>();
      final mutation = SmartCard.processSequence(() async {
        ready.complete();
        await proceed.future;
        controller.fail = true;
        await controller.refreshAfterMutation();
        controller.fail = false;
        expect(controller.polled, isFalse);
      });
      await ready.future;
      final queuedRefresh = controller.refreshData();
      proceed.complete();
      await Future.wait([
        mutation,
        queuedRefresh,
      ]).timeout(const Duration(seconds: 5));
      expect(controller.leases, hasLength(2));
      expect(
        identical(controller.leases.first, controller.leases.last),
        isFalse,
      );
    },
  );

  for (final (store, usePinOnly) in [(true, true), (false, false)]) {
    test(
      'key rotation preserves or removes protection, protected=$store',
      () async {
        final client = _ManagementClient();
        final controller = _controller(client);
        expect(
          await _change(controller, store: store, usePinOnly: usePinOnly),
          PivManagementKeyChangeResult.success,
        );
        expect(client.events.takeWhile((event) => event != 'metadata'), [
          'prepare',
          'read-admin',
          'verify',
          'read-protected',
          'authenticate-old',
          'verify',
          'set-key',
          if (!store) 'write-admin',
          'write-protected',
        ]);
        expect(controller.pinOnlyMode, store);
        expect(controller.hasPendingManagementKeyChange, isFalse);
        expect(controller.pendingManagementKey, isEmpty);
        expect(
          store
              ? hex.encode(TLV.parse(TLV.parse(client.protected)[0x88])[0x89])
              : hex.encode(client.protected),
          store ? _newKey : '',
        );
      },
    );
  }

  test('preflight failure does not replace the key', () async {
    final client = _ManagementClient()..readFails = true;
    final controller = _controller(client);
    expect(await _change(controller), PivManagementKeyChangeResult.failed);
    expect(client.actualKey, _oldKey);
    expect(client.events, isNot(contains('set-key')));
    expect(controller.hasPendingManagementKeyChange, isFalse);
  });

  test('malformed protected object stops before changing the key', () async {
    final client = _ManagementClient()
      ..protected = Uint8List.fromList([0x88, 255]);
    final controller = _controller(client);
    expect(await _change(controller), PivManagementKeyChangeResult.failed);
    expect(client.events, isNot(contains('set-key')));
  });

  test(
    'clears derived salt, preserves other metadata, and writes changed admin first',
    () async {
      final client = _ManagementClient()
        ..admin = Uint8List.fromList([
          0x80,
          9,
          0x81,
          1,
          3,
          0x82,
          1,
          42,
          0x83,
          1,
          7,
        ]);
      final controller = _controller(client);
      expect(await _change(controller), PivManagementKeyChangeResult.success);
      final fields = TLV.parse(TLV.parse(client.admin)[0x80]);
      expect(fields.containsKey(0x82), isFalse);
      expect(fields[0x83], [7]);
      expect(
        client.events.indexOf('write-admin'),
        lessThan(client.events.indexOf('write-protected')),
      );
    },
  );

  test(
    'committed object response loss is checked before any repeated writes',
    () async {
      final client = _ManagementClient()..writeProtectedLost = true;
      final controller = _controller(client);
      expect(
        await _change(controller),
        PivManagementKeyChangeResult.keyChangedProtectionIncomplete,
      );
      expect(controller.polled, isFalse);
      client.writeProtectedLost = false;
      final before = client.events.length;
      expect(
        await controller.continueManagementKeyChange('123456'),
        PivManagementKeyChangeResult.success,
      );
      expect(client.events.sublist(before), [
        'prepare',
        'authenticate-new',
        'verify',
        'read-admin',
        'read-protected',
        'metadata',
        'metadata',
        'metadata',
        'read-admin',
      ]);
      expect(client.events.where((e) => e == 'set-key'), hasLength(1));
      expect(client.events.where((e) => e == 'write-protected'), hasLength(1));
    },
  );

  test(
    'admin response loss resumes only the remaining protected write',
    () async {
      final client = _ManagementClient()..writeAdminLost = true;
      final controller = _controller(client);
      expect(
        await _change(controller, store: false),
        PivManagementKeyChangeResult.keyChangedProtectionIncomplete,
      );
      client.writeAdminLost = false;
      expect(
        await controller.continueManagementKeyChange('123456'),
        PivManagementKeyChangeResult.success,
      );
      expect(client.events.where((e) => e == 'write-admin'), hasLength(1));
      expect(client.events.where((e) => e == 'write-protected'), hasLength(1));
      expect(client.events.where((e) => e == 'set-key'), hasLength(1));
    },
  );

  for (final lost in ['protected', 'set']) {
    test('continues interrupted $lost without another key rotation', () async {
      final client = _ManagementClient()
        ..writeProtectedFails = lost == 'protected'
        ..writeSetLost = lost == 'set';
      final controller = _controller(client);
      expect(
        await _change(controller),
        lost == 'set'
            ? PivManagementKeyChangeResult.outcomeUnknown
            : PivManagementKeyChangeResult.keyChangedProtectionIncomplete,
      );
      expect(controller.pendingManagementKey, _newKey);
      client
        ..writeProtectedFails = false
        ..writeSetLost = false;
      // Even calling the normal API with different inputs must resume the
      // original request, rather than silently replacing its key or policy.
      expect(
        await controller.changeManagementKey('', '09' * 24, pin: '123456'),
        PivManagementKeyChangeResult.success,
      );
      expect(client.actualKey, _newKey);
      expect(client.events.where((e) => e == 'set-key'), hasLength(1));
      expect(client.events, isNot(contains('block-puk')));
      expect(
        hex.encode(TLV.parse(TLV.parse(client.protected)[0x88])[0x89]),
        _newKey,
      );
      expect(controller.hasPendingManagementKeyChange, isFalse);
    });
  }

  test(
    'lost SET response with old key active requires a separate explicit retry',
    () async {
      final client = _ManagementClient()
        ..writeSetLost = true
        ..setApplied = false;
      final controller = _controller(client);
      expect(
        await _change(controller),
        PivManagementKeyChangeResult.outcomeUnknown,
      );
      expect(
        await controller.continueManagementKeyChange('123456'),
        PivManagementKeyChangeResult.previousKeyStillActive,
      );
      expect(client.events.where((e) => e == 'set-key'), hasLength(1));
      expect(client.events, isNot(contains('write-protected')));
      expect(controller.hasPendingManagementKeyChange, isFalse);
      client
        ..writeSetLost = false
        ..setApplied = true;
      expect(await _change(controller), PivManagementKeyChangeResult.success);
      expect(client.events.where((e) => e == 'set-key'), hasLength(2));
    },
  );

  for (final failure in ['transport', 'rejected', 'data-changed']) {
    test('continuation stops without writes on $failure', () async {
      final client = _ManagementClient()..writeProtectedFails = true;
      final controller = _controller(client);
      expect(
        await _change(controller),
        PivManagementKeyChangeResult.keyChangedProtectionIncomplete,
      );
      client
        ..writeProtectedFails = false
        ..newAuthLost = failure == 'transport'
        ..newAuthRejected = failure == 'rejected';
      if (failure == 'data-changed') {
        client.admin = Uint8List.fromList([0x80, 3, 0x81, 1, 7]);
      }
      final before = client.events.length;
      final result = await controller.continueManagementKeyChange('123456');
      expect(
        result,
        failure == 'transport'
            ? PivManagementKeyChangeResult.keyChangedProtectionIncomplete
            : failure == 'rejected'
            ? PivManagementKeyChangeResult.authenticationFailed
            : PivManagementKeyChangeResult.cardStateChanged,
      );
      expect(
        client.events.sublist(before),
        isNot(contains('authenticate-old')),
      );
      expect(
        client.events
            .sublist(before)
            .where((e) => e.startsWith('write-') || e == 'set-key'),
        isEmpty,
      );
      expect(controller.hasPendingManagementKeyChange, isTrue);
    });
  }

  test('refresh failure does not downgrade a completed mutation', () async {
    final client = _ManagementClient()..refreshFails = true;
    final controller = _controller(client);
    expect(await _change(controller), PivManagementKeyChangeResult.success);
    expect(controller.hasPendingManagementKeyChange, isFalse);
    expect(controller.polled, isFalse);
  });

  test('closing the page clears pending secrets', () async {
    final client = _ManagementClient()..writeProtectedFails = true;
    final controller = _controller(client);
    await _change(controller);
    expect(controller.pendingManagementKey, _newKey);
    controller.onClose();
    expect(controller.hasPendingManagementKeyChange, isFalse);
    expect(controller.pendingManagementKey, isEmpty);
  });
}
