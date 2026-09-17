import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:canokey_console/helper/utils/card_client.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:canokey_console/src/rust/api/crypto.dart';
import 'package:canokey_console/src/rust/api/protocol.dart';
import 'package:convert/convert.dart';

/// OATH applet observations from an explicit libcanokey SELECT.
/// A selection is evidence, never a reusable authenticated session.
class OathSelection {
  const OathSelection({
    required this.version,
    this.salt,
    required this.requiresCode,
  });

  final OathVersion version;

  /// Eight-byte key-derivation handle; absent on legacy firmware.
  final Uint8List? salt;

  /// Whether an access code is installed and validation is required.
  final bool requiresCode;
}

/// One CalculateAll entry: either a truncated code or an explicit marker.
class OathCalculatedEntry {
  const OathCalculatedEntry._({
    this.name,
    required this.digits,
    this.rawCode,
    this.isHotp = false,
    this.requiresTouch = false,
  });

  /// Absent only for an individual Calculate result.
  final String? name;
  final int digits;

  /// Big-endian dynamic-truncation value; null for marker entries.
  final int? rawCode;
  final bool isHotp;
  final bool requiresTouch;
}

/// libcanokey-backed OATH operations. The profile is explicitly prepared while
/// the caller owns the card lease; libcanokey then owns SELECT, framing,
/// pagination, continuation and response validation. Every operation selects
/// and, when an access key is supplied, validates within itself — no
/// authentication state is carried between operations.
class OathCardClient extends ProfileCardClient {
  OathCardClient({super.transport, super.lease}) : super(bindSelection: false);

