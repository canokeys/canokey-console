import 'dart:convert';
import 'dart:typed_data';

import 'package:canokey_console/helper/tlv.dart';
import 'package:canokey_console/helper/utils/card_client.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:canokey_console/src/rust/api/protocol.dart';
import 'package:convert/convert.dart';

/// libcanokey owns every OpenPGP operation: card-info reads, PW1/PW3
/// credentials and all administrative writes. Each upstream operation SELECTs
/// OpenPGP and explicitly verifies its own password; the prepared profile is
/// immutable firmware evidence, never an authorization token. OpenPGP
/// operations self-SELECT, so applet switches do not invalidate the profile;
/// only profile evidence and lease generations matter.
class OpenPgpCardClient extends ProfileCardClient {
  OpenPgpCardClient({super.transport, super.lease})
    : super(bindSelection: false);

  /// Explicit minimal discovery before any OpenPGP operation. The profile only
  /// carries firmware observations; upstream operations SELECT OpenPGP themselves.
  Future<void> prepare() => prepareProfile(
    () => ProtocolOperation.probeAdmin(observedSerial: lease.bootstrapSerial),
  );

  /// Every upstream OpenPGP operation SELECTs its applet first.
  Future<Uint8List> _execute(
    ProtocolOperation Function(ProtocolProfile) create,
  ) => executePrepared(create, selectApplet: true);

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
    final touchCacheTime = await _readTouchCacheTime();

    final slots = <OpenPgpKeyType, OpenPgpKeySlotInfo>{};
    for (final type in OpenPgpKeyType.values) {
      final index = type.index;
      final touch = _parseUifValue(_bytes(discretionary[type.uifTag]));
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
  Future<bool> _changePassword(int reference, String oldPin, String newPin) =>
      _runWithPasswords(
        [oldPin, newPin],
        (profile, passwords) => profile.openpgpChangePassword(
          reference: reference,
          old: passwords[0],
          new_: passwords[1],
        ),
      );

  Future<bool> verifyAdminPin(String adminPin) => _runAdminWrite(
    adminPin,
    (profile, password) =>
        profile.openpgpVerify(reference: 2, password: password),
  );

  /// Set (or clear with an empty string) the reset code via upstream
  /// `DataWrite::ResetCode` after its own explicit PW3 verification.
  Future<bool> setResetCode(String adminPin, String resetCode) =>
      _runWithPasswords(
        [adminPin, resetCode],
        (profile, passwords) => profile.openpgpWriteResetCode(
          resetCode: resetCode.isEmpty ? null : passwords[1],
          password: passwords[0],
        ),
        securityRejectionIsFalse: true,
      );

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
  Future<bool> unblockUserPinWithAdmin(String adminPin, String newPin) =>
      _runWithPasswords(
        [adminPin, newPin],
        (profile, passwords) => profile.openpgpUnblockWithAdmin(
          newPin: passwords[1],
          password: passwords[0],
        ),
        securityRejectionIsFalse: true,
      );

  /// Upstream `Request::UnblockWithCode`; no password verification is inserted.
  Future<bool> unblockUserPinWithResetCode(String resetCode, String newPin) =>
      _runWithPasswords(
        [resetCode, newPin],
        (profile, passwords) => profile.openpgpUnblockWithCode(
          code: passwords[0],
          newPin: passwords[1],
        ),
      );

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
    ProtocolOperation Function(ProtocolProfile, Uint8List) create,
  ) => _runWithPasswords(
    [adminPin],
    (profile, passwords) => create(profile, passwords.single),
    securityRejectionIsFalse: true,
  );

  Future<bool> _runWithPasswords(
    List<String> values,
    ProtocolOperation Function(ProtocolProfile, List<Uint8List>) create, {
    bool securityRejectionIsFalse = false,
  }) async {
    final passwords = values
        .map((value) => Uint8List.fromList(utf8.encode(value)))
        .toList();
    try {
      await _execute((profile) => create(profile, passwords));
      return true;
    } on ProtocolException catch (error) {
      if (error.details.kind == 'AuthenticationFailed' ||
          error.details.kind == 'PinBlocked' ||
          (securityRejectionIsFalse &&
              error.details.kind == 'SecurityStatusNotSatisfied')) {
        return false;
      }
      rethrow;
    } finally {
      for (final password in passwords) {
        password.fillRange(0, password.length, 0);
      }
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
