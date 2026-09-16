import 'dart:math';
import 'dart:typed_data';

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/card_session.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/src/rust/api/protocol.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:convert/convert.dart';

class PivCardClient {
  PivCardClient({
    ApduTransport transport = const SmartCardApduTransport(),
    CardLease? lease,
    PivReadExecutor? readExecutor,
    PivCertificateExecutor? certificateExecutor,
    Future<void> Function()? prepareExecutor,
  }) : _transport = transport,
       _readExecutor = readExecutor,
       _certificateExecutor = certificateExecutor,
       _prepareExecutor = prepareExecutor,
       _injectedLease = lease {
    if (lease != null && transport is SmartCardApduTransport) {
      throw ArgumentError('Production transport uses SmartCard.currentLease');
    }
  }

  final ApduTransport _transport;
  final CardLease? _injectedLease;
  final PivReadExecutor? _readExecutor;
  final PivCertificateExecutor? _certificateExecutor;
  final Future<void> Function()? _prepareExecutor;
  final CardSessions _injectedSessions = CardSessions();
  _PivProfileBinding? _profile;

  CardLease get _lease => _transport is SmartCardApduTransport
      ? SmartCard.currentLease
      : _injectedLease ??
            _injectedSessions.current?.lease ??
            (throw StateError('Injected transport requires withSession'));

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

