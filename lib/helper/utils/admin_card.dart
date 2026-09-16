import 'dart:convert';
import 'dart:typed_data';

import 'package:canokey_console/helper/utils/card_client.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/models/webauthn.dart';
import 'package:canokey_console/src/rust/api/protocol.dart';
import 'package:convert/convert.dart';

/// Shared Admin-facade plumbing for clients whose upstream operations either
/// SELECT Admin and explicitly verify a PIN, or reuse this lease's recorded
/// Admin authentication via `Access::Existing`. That session evidence is
/// recorded only by a successful explicit VerifyPin on the same lease and is
/// bound to the lease's selection/profile generations; a UI PIN cache is never
/// authorization.
abstract class AdminSessionCardClient extends ProfileCardClient {
  AdminSessionCardClient({super.transport, super.lease})
    : super(bindSelection: false);

  /// Progress of the most recent Admin operation, including after a failure.
  AdminProgress? lastProgress;

  /// Runs one Admin request. When this lease holds a still-valid recorded
  /// Admin authentication (see CardLease.recordAdminAuthentication) and the
  /// caller allows it, the request uses `Access::Existing`: no SELECT and no
  /// VERIFY are sent, and any supplied PIN stays unused. A PIN-less request
  /// also uses `Access::Existing` while the probe's Admin selection is still
  /// current, skipping a redundant SELECT — unless [selectionSufficient] is
  /// false for requests whose target is card-gated regardless of firmware
  /// (Pass slots); there the card remains the enforcement point either way.
  /// Otherwise the request SELECTs and verifies only the explicitly supplied
  /// PIN.
  Future<AdminResult> executeAdminRequest(
    ProtocolOperation Function(
      ProtocolProfile profile,
      Uint8List? pin,
      bool existing,
    )
    create, {
    String? pin,
    bool existingAllowed = true,
    bool selectionSufficient = true,
    bool mutation = false,
  }) async {
    final binding = preparedBinding;
    lastStatusWord = null;
    lastProgress = null;
    final existing =
        existingAllowed &&
        (binding.lease.hasAdminAuthentication ||
            (selectionSufficient && pin == null && binding.selectionFresh));
    if (!existing) {
      // Selecting factories invalidate any selected PIV context before
      // starting, even though immutable Admin profile evidence can be reused.
      binding.lease.willSelectApplet();
    }
    final pinBytes = existing || pin == null
        ? null
        : Uint8List.fromList(utf8.encode(pin));
    try {
      final result = await executeAdminOperation(
        create(binding.profile, pinBytes, existing),
        transport,
        lease: binding.lease,
        cancellation: cancellation,
        onProgress: (progress) => lastProgress = progress,
      );
      binding.check();
      cancellation.check();
      lastStatusWord = '9000';
      return result;
    } on ProtocolException catch (error) {
      lastStatusWord = formatStatusWord(error.details.statusWord);
      // A failed Existing request leaves the card-side session state
      // uncertain; later requests must re-establish evidence or use a PIN.
      if (existing) binding.lease.invalidateAdminAuthentication();
      rethrow;
    } catch (_) {
      discardProfile(binding);
      rethrow;
    } finally {
      pinBytes?.fillRange(0, pinBytes.length, 0);
      final progress = lastProgress;
      // An exposed or uncertain mutation ends the authenticated session
      // evidence; no-op patches and pre-I/O validation failures retain it.
      if (mutation &&
          progress != null &&
          (progress.confirmedWrites > 0 || progress.reprobeRequired)) {
        binding.lease.invalidateAdminAuthentication();
      }
      if (progress?.reprobeRequired == true) {
        binding.lease.invalidateProfileEvidence();
        discardProfile(binding);
      }
    }
  }
}

/// Each upstream Admin operation either SELECTs and explicitly authenticates
/// its own request, or reuses this lease's authenticated Admin session via
/// `Access::Existing`. That session evidence is recorded only by a successful
/// explicit [verifyPin] on the same lease and is bound to the lease's
/// selection/profile generations; a UI PIN cache is never authorization.
class AdminCardClient extends AdminSessionCardClient {
  AdminCardClient({super.transport, super.lease});

  /// Explicit minimal discovery, before any authentication. Repeat after a
  /// profile-affecting write, including an uncertain write; never auto-reprobe.
  Future<void> prepare() => prepareProfile(
    () => ProtocolOperation.probeAdmin(observedSerial: lease.bootstrapSerial),
  );

