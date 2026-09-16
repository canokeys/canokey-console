import 'dart:convert';
import 'dart:typed_data';

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/card_session.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:canokey_console/src/rust/api/protocol.dart';
import 'package:convert/convert.dart';

/// Pass slot operations share the upstream Admin facade: each operation either
/// SELECTs Admin (a protected write verifying its own explicit PIN) or reuses
/// the lease's recorded Admin authentication via `Access::Existing`. A UI PIN
/// cache is never authorization evidence.
class PassCardClient {
  PassCardClient({
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
            (throw StateError('Injected Pass transport requires withSession'));

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

  /// Explicit minimal Admin discovery, before any slot operation. Repeat after
  /// a slot write, including an uncertain write; never auto-reprobe.
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

  /// Runs one Admin request. A still-valid recorded Admin authentication on
  /// this lease selects `Access::Existing` (no SELECT/VERIFY, no PIN); any
  /// other request SELECTs and verifies only its explicitly supplied PIN.
  Future<AdminResult> _execute(
    ProtocolOperation Function(ProtocolProfile profile, Uint8List? pin, bool existing)
    create, {
    String? pin,
    bool mutation = false,
  }) async {
    final binding = _prepared;
    lastResponse = null;
    lastProgress = null;
    final existing = binding.lease.hasAdminAuthentication;
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
      // A failed Existing request leaves the card-side session uncertain.
      if (existing) binding.lease.invalidateAdminAuthentication();
      rethrow;
    } catch (_) {
      binding.close();
      if (identical(_profile, binding)) _profile = null;
      rethrow;
    } finally {
      pinBytes?.fillRange(0, pinBytes.length, 0);
      final progress = lastProgress;
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

  Future<List<PassSlot>> readSlots() async {
    final result = await _execute(
      (profile, pinBytes, existing) =>
          profile.adminPassSlots(pin: pinBytes, existing: existing),
    );
    return PassSlot.decode(result.data);
  }

  /// Returns false only when the card rejects or blocks the supplied PIN;
  /// other protocol and transport failures propagate with their status word.
  Future<bool> setSlot(
    int index,
    PassSlotType type,
    String password,
    bool withEnter, {
    required String pin,
  }) async {
    if (index != 1 && index != 2) {
      throw ArgumentError.value(index, 'index', 'Pass slot must be 1 or 2');
    }
    final kind = switch (type) {
      PassSlotType.none => 0,
      PassSlotType.static => 1,
      PassSlotType.hmacSha1 => 2,
      PassSlotType.oath => throw ArgumentError.value(
        type,
        'type',
        'OATH slots are configured by the OATH applet',
      ),
      PassSlotType.unknown => throw ArgumentError.value(
        type,
        'type',
        'Unknown Pass slots cannot be modified',
      ),
    };
    Uint8List? secret;
    if (type == PassSlotType.static) {
      final passwordBytes = password.codeUnits;
      if (passwordBytes.length > 32 ||
          passwordBytes.any((byte) => byte < 0x20 || byte > 0x7E)) {
        throw ArgumentError.value(
          password,
          'password',
          'Static passwords must be at most 32 printable ASCII characters',
        );
      }
      secret = Uint8List.fromList(passwordBytes);
    } else if (type == PassSlotType.hmacSha1) {
      final List<int> key;
      try {
        key = hex.decode(password);
      } on FormatException {
        throw ArgumentError.value(
          password,
          'password',
          'HMAC-SHA1 keys are hex encoded',
        );
      }
      if (key.length != 20) {
        throw ArgumentError.value(
          password,
          'password',
          'HMAC-SHA1 keys are 20 bytes',
        );
      }
      secret = Uint8List.fromList(key);
    }
    try {
      await _execute(
        (profile, pinBytes, existing) => profile.adminSetPassSlot(
          slot: index - 1,
          kind: kind,
          data: secret ?? const [],
          appendEnter: type == PassSlotType.static && withEnter,
          pin: pinBytes,
          existing: existing,
        ),
        pin: pin,
        mutation: true,
      );
      return true;
    } on ProtocolException catch (error) {
      if (error.details.kind == 'AuthenticationFailed' ||
          error.details.kind == 'PinBlocked') {
        return false;
      }
      rethrow;
    } finally {
      secret?.fillRange(0, secret.length, 0);
    }
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