  /// Explicit discovery/selection before authentication. The lease owns the
  /// immutable observations; later metadata reads never probe or SELECT.
  Future<void> prepare() async {
    _cancellation.check();
    final override = _prepareExecutor;
    if (override != null) return override();
    final lease = _lease;
    if (lease.isExchanging) {
      throw StateError('Cannot replace a profile during an active operation');
    }
    lease.willSelectApplet();
    _profile?.close();
    _profile = null;
    final profile = await executeProfileProbe(
      ProtocolOperation.probePiv(),
      _transport,
      lease: lease,
      cancellation: _cancellation,
    );
    final binding = _PivProfileBinding(profile, lease);
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

  final CardCancellation _cancellation = CardCancellation();

  /// Request cancellation; the active executor drains I/O and frees its handle.
  void cancelPendingOperations() => _cancellation.cancel();

  Future<Uint8List> _read(PivReadOperation kind) async {
    _cancellation.check();
    final binding = kind == PivReadOperation.select ? null : _profile;
    binding?.check();
    final executor = _readExecutor;
    if (executor != null) return executor(kind);
    final data = await executeProtocolOperation(
      ProtocolOperation.pivRead(kind: kind),
      _transport,
      lease: _transport is SmartCardApduTransport
          ? null
          : _injectedLease ?? _injectedSessions.current?.lease,
      cancellation: _cancellation,
    );
    binding?.check();
    _cancellation.check();
    return data;
  }

  String? lastStatusWord;

  Future<void> select() async {
    final lease = _transport is SmartCardApduTransport
        ? SmartCard.currentLease
        : _injectedLease ?? _injectedSessions.current?.lease;
    lease?.willSelectApplet();
    final binding = _profile;
    if (binding != null) {
      if (binding.lease.isExchanging) {
        throw StateError('Cannot SELECT during an active operation');
      }
      _discardProfile(binding);
    }
    await _read(PivReadOperation.select);
  }

  Future<Uint8List> readVersion() async {
    return _read(PivReadOperation.version);
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
    return _executePrepared((profile) => profile.pivGenerateKey(
          slot: slot,
          algorithm: algorithm,
          pinPolicy: pinPolicy,
          touchPolicy: touchPolicy,
        ));
  }

  Future<void> deleteCertificate(int slot) async {
    await _executePrepared((profile) => profile.pivDeleteCertificate(objectId: slot));
  }

  Future<void> deleteKey(int slot) async {
    await _executePrepared((profile) => profile.pivDeleteKey(slot: slot));
  }

  Future<void> moveKey(int source, int target) async {
    await _executePrepared((profile) => profile.pivMoveKey(source: source, target: target));
  }

  Future<void> setManagementKey({
    required int algorithm,
    required Uint8List key,
    int touch = 0,
    bool updateProtected = false,
  }) async {
    await _executePrepared((profile) => profile.pivSetManagementKey(
          algorithm: algorithm,
          key: key,
          touch: touch,
          updateProtected: updateProtected,
        ));
  }

  /// A successful write replaces the observed algorithm IDs; upstream marks it
  /// ReprobeRequired, so the prepared profile is always discarded afterwards.
  Future<void> setAlgorithmConfig(Uint8List raw) async {
    final binding = _prepared;
    await _executePrepared((profile) => profile.pivSetAlgorithmConfig(raw: raw));
    _discardProfile(binding);
  }

  Future<void> setContainerName(int slot, String name) async {
    await _executePrepared((profile) => profile.pivSetContainerName(slot: slot, name: name));
  }

  Future<void> resetPinPukRetries(int pinRetries, int pukRetries) async {
    await _executePrepared((profile) => profile.pivResetPinPukRetries(
          pinRetries: pinRetries,
          pukRetries: pukRetries,
        ));
  }

  Future<Uint8List> sign({
    required int slot,
    required int algorithm,
    required Uint8List input,
    int inputKind = 1,
  }) async {
    return _executePrepared((profile) => profile.pivSign(
          slot: slot,
          algorithm: algorithm,
          input: input,
          inputKind: inputKind,
        ));
  }

  /// Firmware streaming modes: 0 = ML-DSA-65 (empty context), 1 = randomized
  /// Ed25519, 2 = SM2 full message. Classic digest/padded signing uses [sign].
  Future<Uint8List> signStreaming({
    required int slot,
    required int mode,
    required Uint8List message,
    Uint8List? userId,
  }) async {
    return _executePrepared((profile) => profile.pivSignStreaming(
          slot: slot,
          mode: mode,
          message: message,
          userId: userId,
        ));
  }

  /// INS F9 attestation certificate for a generated slot.
  Future<Uint8List> attest(int slot) async =>
      _executePrepared((profile) => profile.pivAttest(slot: slot));

  Future<Uint8List> decrypt(int slot, int algorithm, Uint8List ciphertext) async =>
      _executePrepared((profile) => profile.pivDecrypt(
            slot: slot,
            algorithm: algorithm,
            ciphertext: ciphertext,
          ));

  Future<Uint8List> derive(int slot, int algorithm, Uint8List peer) async =>
      _executePrepared((profile) => profile.pivDerive(
            slot: slot,
            algorithm: algorithm,
            peer: peer,
          ));

  Future<Uint8List> decapsulate(int slot, Uint8List ciphertext) async =>
      _executePrepared((profile) => profile.pivDecapsulate(
            slot: slot,
            ciphertext: ciphertext,
          ));

  Future<Uint8List> sm2Agreement({
    required int slot,
    required int role,
    required Uint8List peerStatic,
    required Uint8List peerEphemeral,
    Uint8List? userId,
    Uint8List? peerId,
    int keyLen = 32,
  }) async =>
      _executePrepared((profile) => profile.pivSm2Agreement(
            slot: slot,
            role: role,
            peerStatic: peerStatic,
            peerEphemeral: peerEphemeral,
            userId: userId,
            peerId: peerId,
            keyLen: keyLen,
          ));

  Future<void> importEcKey({
    required int slot,
    required int algorithm,
    required Uint8List scalar,
    int pinPolicy = 0,
    int touchPolicy = 0,
  }) async {
    await _executePrepared((profile) => profile.pivImportEcKey(
          slot: slot,
          algorithm: algorithm,
          scalar: scalar,
          pinPolicy: pinPolicy,
          touchPolicy: touchPolicy,
        ));
  }

  Future<void> importRsaKey({
    required int slot,
    required int algorithm,
    required Uint8List p,
    required Uint8List q,
    required Uint8List dp,
    required Uint8List dq,
    required Uint8List qinv,
    int pinPolicy = 0,
    int touchPolicy = 0,
  }) async {
    await _executePrepared((profile) => profile.pivImportRsaKey(
          slot: slot,
          algorithm: algorithm,
          p: p,
          q: q,
          dp: dp,
          dq: dq,
          qinv: qinv,
          pinPolicy: pinPolicy,
          touchPolicy: touchPolicy,
        ));
  }

  Future<void> importEd25519Key({
    required int slot,
    required Uint8List seed,
    int pinPolicy = 0,
    int touchPolicy = 0,
  }) async {
    await _executePrepared((profile) => profile.pivImportEd25519Key(
          slot: slot,
          seed: seed,
          pinPolicy: pinPolicy,
          touchPolicy: touchPolicy,
        ));
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
    await _executePrepared((profile) => profile.pivImportPqSeed(
          slot: slot,
          kind: kind,
          seed: seed,
          pinPolicy: pinPolicy,
          touchPolicy: touchPolicy,
        ));
  }

  _PivProfileBinding get _prepared {
    final lease = _lease;
    final binding = _profile;
    if (binding == null || !identical(binding.lease, lease)) {
      throw StateError('Prepare PIV in this lease before this operation');
    }
    binding.check();
    _cancellation.check();
    if (lease.isExchanging) {
      throw StateError('A card operation is already active');
    }
    return binding;
  }

  void _discardProfile(_PivProfileBinding binding) {
    binding.close();
    if (identical(_profile, binding)) _profile = null;
  }

  /// Use the serial observed before authentication; never switch applets here.
  Future<String> readSerial() async {
    final serial = _prepared.profile.serial();
    if (serial == null) throw StateError('Device did not report a serial');
    return hex.encode(serial).toUpperCase();
  }

  Future<Uint8List> _executePrepared(
    ProtocolOperation Function(ProtocolProfile) create, {
    bool allowMissing = false,
  }) async {
    final binding = _prepared;
    lastStatusWord = null;
    try {
      final data = await executeProtocolOperation(
        create(binding.profile),
        _transport,
        lease: binding.lease,
        cancellation: _cancellation,
      );
      binding.check();
      _cancellation.check();
      if (!identical(_profile, binding)) {
        throw StateError('PIV profile replaced');
      }
      lastStatusWord = '9000';
      return data;
    } on ProtocolException catch (error) {
      binding.check();
      _cancellation.check();
      final status = error.details.statusWord;
      lastStatusWord = status?.toRadixString(16).padLeft(4, '0').toUpperCase();
      // A rejected credential leaves immutable device observations valid. An
      // uncertain exchange/acknowledgment cannot be used for dependent work.
      if (error.exchangeAttempted &&
          error.details.kind != 'AuthenticationFailed' &&
          error.details.kind != 'PinBlocked' &&
          !(allowMissing && error.details.kind == 'NotFound')) {
        _discardProfile(binding);
      }
      rethrow;
    } catch (_) {
      _discardProfile(binding);
      rethrow;
    }
  }

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
      if (kind != PivCredentialOperation.logout &&
          (error.details.kind == 'AuthenticationFailed' ||
              error.details.kind == 'PinBlocked')) {
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

  Future<void> logout() async {
    await _credential(PivCredentialOperation.logout, '');
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

  /// Reads the algorithm extension configuration. Firmware 3.0.x gates this
  /// read behind management-key authentication and every SELECT resets that
  /// status, so callers on such firmware pass [managementKey]: the client
  /// SELECTs, prepares and authenticates in the same selection before reading.
  Future<PivAlgorithmExtensionConfig?> readAlgorithmExtensions({
    String? managementKey,
    AlgorithmType managementKeyAlgorithm = AlgorithmType.tdes,
  }) async {
    await select();
    if (managementKey != null) {
      await prepare();
      if (!await authenticateManagementKey(
        managementKey,
        managementKeyAlgorithm,
      )) {
        throw StateError('PIV management key authentication failed');
      }
    }
    try {
      final data = await _read(PivReadOperation.algorithmConfiguration);
      return PivAlgorithmExtensionConfig.decode(data);
    } on ProtocolException catch (error) {
      // Only an unavailable instruction permits the existing firmware fallback.
      // Security, malformed-data and unexpected card failures remain errors.
      if (error.details.kind == 'UnsupportedFeature') return null;
      rethrow;
    }
  }

  /// Requires prepare() in this same lease. Algorithm interpretation comes from
  /// its observed profile, never the caller's cached algorithmExtensionConfig.
  Future<SlotInfo?> readMetadata(
    int slot, {
    PivAlgorithmExtensionConfig? algorithmExtensionConfig,
  }) async {
    RangeError.checkValueInInterval(slot, 0, 0xff, 'slot');
    final lease = _lease;
    final binding = _profile;
    if (binding == null || !identical(binding.lease, lease)) {
      throw StateError('Prepare PIV in this lease before reading metadata');
    }
    binding.check();
    _cancellation.check();
    lastStatusWord = null;
    Uint8List data;
    try {
      data = await executeProtocolOperation(
        binding.profile.pivMetadata(reference: slot),
        _transport,
        lease: lease,
        cancellation: _cancellation,
      );
      binding.check();
      _cancellation.check();
      lastStatusWord = '9000';
    } on ProtocolException catch (error) {
      binding.check();
      _cancellation.check();
      final status = error.details.statusWord;
      lastStatusWord = status?.toRadixString(16).padLeft(4, '0').toUpperCase();
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
    final binding = executor == null ? _prepared : null;
    lastStatusWord = null;
    try {
      _cancellation.check();
      final certificate = executor != null
          ? await executor(objectId)
          : await executeProtocolOperation(
              binding!.profile.pivCertificate(objectId: objectId),
              _transport,
              lease: binding.lease,
              cancellation: _cancellation,
            );
      _cancellation.check();
      binding?.check();
      lastStatusWord = '9000';
      return certificate;
    } on ProtocolException catch (error) {
      binding?.check();
      _cancellation.check();
      final status = error.details.statusWord;
      lastStatusWord = status?.toRadixString(16).padLeft(4, '0').toUpperCase();
      if (error.details.phase == 'Command' &&
          (status == 0x6a82 || status == 0x6a88)) {
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

class _PivProfileBinding {
  _PivProfileBinding(this.profile, this.lease)
    : selectionGeneration = lease.selectionGeneration,
      profileGeneration = lease.profileGeneration;
  final ProtocolProfile profile;
  final CardLease lease;
  bool _closed = false;
  final int selectionGeneration;
  final int profileGeneration;

  void check() {
    lease.check();
    if (_closed ||
        selectionGeneration != lease.selectionGeneration ||
        profileGeneration != lease.profileGeneration) {
      throw StateError(
        'PIV selection or device observations are no longer current',
      );
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