  /// Explicit discovery only when the prepared binding is missing or stale.
  /// A still-valid binding is reused as-is, preserving the lease's recorded
  /// Admin session evidence; discovery is never repeated implicitly.
  Future<void> prepareIfStale() async {
    final binding = currentProfile;
    if (binding != null && identical(binding.lease, lease)) {
      try {
        binding.check();
        cancellation.check();
        return;
      } on StateError {
        // Fall through to explicit discovery below.
      }
    }
    await prepare();
  }

  Future<AdminResult> _read(AdminReadOperation kind, {String? pin}) =>
      executeAdminRequest(
        (profile, pinBytes, existing) =>
            profile.adminRead(kind: kind, pin: pinBytes, existing: existing),
        pin: pin,
      );

  Future<void> _action(
    AdminAction kind, {
    String? pin,
    List<int> data = const [],
    int index = 0,
    int value = 0,
    bool existingAllowed = true,
    bool mutation = true,
  }) async {
    final payload = Uint8List.fromList(data);
    try {
      await executeAdminRequest(
        (profile, pinBytes, existing) => profile.adminAction(
          kind: kind,
          pin: pinBytes,
          data: payload,
          index: index,
          value: value,
          existing: existing,
        ),
        pin: pin,
        existingAllowed: existingAllowed,
        mutation: mutation,
      );
    } finally {
      payload.fillRange(0, payload.length, 0);
    }
  }

  /// The explicit Admin authentication step. Always SELECTs and verifies the
  /// supplied PIN itself; only its success records this lease's authenticated
  /// session evidence that later Existing requests rely on.
  Future<bool> verifyPin(String pin) async {
    try {
      await _action(
        AdminAction.verifyPin,
        pin: pin,
        existingAllowed: false,
        mutation: false,
      );
      // preparedBinding revalidates the binding and lease identity before
      // stamping.
      preparedBinding.lease.recordAdminAuthentication();
      return true;
    } on ProtocolException catch (error) {
      if (error.details.kind == 'AuthenticationFailed' ||
          error.details.kind == 'PinBlocked') {
        return false;
      }
      rethrow;
    }
  }

  Future<void> changePin(String pin, {required String currentPin}) async {
    final bytes = Uint8List.fromList(utf8.encode(pin));
    try {
      await _action(AdminAction.changePin, pin: currentPin, data: bytes);
    } finally {
      bytes.fillRange(0, bytes.length, 0);
    }
  }

  Future<String> readFirmwareVersion() async => utf8.decode(
    preparedBinding.profile.firmware() ??
        (throw StateError('Missing firmware observation')),
  );
  Future<String> readModel() async =>
      preparedBinding.profile.model() ??
      (throw StateError('Device did not report its model'));
  Future<String> readSerial() async => hex
      .encode(
        preparedBinding.profile.serial() ??
            (throw StateError('Device did not report its serial')),
      )
      .toUpperCase();

  /// A real serial read over the wire, unlike [readSerial] which returns the
  /// probe (possibly bootstrap-fed) observation. Authentication re-confirms
  /// the physical device with this before submitting a PIN.
  Future<String> readSerialFromCard() async {
    final binding = preparedBinding;
    final data = await executeProtocolOperation(
      ProtocolOperation.bootstrapIdentity(step: BootstrapIdentityStep.serial),
      transport,
      lease: binding.lease,
      cancellation: cancellation,
    );
    binding.check();
    cancellation.check();
    return hex.encode(data).toUpperCase();
  }

  Future<String> readChipId() async =>
      hex.encode((await _read(AdminReadOperation.chipId)).data).toUpperCase();

  Future<Uint8List> readConfig({String? pin}) async =>
      (await _read(AdminReadOperation.configuration, pin: pin)).data;
  Future<bool> readNfcEnabled({String? pin}) async =>
      (await _read(AdminReadOperation.nfcStatus, pin: pin)).data.single == 1;
  Future<AdminStorageUsage> readStorageUsage({String? pin}) async =>
      (await _read(AdminReadOperation.flashUsage, pin: pin)).flashUsage!;

  Future<List<AdminAppletUsage>> readAppletStorageUsage() async =>
      (await _read(AdminReadOperation.appletUsage)).appletUsage!;

  Future<int> readKeyboardLayout({String? pin}) async =>
      (await _read(AdminReadOperation.keyboardLayout, pin: pin)).data.single;

