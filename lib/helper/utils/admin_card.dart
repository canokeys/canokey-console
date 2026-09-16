import 'dart:convert';
import 'dart:typed_data';

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/card_session.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/models/webauthn.dart';
import 'package:canokey_console/src/rust/api/protocol.dart';
import 'package:convert/convert.dart';

class AdminStorageUsage {
  const AdminStorageUsage({required this.usedKiB, required this.totalKiB});
  final int usedKiB;
  final int totalKiB;
}

/// Each upstream Admin operation either SELECTs and explicitly authenticates
/// its own request, or reuses this lease's authenticated Admin session via
/// `Access::Existing`. That session evidence is recorded only by a successful
/// explicit [verifyPin] on the same lease and is bound to the lease's
/// selection/profile generations; a UI PIN cache is never authorization.
class AdminCardClient {
  AdminCardClient({
    ApduTransport transport = const SmartCardApduTransport(),
    CardLease? lease,
  }) : _transport = transport,
       _injectedLease = lease {
    if (lease != null && transport is SmartCardApduTransport) {
      throw ArgumentError('Production transport uses SmartCard.currentLease');
    }
  }

  final ApduTransport _transport;
  final CardLease? _injectedLease;
  final CardSessions _injectedSessions = CardSessions();
  final CardCancellation _cancellation = CardCancellation();
  _AdminProfileBinding? _profile;
  String? lastResponse;
  AdminProgress? lastProgress;

  CardLease get _lease => _transport is SmartCardApduTransport
      ? SmartCard.currentLease
      : _injectedLease ??
            _injectedSessions.current?.lease ??
            (throw StateError('Injected Admin transport requires withSession'));

  Future<T> withSession<T>(Future<T> Function() action) {
    if (_transport is SmartCardApduTransport) {
      throw StateError('Use SmartCard.process for the production transport');
    }
    if (_injectedLease != null) {
      throw StateError('Use the supplied lease owner');
    }
    return _injectedSessions.run((session) async {
      session.bind(_transport.transceive);
      return action();
    });
  }

  void cancelPendingOperations() => _cancellation.cancel();

  /// Explicit minimal discovery, before any authentication. Repeat after a
  /// profile-affecting write, including an uncertain write; never auto-reprobe.
  Future<void> prepare() async {
    _cancellation.check();
    final lease = _lease;
    lease.willSelectApplet();
    _profile?.close();
    _profile = null;
    final profile = await executeProfileProbe(
      ProtocolOperation.probeAdmin(),
      _transport,
      lease: lease,
      cancellation: _cancellation,
    );
    final binding = _AdminProfileBinding(profile, lease);
    try {
      lease.check();
      _cancellation.check();
      lease.onClose(() {
        binding.close();
        if (identical(_profile, binding)) _profile = null;
      });
      _profile = binding;
    } catch (_) {
      binding.close();
      rethrow;
    }
  }

  /// Explicit discovery only when the prepared binding is missing or stale.
  /// A still-valid binding is reused as-is, preserving the lease's recorded
  /// Admin session evidence; discovery is never repeated implicitly.
  Future<void> prepareIfStale() async {
    final binding = _profile;
    if (binding != null && identical(binding.lease, _lease)) {
      try {
        binding.check();
        _cancellation.check();
        return;
      } on StateError {
        // Fall through to explicit discovery below.
      }
    }
    await prepare();
  }

  _AdminProfileBinding get _prepared {
    final lease = _lease;
    final binding = _profile;
    if (binding == null || !identical(binding.lease, lease)) {
      throw StateError('Prepare Admin in the current lease first');
    }
    binding.check();
    _cancellation.check();
    if (lease.isExchanging) {
      throw StateError('A card operation is already active');
    }
    return binding;
  }

  /// Runs one Admin request. When this lease holds a still-valid recorded
  /// Admin authentication (see CardLease.recordAdminAuthentication) and the
  /// caller allows it, the request uses `Access::Existing`: no SELECT and no
  /// VERIFY are sent, and any supplied PIN stays unused. Otherwise the
  /// request SELECTs and verifies only the explicitly supplied PIN.
  Future<AdminResult> _execute(
    ProtocolOperation Function(ProtocolProfile profile, Uint8List? pin, bool existing)
    create, {
    String? pin,
    bool existingAllowed = true,
    bool mutation = false,
  }) async {
    final binding = _prepared;
    lastResponse = null;
    lastProgress = null;
    final existing = existingAllowed && binding.lease.hasAdminAuthentication;
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
        _transport,
        lease: binding.lease,
        cancellation: _cancellation,
        onProgress: (progress) => lastProgress = progress,
      );
      binding.check();
      _cancellation.check();
      lastResponse = '9000';
      return result;
    } on ProtocolException catch (error) {
      lastResponse = error.details.statusWord
          ?.toRadixString(16)
          .padLeft(4, '0')
          .toUpperCase();
      // A failed Existing request leaves the card-side session state
      // uncertain; later requests must re-establish evidence or use a PIN.
      if (existing) binding.lease.invalidateAdminAuthentication();
      rethrow;
    } catch (_) {
      binding.close();
      if (identical(_profile, binding)) _profile = null;
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
        binding.close();
        if (identical(_profile, binding)) _profile = null;
      }
    }
  }

  Future<AdminResult> _read(AdminReadOperation kind, {String? pin}) => _execute(
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
      await _execute(
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
      // _prepared revalidates the binding and lease identity before stamping.
      _prepared.lease.recordAdminAuthentication();
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
    _prepared.profile.firmware() ??
        (throw StateError('Missing firmware observation')),
  );
  Future<String> readModel() async =>
      _prepared.profile.model() ??
      (throw StateError('Device did not report its model'));
  Future<String> readSerial() async => hex
      .encode(
        _prepared.profile.serial() ??
            (throw StateError('Device did not report its serial')),
      )
      .toUpperCase();
  Future<String> readChipId() async =>
      hex.encode((await _read(AdminReadOperation.chipId)).data).toUpperCase();

  Future<Uint8List> readConfig({String? pin}) async =>
      (await _read(AdminReadOperation.configuration, pin: pin)).data;
  Future<bool> readNfcEnabled({String? pin}) async =>
      (await _read(AdminReadOperation.nfcStatus, pin: pin)).data.single == 1;
  Future<AdminStorageUsage> readStorageUsage({String? pin}) async {
    final data = (await _read(AdminReadOperation.flashUsage, pin: pin)).data;
    return AdminStorageUsage(usedKiB: data[0], totalKiB: data[1]);
  }

  Future<Uint8List> readAppletStorageUsage() async =>
      (await _read(AdminReadOperation.appletUsage)).data;

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
    await _execute(
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
  Future<void> setLegacyPivExtensions(bool enabled, {required String pin}) =>
      _action(
        AdminAction.legacyPivExtensions,
        pin: pin,
        value: enabled ? 1 : 0,
      );
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

class _AdminProfileBinding {
  _AdminProfileBinding(this.profile, this.lease)
    : generation = lease.profileGeneration;
  final ProtocolProfile profile;
  final CardLease lease;
  final int generation;
  bool _closed = false;
  void check() {
    lease.check();
    if (_closed || generation != lease.profileGeneration) {
      throw StateError('Admin profile requires explicit discovery');
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    try {
      profile.close();
    } finally {
      profile.dispose();
    }
  }
}
