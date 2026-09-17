import 'dart:math';
import 'dart:typed_data';

import 'package:canokey_console/helper/utils/card_client.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/src/rust/api/protocol.dart';
import 'package:canokey_console/src/rust/api/piv_crypto.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:convert/convert.dart';

class PivCardClient extends ProfileCardClient {
  PivCardClient({
    super.transport,
    super.lease,
    PivCertificateExecutor? certificateExecutor,
    Future<void> Function()? prepareExecutor,
  }) : _certificateExecutor = certificateExecutor,
       _prepareExecutor = prepareExecutor,
       super(bindSelection: true);

  final PivCertificateExecutor? _certificateExecutor;
  final Future<void> Function()? _prepareExecutor;

  /// Explicit discovery/selection before authentication. The lease owns the
  /// immutable observations; later metadata reads never probe or SELECT.
  Future<void> prepare() async {
    cancellation.check();
    final override = _prepareExecutor;
    if (override != null) return override();
    await prepareProfile(
      () => ProtocolOperation.probePiv(observedSerial: lease.bootstrapSerial),
      rejectWhileExchanging: true,
    );
  }

  /// Read the validated metadata directory without inserting SELECT.
  Future<Uint8List> readMetadataDirectory() async {
    return _executePrepared((profile) => profile.pivMetadataDirectory());
  }

  Future<Uint8List> generateKey({
    required int slot,
    required int algorithm,
    required int pinPolicy,
    required int touchPolicy,
  }) async {
    return _executePrepared(
      (profile) => profile.pivGenerateKey(
        slot: slot,
        algorithm: algorithm,
        pinPolicy: pinPolicy,
        touchPolicy: touchPolicy,
      ),
    );
  }

  Future<void> deleteKey(int slot) async {
    await _executePrepared((profile) => profile.pivDeleteKey(slot: slot));
  }

  Future<void> moveKey(int source, int target) async {
    await _executePrepared(
      (profile) => profile.pivMoveKey(source: source, target: target),
    );
  }

  Future<void> setManagementKey({
    required int algorithm,
    required Uint8List key,
    int touch = 0,
    bool updateProtected = false,
  }) async {
    await _executePrepared(
      (profile) => profile.pivSetManagementKey(
        algorithm: algorithm,
        key: key,
        touch: touch,
        updateProtected: updateProtected,
      ),
    );
  }

  /// A successful write replaces the observed algorithm IDs; upstream marks it
  /// ReprobeRequired, so the prepared profile is always discarded afterwards.
  Future<void> setAlgorithmConfig(Uint8List raw) async {
    final binding = preparedBinding;
    await _executePrepared(
      (profile) => profile.pivSetAlgorithmConfig(raw: raw),
    );
    discardProfile(binding);
  }

  Future<void> resetPinPukRetries(int pinRetries, int pukRetries) async {
    await _executePrepared(
      (profile) => profile.pivResetPinPukRetries(
        pinRetries: pinRetries,
        pukRetries: pukRetries,
      ),
    );
  }

  Future<Uint8List> sign({
    required int slot,
    required int algorithm,
    required Uint8List input,
    int inputKind = 1,
  }) async {
    return _executePrepared(
      (profile) => profile.pivSign(
        slot: slot,
        algorithm: algorithm,
        input: input,
        inputKind: inputKind,
      ),
    );
  }

  /// Firmware streaming modes: 0 = ML-DSA-65 (empty context), 1 = randomized
  /// Ed25519, 2 = SM2 full message. Classic digest/padded signing uses [sign].
  Future<Uint8List> signStreaming({
    required int slot,
    required int mode,
    required Uint8List message,
    Uint8List? userId,
  }) async {
    return _executePrepared(
      (profile) => profile.pivSignStreaming(
        slot: slot,
        mode: mode,
        message: message,
        userId: userId,
      ),
    );
  }

  /// INS F9 attestation certificate for a generated slot.
  Future<Uint8List> attest(int slot) async =>
      _executePrepared((profile) => profile.pivAttest(slot: slot));

  Future<Uint8List> derive(int slot, int algorithm, Uint8List peer) async =>
      _executePrepared(
        (profile) =>
            profile.pivDerive(slot: slot, algorithm: algorithm, peer: peer),
      );

  Future<Uint8List> decapsulate(int slot, Uint8List ciphertext) async =>
      _executePrepared(
        (profile) => profile.pivDecapsulate(slot: slot, ciphertext: ciphertext),
      );

  Future<void> importPrivateKey({
    required int slot,
    required int algorithm,
    required PivPrivateKeyData key,
    int pinPolicy = 0,
    int touchPolicy = 0,
  }) async {
    await _executePrepared(
      (profile) => profile.pivImportPrivateKey(
        slot: slot,
        algorithm: algorithm,
        key: key,
        pinPolicy: pinPolicy,
        touchPolicy: touchPolicy,
      ),
    );
  }

