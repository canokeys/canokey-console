import 'dart:convert';
import 'dart:typed_data';

import 'package:canokey_console/helper/tlv.dart';
import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/card_session.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:canokey_console/src/rust/api/protocol.dart';
import 'package:convert/convert.dart';

/// libcanokey owns every OpenPGP operation: card-info reads, PW1/PW3
/// credentials and all administrative writes. Each upstream operation SELECTs
/// OpenPGP and explicitly verifies its own password; the prepared profile is
/// immutable firmware evidence, never an authorization token.
class OpenPgpCardClient {
  OpenPgpCardClient({
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
  _OpenPgpProfileBinding? _profile;
  String? lastStatusWord;

  CardLease get _lease => _transport is SmartCardApduTransport
      ? SmartCard.currentLease
      : _injectedLease ??
            _injectedSessions.current?.lease ??
            (throw StateError('Injected OpenPGP transport requires withSession'));

  /// For caller-owned transports (tests/USB-IP). Production uses SmartCard.process.
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

  /// Explicit minimal discovery before any OpenPGP operation. The profile only
  /// carries firmware observations; upstream operations SELECT OpenPGP themselves.
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
    final binding = _OpenPgpProfileBinding(profile, lease);
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

  _OpenPgpProfileBinding get _prepared {
    final lease = _lease;
    final binding = _profile;
    if (binding == null || !identical(binding.lease, lease)) {
      throw StateError('Prepare OpenPGP in the current lease first');
    }
    binding.check();
    _cancellation.check();
    if (lease.isExchanging) {
      throw StateError('A card operation is already active');
    }
    return binding;
  }

  Future<Uint8List> _execute(
    ProtocolOperation Function(ProtocolProfile) create,
  ) async {
    final binding = _prepared;
    lastStatusWord = null;
    // Every upstream OpenPGP operation SELECTs its applet first.
    binding.lease.willSelectApplet();
    try {
      final data = await executeProtocolOperation(
        create(binding.profile),
        _transport,
        lease: binding.lease,
        cancellation: _cancellation,
      );
      binding.check();
      _cancellation.check();
      lastStatusWord = '9000';
      return data;
    } on ProtocolException catch (error) {
      binding.check();
      _cancellation.check();
      lastStatusWord = error.details.statusWord
          ?.toRadixString(16)
          .padLeft(4, '0')
          .toUpperCase();
      rethrow;
    }
  }

  Future<OpenPgpCardInfo> readCardInfo() async {
    final applicationData = await _readDataObject(0x6E);
    final application = _parseApplicationRelatedData(applicationData);
    final discretionary = _parseDiscretionaryData(application);
    final aid = _bytes(application[0x4F]);
    final version = _versionFromAid(aid);
    final manufacturer = _manufacturerFromAid(aid);
    final serial = _serialFromAid(aid);
    final holder = _decodeCardholder(await _tryReadDataObject(0x65));
    final url = _decodeText(await _tryReadDataObject(0x5F50));
    final pinState = _parsePinState(_bytes(discretionary[0xC4]));
    final fingerprints = _splitFixed(_bytes(discretionary[0xC5]), 20);
    final generationTimes = _splitFixed(_bytes(discretionary[0xCD]), 4);
    final uif = _parseUif(discretionary);
    final touchCacheTime = await _readTouchCacheTime();

    final slots = <OpenPgpKeyType, OpenPgpKeySlotInfo>{};
    for (final type in OpenPgpKeyType.values) {
      final index = type.index;
      final touch = uif[type] ?? (OpenPgpTouchPolicy.off, false);
      slots[type] = OpenPgpKeySlotInfo(
        type: type,
        fingerprint: _fingerprintAt(fingerprints, index),
        generatedAt: _generationTimeAt(generationTimes, index),
        touchPolicy: touch.$1,
        touchFixed: touch.$2,
      );
    }

    return OpenPgpCardInfo(
      version: version,
      manufacturer: manufacturer,
      serialNumber: serial,
      cardHolder: holder,
      publicKeyUrl: url,
      pinState: pinState,
      keySlots: slots,
      touchCacheTime: touchCacheTime,
    );
  }

  Future<bool> changeUserPin(String oldPin, String newPin) =>
      _changePassword(0, oldPin, newPin);

  Future<bool> changeAdminPin(String oldPin, String newPin) =>
      _changePassword(2, oldPin, newPin);

  /// PW1-sign (0) or PW3 (2); upstream sends old||new without a prior VERIFY.
  Future<bool> _changePassword(
    int reference,
    String oldPin,
    String newPin,
  ) async {
    final oldBytes = Uint8List.fromList(utf8.encode(oldPin));
    final newBytes = Uint8List.fromList(utf8.encode(newPin));
    try {
      await _execute(
        (profile) => profile.openpgpChangePassword(
          reference: reference,
          old: oldBytes,
          new_: newBytes,
        ),
      );
      return true;
    } on ProtocolException catch (error) {
      if (error.details.kind == 'AuthenticationFailed' ||
          error.details.kind == 'PinBlocked') {
        return false;
      }
      rethrow;
    } finally {
      oldBytes.fillRange(0, oldBytes.length, 0);
      newBytes.fillRange(0, newBytes.length, 0);
    }
  }

  Future<bool> verifyAdminPin(String adminPin) async {
    final bytes = Uint8List.fromList(utf8.encode(adminPin));
    try {
      await _execute(
        (profile) => profile.openpgpVerify(reference: 2, password: bytes),
      );
      return true;
    } on ProtocolException catch (error) {
      if (error.details.kind == 'AuthenticationFailed' ||
          error.details.kind == 'PinBlocked' ||
          error.details.kind == 'SecurityStatusNotSatisfied') {
        return false;
      }
      rethrow;
    } finally {
      bytes.fillRange(0, bytes.length, 0);
    }
  }

  /// Set (or clear with an empty string) the reset code via upstream
  /// `DataWrite::ResetCode` after its own explicit PW3 verification.
  Future<bool> setResetCode(String adminPin, String resetCode) async {
    final code = resetCode.isEmpty
        ? null
        : Uint8List.fromList(utf8.encode(resetCode));
    try {
      return await _runAdminWrite(
        adminPin,
        (profile, password) => profile.openpgpWriteResetCode(
          resetCode: code,
          password: password,
        ),
      );
    } finally {
      if (code != null) code.fillRange(0, code.length, 0);
    }
  }

  /// Upstream `Request::ResetRetries`, gated on the retry-reset capability.
  /// On success the card resets PW1/PW3 to firmware defaults and clears
  /// authorization; Console caches no OpenPGP credentials, so nothing local
  /// needs invalidation. Never retried after an uncertain outcome.
  Future<bool> setPinRetries(
    String adminPin,
    int userRetries,
    int resetRetries,
    int adminRetries,
  ) => _runAdminWrite(
    adminPin,
    (profile, password) => profile.openpgpResetRetries(
      retries: [userRetries, resetRetries, adminRetries],
      password: password,
    ),
  );

  /// Upstream `DataWrite::ReuseSignaturePin`; Console's flag is inverted.
  Future<bool> setSignaturePinPolicy(
    String adminPin,
    bool verifyForEverySignature,
  ) => _runAdminWrite(
    adminPin,
    (profile, password) => profile.openpgpWriteSignaturePinPolicy(
      reuse: !verifyForEverySignature,
      password: password,
    ),
  );

  /// Upstream `Request::UnblockWithAdmin` after explicit PW3 verification.
  Future<bool> unblockUserPinWithAdmin(String adminPin, String newPin) async {
    final newPinBytes = Uint8List.fromList(utf8.encode(newPin));
    try {
      return await _runAdminWrite(
        adminPin,
        (profile, password) => profile.openpgpUnblockWithAdmin(
          newPin: newPinBytes,
          password: password,
        ),
      );
    } finally {
      newPinBytes.fillRange(0, newPinBytes.length, 0);
    }
  }

  /// Upstream `Request::UnblockWithCode`; no password verification is inserted.
  Future<bool> unblockUserPinWithResetCode(String resetCode, String newPin) async {
    final code = Uint8List.fromList(utf8.encode(resetCode));
    final newPinBytes = Uint8List.fromList(utf8.encode(newPin));
    try {
      await _execute(
        (profile) =>
            profile.openpgpUnblockWithCode(code: code, newPin: newPinBytes),
      );
      return true;
    } on ProtocolException catch (error) {
      if (error.details.kind == 'AuthenticationFailed' ||
          error.details.kind == 'PinBlocked') {
        return false;
      }
      rethrow;
    } finally {
      code.fillRange(0, code.length, 0);
      newPinBytes.fillRange(0, newPinBytes.length, 0);
    }
  }

  /// Upstream `DataWrite::TouchPolicy`, emitting the standard two-byte UIF
  /// field; the UIF capability gates construction on legacy firmware.
  Future<bool> setTouchPolicy(
    OpenPgpKeyType keyType,
    OpenPgpTouchPolicy policy,
    String adminPin,
  ) => _runAdminWrite(
    adminPin,
    (profile, password) => profile.openpgpWriteTouchPolicy(
      slot: keyType.index,
      policy: policy.value,
      password: password,
    ),
  );

  /// Upstream `DataWrite::TouchCacheTime`; the UIF capability gates it.
  Future<bool> setTouchCacheTime(String adminPin, int seconds) {
    RangeError.checkValueInInterval(seconds, 0, 0xff, 'seconds');
    return _runAdminWrite(
      adminPin,
      (profile, password) => profile.openpgpWriteTouchCacheTime(
        seconds: seconds,
        password: password,
      ),
    );
  }

  /// PW3-protected write. Credential rejection, blocked PW3 and target-stage
  /// security rejections keep the UI's false result and status word; other
  /// protocol and transport failures propagate.
  Future<bool> _runAdminWrite(
    String adminPin,
    ProtocolOperation Function(ProtocolProfile profile, Uint8List password)
    create,
  ) async {
    final password = Uint8List.fromList(utf8.encode(adminPin));
    try {
      await _execute((profile) => create(profile, password));
      return true;
    } on ProtocolException catch (error) {
      if (error.details.kind == 'AuthenticationFailed' ||
          error.details.kind == 'PinBlocked' ||
          error.details.kind == 'SecurityStatusNotSatisfied') {
        return false;
      }
      rethrow;
    } finally {
      password.fillRange(0, password.length, 0);
    }
  }

  Future<List<int>> _readDataObject(int tag) async {
    return _execute((profile) => profile.openpgpReadData(tag: tag));
  }

  /// Optional objects: only a missing object (or an unsupported feature gate
  /// before any exchange) becomes null; security/malformed failures propagate.
  Future<List<int>?> _tryReadDataObject(int tag) async {
    try {
      return await _readDataObject(tag);
    } on ProtocolException catch (error) {
      if (error.details.kind == 'NotFound') return null;
      rethrow;
    }
  }

  Map<OpenPgpKeyType, (OpenPgpTouchPolicy, bool)> _parseUif(Map discretionary) {
    final result = <OpenPgpKeyType, (OpenPgpTouchPolicy, bool)>{};
    for (final type in OpenPgpKeyType.values) {
      final data = _bytes(discretionary[type.uifTag]);
      result[type] = _parseUifValue(data);
    }
    return result;
  }

  (OpenPgpTouchPolicy, bool) _parseUifValue(List<int> data) {
    if (data.isEmpty) {
      return (OpenPgpTouchPolicy.off, false);
    }
    final policy = OpenPgpTouchPolicy.fromValue(data[0]);
    final fixed =
        policy == OpenPgpTouchPolicy.permanent ||
        policy == OpenPgpTouchPolicy.cachedPermanent;
    return (policy, fixed);
  }

  Future<int?> _readTouchCacheTime() async {
    List<int> data;
    try {
      data = await _readDataObject(0x0102);
    } on ProtocolException catch (error) {
      // Firmware before the UIF gate and cards without the object both keep
      // the previous absent-cache-time behavior.
      if (error.details.kind == 'NotFound' ||
          error.details.kind == 'UnsupportedFeature') {
        return null;
      }
      rethrow;
    }
    if (data.isEmpty) {
      return null;
    }
    return data[0];
  }

  Map _parseApplicationRelatedData(List<int> data) {
    final parsed = TLV.parse(data);
    final wrapped = _bytes(parsed[0x6E]);
    if (wrapped.isEmpty) {
      return parsed;
    }
    return TLV.parse(wrapped);
  }

  Map _parseDiscretionaryData(Map application) {
    final parsed = application[0x73];
    if (parsed is Map) {
      return parsed;
    }
    final raw = _bytes(parsed);
    if (raw.isNotEmpty) {
      return TLV.parse(raw);
    }
    return application;
  }

  OpenPgpPinState _parsePinState(List<int> data) {
    return OpenPgpPinState(
      signaturePinForced: data.isNotEmpty && data[0] == 0,
      userRetries: data.length > 4 ? data[4] : null,
      resetRetries: data.length > 5 ? data[5] : null,
      adminRetries: data.length > 6 ? data[6] : null,
    );
  }

  String _versionFromAid(List<int> aid) {
    if (aid.length < 8) {
      return '';
    }
    return '${_bcd(aid[6])}.${_bcd(aid[7])}';
  }

  String _manufacturerFromAid(List<int> aid) {
    if (aid.length < 10) {
      return '';
    }
    final id = (aid[8] << 8) + aid[9];
    if (id == 0x0006) {
      return 'Yubico';
    }
    if (id == 0x0000) {
      return '';
    }
    return '0x${id.toRadixString(16).padLeft(4, '0').toUpperCase()}';
  }

  String _serialFromAid(List<int> aid) {
    if (aid.length < 14) {
      return '';
    }
    return hex.encode(aid.sublist(10, 14)).toUpperCase();
  }

  int _bcd(int value) {
    return 10 * (value >> 4) + (value & 0x0F);
  }

  String _decodeCardholder(List<int>? data) {
    if (data == null || data.isEmpty) {
      return '';
    }
    try {
      final parsed = TLV.parse(data);
      return _decodeText(_bytes(parsed[0x5B]));
    } catch (_) {
      return _decodeText(data);
    }
  }

  String _decodeText(List<int>? data) {
    if (data == null || data.isEmpty) {
      return '';
    }
    try {
      return utf8.decode(data);
    } catch (_) {
      return latin1.decode(data);
    }
  }

  List<int> _bytes(dynamic value) {
    if (value is List<int>) {
      return value;
    }
    return [];
  }

  List<List<int>> _splitFixed(List<int> data, int width) {
    if (data.isEmpty || width <= 0) {
      return [];
    }
    final result = <List<int>>[];
    for (var offset = 0; offset + width <= data.length; offset += width) {
      result.add(data.sublist(offset, offset + width));
    }
    return result;
  }

  String? _fingerprintAt(List<List<int>> fingerprints, int index) {
    if (index >= fingerprints.length) {
      return null;
    }
    final fingerprint = fingerprints[index];
    if (fingerprint.every((byte) => byte == 0)) {
      return null;
    }
    return hex.encode(fingerprint).toUpperCase();
  }

  DateTime? _generationTimeAt(List<List<int>> generationTimes, int index) {
    if (index >= generationTimes.length) {
      return null;
    }
    final bytes = generationTimes[index];
    if (bytes.length != 4 || bytes.every((byte) => byte == 0)) {
      return null;
    }
    final seconds =
        (bytes[0] << 24) + (bytes[1] << 16) + (bytes[2] << 8) + bytes[3];
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }
}

/// Firmware-evidence binding; OpenPGP operations self-SELECT, so applet
/// switches do not invalidate it. Only profile evidence and lease matter.
class _OpenPgpProfileBinding {
  _OpenPgpProfileBinding(this.profile, this.lease)
    : generation = lease.profileGeneration;
  final ProtocolProfile profile;
  final CardLease lease;
  final int generation;
  bool _closed = false;
  void check() {
    lease.check();
    if (_closed || generation != lease.profileGeneration) {
      throw StateError('OpenPGP profile requires explicit discovery');
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