  /// Fresh host challenge for each access proof.
  static Uint8List _randomChallenge() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(8, (_) => random.nextInt(256)));
  }

  /// OATH password convention: PBKDF2-HMAC-SHA1, 1000 iterations, the SELECT
  /// handle as salt, sixteen output bytes.
  static Uint8List deriveKey(String code, List<int> salt) =>
      pbkdf2HmacSha1(password: code, salt: salt, iterations: 1000, keyLen: 16);

  /// Explicit minimal discovery, before any authentication. Repeat after a
  /// profile-affecting write, including an uncertain write; never auto-reprobe.
  Future<void> prepare() => prepareProfile(
    () => ProtocolOperation.probeAdmin(observedSerial: lease.bootstrapSerial),
  );

  /// All OATH operations SELECT the applet before their target command. A
  /// non-protocol failure discards the profile evidence.
  Future<Uint8List> _execute(
    ProtocolOperation Function(ProtocolProfile) create,
  ) => _executeResult(create, (step) => step.data!);

  (Uint8List?, Uint8List?) _accessParts(Uint8List? key) =>
      key == null ? (null, null) : (key, _randomChallenge());

  Future<T> _executeResult<T>(
    ProtocolOperation Function(ProtocolProfile) create,
    T Function(ProtocolStep) result,
  ) => executePreparedResult(
    create,
    result: result,
    selectApplet: true,
    recheckOnProtocolError: false,
    discardOnOtherError: true,
  );

  Future<OathSelection> select() =>
      _executeResult((profile) => profile.oathSelect(), (step) {
        final selection = step.oathSelection!;
        return OathSelection(
          version: selection.version == null
              ? OathVersion.legacy
              : hex.encode(selection.version!) == '060000'
              ? OathVersion.v2
              : OathVersion.v1,
          salt: selection.salt,
          requiresCode: selection.challenge != null,
        );
      });

  /// Explicitly prove an access key. Wrong keys surface as AuthenticationFailed.
  Future<void> validate(Uint8List key) => _execute(
    (profile) =>
        profile.oathValidate(key: key, challenge: _randomChallenge()),
  );

  Future<void> put({
    required String name,
    required String secretHex,
    required OathType type,
    required OathAlgorithm algorithm,
    required int digits,
    bool requireTouch = false,
    int initialValue = 0,
    Uint8List? key,
  }) {
    if (initialValue < 0 || initialValue > 0xffffffff) {
      throw RangeError.range(initialValue, 0, 0xffffffff, 'initialValue');
    }
    final secret = Uint8List.fromList(hex.decode(secretHex));
    final (accessKey, accessChallenge) = _accessParts(key);
    return _execute(
      (profile) => profile.oathPut(
        name: utf8.encode(name),
        kind: type == OathType.hotp ? 1 : 2,
        algorithm: algorithm.value,
        digits: digits,
        secret: secret,
        requireTouch: requireTouch,
        increasing: false,
        initialCounter: initialValue,
        accessKey: accessKey,
        accessChallenge: accessChallenge,
      ),
    ).whenComplete(() => secret.fillRange(0, secret.length, 0));
  }

  Future<void> delete(String name, {Uint8List? key}) {
    final (accessKey, accessChallenge) = _accessParts(key);
    return _execute(
      (profile) => profile.oathDelete(
        name: utf8.encode(name),
        accessKey: accessKey,
        accessChallenge: accessChallenge,
      ),
    );
  }

  /// Calculate one credential. The truncated code is returned unformatted;
  /// display formatting (decimal, Steam) stays with the caller.
  Future<(int digits, int rawCode)> calculate({
    required String name,
    required OathType type,
    String? challengeHex,
    Uint8List? key,
  }) {
    Uint8List? challenge;
    if (type == OathType.totp) {
      if (challengeHex == null || challengeHex.length != 16) {
        throw ArgumentError.value(
          challengeHex,
          'challengeHex',
          'TOTP challenges must contain eight bytes',
        );
      }
      challenge = Uint8List.fromList(hex.decode(challengeHex));
    }
    final (accessKey, accessChallenge) = _accessParts(key);
    return _executeResult(
      (profile) => profile.oathCalculate(
        name: utf8.encode(name),
        kind: type == OathType.hotp ? 1 : 2,
        // Only full-format validation reads the expected algorithm.
        algorithm: OathAlgorithm.sha1.value,
        challenge: challenge,
        format: 0,
        accessKey: accessKey,
        accessChallenge: accessChallenge,
      ),
      (step) {
        final entry = _calculation(step.oathCalculations!.single);
        if (entry.name != null || entry.rawCode == null) {
          throw const FormatException('Unexpected OATH calculation result');
        }
        return (entry.digits, entry.rawCode!);
      },
    );
  }

  Future<List<OathCalculatedEntry>> calculateAll(
    String challengeHex, {
    Uint8List? key,
  }) {
    if (challengeHex.length != 16) {
      throw ArgumentError.value(
        challengeHex,
        'challengeHex',
        'OATH challenges must contain eight bytes',
      );
    }
    final (accessKey, accessChallenge) = _accessParts(key);
    return _executeResult(
      (profile) => profile.oathCalculateAll(
        challenge: Uint8List.fromList(hex.decode(challengeHex)),
        format: 0,
        accessKey: accessKey,
        accessChallenge: accessChallenge,
      ),
      (step) => step.oathCalculations!
          .map(_calculation)
          .map(
            (entry) => entry.name != null
                ? entry
                : throw const FormatException('Nameless OATH list entry'),
          )
          .toList(),
    );
  }

  /// Set or replace the access code. The current key validates in the same
  /// operation; pass no old key only when the applet is unprotected.
  Future<void> setCode({required Uint8List newKey, Uint8List? oldKey}) =>
      _execute(
        (profile) => profile.oathSetCode(
          oldKey: oldKey,
          newKey: newKey,
          challenge: _randomChallenge(),
        ),
      );

  Future<void> clearCode({Uint8List? key}) {
    final (accessKey, accessChallenge) = _accessParts(key);
    return _execute(
      (profile) =>
          profile.oathClearCode(key: accessKey, challenge: accessChallenge),
    );
  }

  /// Mark an existing HOTP credential as the touch keyboard-emulation
  /// default: slot 0 = short, 1 = long. The legacy single-slot dialect comes
  /// from the probed profile; a long slot or append-enter there fails
  /// construction with InvalidArgument before any I/O.
  Future<void> setDefault({
    required String name,
    required int slot,
    required bool appendEnter,
    Uint8List? key,
  }) {
    if (slot != 0 && slot != 1) {
      throw RangeError.range(slot, 0, 1, 'slot');
    }
    final (accessKey, accessChallenge) = _accessParts(key);
    return _execute(
      (profile) => profile.oathSetDefault(
        slot: slot,
        appendEnter: appendEnter,
        name: name,
        accessKey: accessKey,
        accessChallenge: accessChallenge,
      ),
    );
  }

  static OathCalculatedEntry _calculation(OathCalculation entry) {
    final name = entry.name == null ? null : utf8.decode(entry.name!);
    return switch (entry.code) {
      OathCode.truncated => OathCalculatedEntry._(
        name: name,
        digits: entry.digits,
        rawCode: entry.rawCode,
      ),
      OathCode.hotp => OathCalculatedEntry._(
        name: name,
        digits: entry.digits,
        isHotp: true,
      ),
      OathCode.touchRequired => OathCalculatedEntry._(
        name: name,
        digits: entry.digits,
        requiresTouch: true,
      ),
      _ => throw const FormatException('Unexpected full OATH calculation code'),
    };
  }
}