  /// Import a post-quantum seed (INS FE): kind 0 = ML-DSA-65 (32-byte seed),
  /// 1 = ML-KEM-768 (64-byte d||z seed).
  Future<void> importPqSeed({
    required int slot,
    required int kind,
    required Uint8List seed,
    int pinPolicy = 0,
    int touchPolicy = 0,
  }) async {
    await _executePrepared(
      (profile) => profile.pivImportPqSeed(
        slot: slot,
        kind: kind,
        seed: seed,
        pinPolicy: pinPolicy,
        touchPolicy: touchPolicy,
      ),
    );
  }

  /// Use the serial observed before authentication; never switch applets here.
  Future<String> readSerial() async {
    final serial = preparedBinding.profile.serial();
    if (serial == null) throw StateError('Device did not report a serial');
    return hex.encode(serial).toUpperCase();
  }

  /// Runs one prepared PIV operation. A rejected credential leaves immutable
  /// device observations valid; an uncertain exchange/acknowledgment discards
  /// the profile and cannot be used for dependent work.
  Future<Uint8List> _executePrepared(
    ProtocolOperation Function(ProtocolProfile) create, {
    bool allowMissing = false,
  }) => executePrepared(
    create,
    verifyProfileIdentity: true,
    discardOnOtherError: true,
    discardOnProtocolError: (error) =>
        error.exchangeAttempted &&
        error.details.kind != 'AuthenticationFailed' &&
        error.details.kind != 'PinBlocked' &&
        !(allowMissing && error.details.kind == 'NotFound'),
  );

  /// Selected-only empty VERIFY; 9000 does not imply a known retry count.
  Future<String> readPinRetries() async {
    final data = await _executePrepared(
      (_) => ProtocolOperation.pivRead(kind: PivReadOperation.pinStatus),
    );
    return lastStatusWord = hex.encode(data).toUpperCase();
  }

  Future<int?> readRemainingPinRetries() async {
    final status = await readPinRetries();
    if (status == '6983') return 0;
    if (status.startsWith('63C')) return int.parse(status[3], radix: 16);
    return null;
  }

  Future<bool> verifyPin(String pin) =>
      _credential(PivCredentialOperation.verifyPin, pin);

  Future<bool> changePin(String oldPin, String newPin) =>
      _credential(PivCredentialOperation.changePin, oldPin, newPin);

  Future<bool> changePuk(String oldPuk, String newPuk) =>
      _credential(PivCredentialOperation.changePuk, oldPuk, newPuk);

  Future<bool> unblockPin(String puk, String newPin) =>
      _credential(PivCredentialOperation.unblockPin, puk, newPin);

