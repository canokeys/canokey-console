import 'dart:typed_data';
import 'package:canokey_console/controller/applets/piv/piv_controller.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:canokey_console/models/piv_macos_setup.dart';
import 'package:flutter_test/flutter_test.dart';

PivMacOsSetupSlot entry(
  String slot, {
  bool key = false,
  bool cert = false,
  bool compatible = false,
}) => PivMacOsSetupSlot(
  slotNumber: slot,
  key: key
      ? SlotInfo(
          int.parse(slot, radix: 16),
          AlgorithmType.eccp256,
          PinPolicy.once,
          TouchPolicy.always,
          Origin.generated,
          [1, 2],
          false,
          0,
          0,
        )
      : null,
  certificate: cert ? [3, 4] : null,
  compatible: compatible,
);

class SetupController extends PivController {
  SetupController(List<PivMacOsSetupSlot> slots)
    : state = PivMacOsSetupPlan(serial: 'card', slots: slots);
  PivMacOsSetupPlan state;
  String? failSlot;
  final writes = <String>[];
  final reused = <bool>[];
  @override
  Future<PivMacOsSetupPlan?> inspectMacOsSetup() async => state;
  @override
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
    writes.add(slot);
    reused.add(reuseExistingKey);
    expect(expectedSerial, state.serial);
    expect(
      expectedState!.sameContents(
        state.slots.firstWhere((s) => s.slotNumber == slot),
      ),
      isTrue,
    );
    expect(keyUsage, slot == '9A' ? 1 : 16);
    if (slot == failSlot) return null;
    state = PivMacOsSetupPlan(
      serial: state.serial,
      slots: [
        for (final old in state.slots)
          old.slotNumber == slot
              ? entry(slot, key: true, cert: true, compatible: true)
              : old,
      ],
    );
    return Uint8List.fromList([3, 4]);
  }
}

Future<bool> run(
  SetupController c, {
  PivMacOsSetupPlan? plan,
  bool consent = false,
}) => c.configureMacOsLogin(
  plan: plan ?? c.state,
  pin: '123456',
  managementKey: '',
  usePinOnly: true,
  allowReplacement: consent,
  onProgress: (_, _) {},
);

void main() {
  test('preserves configured 9A and creates only missing 9D', () async {
    final c = SetupController([
      entry('9A', key: true, cert: true, compatible: true),
      entry('9D'),
    ]);
    expect(await run(c), isTrue);
    expect(c.writes, ['9D']);
    expect(c.reused, [false]);
  });
  test('reuses an existing key when adding its certificate', () async {
    final c = SetupController([entry('9A', key: true), entry('9D', key: true)]);
    expect(await run(c), isTrue);
    expect(c.reused, [true, true]);
  });
  test('replacement requires consent before any writes', () async {
    final c = SetupController([
      entry('9A', key: true, cert: true),
      entry('9D'),
    ]);
    expect(await run(c), isFalse);
    expect(c.writes, isEmpty);
    expect(await run(c, consent: true), isTrue);
    expect(c.reused.first, isTrue);
  });
  test('changed card or contents invalidates reviewed plan', () async {
    final c = SetupController([entry('9A'), entry('9D')]);
    final reviewed = c.state;
    c.state = PivMacOsSetupPlan(serial: 'other', slots: reviewed.slots);
    expect(await run(c, plan: reviewed), isFalse);
    expect(c.writes, isEmpty);
    c.state = PivMacOsSetupPlan(
      serial: 'card',
      slots: [entry('9A', key: true), entry('9D')],
    );
    expect(await run(c, plan: reviewed), isFalse);
    expect(c.writes, isEmpty);
  });
  test('retry after 9D failure preserves completed 9A', () async {
    final c = SetupController([entry('9A'), entry('9D')])..failSlot = '9D';
    expect(await run(c), isFalse);
    c.failSlot = null;
    expect(await run(c), isTrue);
    expect(c.writes, ['9A', '9D', '9D']);
  });
}