  Future<Uint8List> readKeyboardKeymap({String? pin}) async =>
      (await _read(AdminReadOperation.keyboardKeymap, pin: pin)).data;

  Future<void> writeKeyboardKeymap(
    int layoutId,
    Uint8List keymap, {
    required String pin,
  }) async {
    if (keymap.length != 256) {
      throw ArgumentError.value(keymap.length, 'keymap');
    }
    await _action(
      AdminAction.keyboardKeymap,
      pin: pin,
      index: layoutId,
      data: keymap,
    );
  }

  Future<void> clearKeyboardKeymap({required String pin}) async {
    await _action(AdminAction.clearKeyboardKeymap, pin: pin);
  }

  Future<String?> readCoreCommit() async {
    try {
      final data = (await _read(AdminReadOperation.coreCommit)).data;
      return data.isEmpty ? null : utf8.decode(data);
    } on ProtocolException catch (error) {
      if (error.details.kind == 'UnsupportedFeature') return null;
      rethrow;
    }
  }

  Future<void> configure({
    required String pin,
    bool? ledOn,
    bool? ndefReadOnly,
    bool? ndefEnabled,
    bool? webusbLanding,
    int featureMask = 0,
    int featureValues = 0,
  }) async {
    RangeError.checkValueInInterval(featureMask, 0, 0x3f, 'featureMask');
    RangeError.checkValueInInterval(featureValues, 0, 0x3f, 'featureValues');
    await executeAdminRequest(
      (profile, pinBytes, existing) => profile.adminConfigure(
        pin: pinBytes,
        existing: existing,
        patch: AdminConfigurationPatch(
          ledOn: ledOn,
          ndefReadOnly: ndefReadOnly,
          ndefEnabled: ndefEnabled,
          webusbLanding: webusbLanding,
          featureMask: featureMask,
          featureValues: featureValues,
        ),
      ),
      pin: pin,
      mutation: true,
    );
  }

  Future<void> setKeyboardInterface(bool enabled, {required String pin}) =>
      _action(AdminAction.keyboardInterface, pin: pin, value: enabled ? 1 : 0);
  Future<void> setKeyboardReturn(bool enabled, {required String pin}) =>
      _action(AdminAction.keyboardReturn, pin: pin, value: enabled ? 1 : 0);
  Future<void> setLegacyTouch(int index, int value, {required String pin}) {
    RangeError.checkValueInInterval(index, 0, 3, 'index');
    RangeError.checkValueInInterval(value, 0, 0xff, 'value');
    return _action(
      AdminAction.legacyTouch,
      pin: pin,
      index: index,
      value: value,
    );
  }

  Future<void> setNfcEnabled(bool enabled, {required String pin}) =>
      _action(AdminAction.nfc, pin: pin, value: enabled ? 1 : 0);
  Future<void> setNdefReadOnly(bool readOnly, {required String pin}) =>
      configure(pin: pin, ndefReadOnly: readOnly);
  Future<void> resetNdef({required String pin}) =>
      resetApplet(Applet.ndef, pin: pin);
  Future<void> resetApplet(Applet applet, {required String pin}) =>
      _action(switch (applet) {
        Applet.openpgp => AdminAction.resetOpenPgp,
        Applet.piv => AdminAction.resetPiv,
        Applet.oath => AdminAction.resetOath,
        Applet.ndef => AdminAction.resetNdef,
        Applet.webauthn => AdminAction.resetCtap,
        Applet.pass => AdminAction.resetPass,
      }, pin: pin);
  Future<void> factoryReset() => _action(AdminAction.factoryReset);

  Future<WebAuthnSm2Config> readSm2Config({required String pin}) async {
    final result = await _read(AdminReadOperation.sm2Configuration, pin: pin);
    // Legacy CanoKey 3.0.x copies packed native little-endian i32 fields.
    // The variant comes from the profile, never from guessing response length.
    return WebAuthnSm2Config.decode(
      result.data,
      legacyEndian: result.kind == AdminValueKind.legacySm2Configuration
          ? Endian.little
          : Endian.big,
    );
  }

  Future<void> writeSm2Config({
    required String pin,
    required bool enabled,
    required int curveId,
    required int algoId,
  }) async {
    // Probe evidence chooses the format; this authenticated read validates it.
    final current = await readSm2Config(pin: pin);
    final data = current.encode(
      enabled: enabled,
      curveId: curveId,
      algoId: algoId,
    );
    await _action(AdminAction.writeSm2, pin: pin, data: data);
  }
}