  Future<bool> _credential(
    PivCredentialOperation kind,
    String current, [
    String replacement = '',
  ]) async {
    final currentBytes = Uint8List.fromList(current.codeUnits);
    final replacementBytes = Uint8List.fromList(replacement.codeUnits);
    try {
      if (current.codeUnits.any((byte) => byte > 0xff) ||
          replacement.codeUnits.any((byte) => byte > 0xff)) {
        throw ArgumentError(
          'PIV credentials must contain single-byte characters',
        );
      }
      await _executePrepared(
        (profile) => profile.pivCredential(
          kind: kind,
          current: currentBytes,
          replacement: replacementBytes,
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
      currentBytes.fillRange(0, currentBytes.length, 0);
      replacementBytes.fillRange(0, replacementBytes.length, 0);
    }
  }

  /// Explicit destructive workflow; each attempt is an upstream credential
  /// operation. No retry follows transport, parsing or unexpected card failures.
  Future<bool> blockPuk() async {
    final random = Random.secure();
    for (var attempt = 0; attempt < 257; attempt++) {
      final candidate = List.generate(8, (_) => random.nextInt(10)).join();
      await changePuk(candidate, candidate);
      if (lastStatusWord == '6983') return true;
    }
    return false;
  }

  Future<bool> authenticateManagementKey(
    String key,
    AlgorithmType algorithm,
  ) async {
    final bytes = Uint8List.fromList(hex.decode(key));
    try {
      await _executePrepared(
        (profile) => profile.pivAuthenticateManagement(
          algorithm: algorithm.value,
          key: bytes,
        ),
      );
      return true;
    } on ProtocolException catch (error) {
      if (error.details.kind == 'AuthenticationFailed' ||
          error.details.kind == 'SecurityStatusNotSatisfied') {
        return false;
      }
      rethrow;
    } finally {
      bytes.fillRange(0, bytes.length, 0);
    }
  }

  /// Explicit discovery only when the prepared binding is missing or stale.
  /// A still-valid binding is reused as-is; discovery is never repeated
  /// implicitly.
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

  /// Reads the algorithm extension configuration through the upstream
  /// profile-based operation. On 3.0.x firmware the read sits behind
  /// management-key authentication (upstream capability
  /// PivProtectedAlgorithmConfigRead), so callers on such firmware pass
  /// [managementKey]: upstream SELECTs, authenticates and reads within one
  /// operation. Without a key the caller's selected transaction is reused.
  /// Firmware without the read fails the capability check at construction,
  /// before any authentication I/O.
  Future<PivAlgorithmExtensionConfig?> readAlgorithmExtensions({
    String? managementKey,
    AlgorithmType managementKeyAlgorithm = AlgorithmType.tdes,
  }) async {
    // The keyed operation SELECTs PIV and authenticates management within one
    // operation. A fresh prepared binding already implies PIV is the selected
    // applet (the binding is selection-bound), so the internal re-SELECT does
    // not disturb anyone else's evidence.
    await prepareIfStale();
    final keyBytes = managementKey == null
        ? null
        : Uint8List.fromList(hex.decode(managementKey));
    try {
      final data = await executePrepared(
        (profile) => profile.pivReadAlgorithmConfig(
          managementKey: keyBytes,
          managementKeyAlgorithm: managementKeyAlgorithm.value,
        ),
        verifyProfileIdentity: true,
        discardOnOtherError: true,
        discardOnProtocolError: (error) =>
            // The 3.0.x management-key gate rejects an unauthenticated read
            // with 6982 without touching card state; the profile stays valid.
            error.exchangeAttempted &&
            error.details.kind != 'AuthenticationFailed' &&
            error.details.kind != 'PinBlocked' &&
            error.details.kind != 'SecurityStatusNotSatisfied',
      );
      return PivAlgorithmExtensionConfig.decode(data);
    } on ProtocolException catch (error) {
      // An unavailable instruction (or the 3.0.x authentication gate on an
      // unauthenticated read) permits the existing firmware defaults. Other
      // security, malformed-data and unexpected card failures remain errors.
      if (error.details.kind == 'UnsupportedFeature' ||
          error.details.kind == 'SecurityStatusNotSatisfied') {
        return null;
      }
      rethrow;
    } finally {
      keyBytes?.fillRange(0, keyBytes.length, 0);
    }
  }

  /// Requires prepare() in this same lease. Algorithm interpretation comes from
  /// its observed profile, never caller-side cached UI configuration.
  Future<SlotInfo?> readMetadata(int slot) async {
    RangeError.checkValueInInterval(slot, 0, 0xff, 'slot');
    final binding = preparedBinding;
    Uint8List data;
    try {
      data = await executePrepared(
        (profile) => profile.pivMetadata(reference: slot),
      );
    } on ProtocolException catch (error) {
      if (error.details.kind == 'NotFound') return null;
      rethrow;
    }
    return SlotInfo.parse(
      slot,
      data,
      resolveAlgorithm: (wireId) {
        if (slot == 0x80 || slot == 0x81 || slot == 0x9b) {
          return AlgorithmType.fromValue(wireId);
        }
        final displayId = binding.profile.pivAlgorithmDisplayId(wireId: wireId);
        if (displayId == null) {
          throw FormatException('Unknown PIV metadata algorithm $wireId');
        }
        return AlgorithmType.fromValue(displayId);
      },
    );
  }

  /// Read and decompress a PIV certificate through libcanokey without SELECT.
  /// Only a missing object returns null; other card/protocol failures propagate.
  Future<Uint8List?> readCertificate(int objectId) async {
    RangeError.checkValueInInterval(objectId, 0, 0xff, 'objectId');
    final executor = _certificateExecutor;
    final binding = executor == null ? preparedBinding : null;
    lastStatusWord = null;
    try {
      cancellation.check();
      final certificate = executor != null
          ? await executor(objectId)
          : await executeProtocolOperation(
              binding!.profile.pivCertificate(objectId: objectId),
              transport,
              lease: binding.lease,
              cancellation: cancellation,
            );
      cancellation.check();
      binding?.check();
      lastStatusWord = '9000';
      return certificate;
    } on ProtocolException catch (error) {
      binding?.check();
      cancellation.check();
      lastStatusWord = formatStatusWord(error.details.statusWord);
      if (error.details.phase == 'Command' &&
          (error.details.statusWord == 0x6a82 ||
              error.details.statusWord == 0x6a88)) {
        return null;
      }
      rethrow;
    }
  }

  Uint8List _objectIdBytes(int objectId) {
    RangeError.checkValueInInterval(objectId, 0, 0xffffff, 'objectId');
    return Uint8List.fromList(
      hex.decode(objectId.toRadixString(16).padLeft(6, '0')),
    );
  }

  /// Read the normalized 53 value; only an absent object becomes null.
  Future<Uint8List?> readObject(int objectId) async {
    final id = _objectIdBytes(objectId);
    try {
      return await _executePrepared(
        (profile) => profile.pivReadObject(objectId: id),
        allowMissing: true,
      );
    } on ProtocolException catch (error) {
      if (error.details.kind == 'NotFound') return null;
      rethrow;
    }
  }

  /// The card checks existing authorization. Partial/uncertain writes terminate
  /// preparation; the executor never replays a mutation or runs a rollback.
  Future<void> writeObject(int objectId, Uint8List data) async {
    final id = _objectIdBytes(objectId);
    final copy = Uint8List.fromList(data);
    try {
      await _executePrepared(
        (profile) => profile.pivWriteObject(objectId: id, data: copy),
      );
    } finally {
      copy.fillRange(0, copy.length, 0);
    }
  }
}
