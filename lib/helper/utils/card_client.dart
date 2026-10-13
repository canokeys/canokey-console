import 'dart:typed_data';

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/card_session.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/src/rust/api/protocol.dart';

/// Immutable profile evidence bound to one physical lease. The binding expires
/// on lease replacement and on profile invalidation; with [bindSelection] it
/// additionally expires on any later applet selection. The profile is
/// evidence, never an authentication token.
class ProfileBinding {
  ProfileBinding(this.profile, this.lease, {bool bindSelection = false})
    : profileGeneration = lease.profileGeneration,
      selectionGeneration = bindSelection ? lease.selectionGeneration : null,
      _observedSelectionGeneration = lease.selectionGeneration;

  final ProtocolProfile profile;
  final CardLease lease;
  final int profileGeneration;
  final int? selectionGeneration;
  final int _observedSelectionGeneration;
  bool _closed = false;

  /// True while no applet selection has happened since this binding's probe
  /// left its applet selected. Non-fatal evidence: callers that can re-SELECT
  /// fall back instead of failing.
  bool get selectionFresh =>
      !_closed &&
      profileGeneration == lease.profileGeneration &&
      _observedSelectionGeneration == lease.selectionGeneration;

  void check() {
    lease.check();
    final selection = selectionGeneration;
    if (_closed ||
        profileGeneration != lease.profileGeneration ||
        (selection != null && selection != lease.selectionGeneration)) {
      throw StateError('Card profile requires explicit discovery');
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

/// Shared transport/lease plumbing for every card client: the production
/// transport reads SmartCard.currentLease, injected transports use a
/// caller-owned lease or [withSession], and cancellation is local evidence
/// that never races the executor's handle cleanup.
abstract class CardClientBase {
  CardClientBase({
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

  final CardCancellation cancellation = CardCancellation();

  ApduTransport get transport => _transport;

  CardLease get lease => _transport is SmartCardApduTransport
      ? SmartCard.currentLease
      : injectedCurrentLease ??
            (throw StateError('Injected transport requires withSession'));

  /// The caller-owned lease bound for an injected transport, if any.
  CardLease? get injectedCurrentLease =>
      _injectedLease ?? _injectedSessions.current?.lease;

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

  /// Request cancellation; the active executor drains I/O and frees its handle.
  void cancelPendingOperations() => cancellation.cancel();
}

/// Base for clients whose operations run against an explicitly prepared
/// [ProfileBinding]. Discovery is explicit, evidence is revalidated before and
/// after every operation, and failures never trigger a hidden re-probe.
abstract class ProfileCardClient extends CardClientBase {
  ProfileCardClient({super.transport, super.lease, required bool bindSelection})
    : _bindSelection = bindSelection;

  final bool _bindSelection;
  ProfileBinding? _profile;

  /// Status word of the most recent prepared operation, uppercase hex; null
  /// when no card response was observed.
  String? lastStatusWord;

  ProfileBinding? get currentProfile => _profile;

  /// The prepared binding for this lease, revalidated before every operation.
  ProfileBinding get preparedBinding {
    final lease = this.lease;
    final binding = _profile;
    if (binding == null || !identical(binding.lease, lease)) {
      throw StateError('Prepare the card profile in the current lease first');
    }
    binding.check();
    cancellation.check();
    if (lease.isExchanging) {
      throw StateError('A card operation is already active');
    }
    return binding;
  }

  /// Explicit minimal discovery, before any authentication. Repeat after a
  /// profile-affecting write, including an uncertain write; never auto-reprobe.
  Future<void> prepareProfile(
    ProtocolOperation Function() probe, {
    bool rejectWhileExchanging = false,
  }) async {
    cancellation.check();
    final lease = this.lease;
    if (rejectWhileExchanging && lease.isExchanging) {
      throw StateError('Cannot replace a profile during an active operation');
    }
    lease.willSelectApplet();
    _profile?.close();
    _profile = null;
    final profile = await executeProfileProbe(
      probe(),
      transport,
      lease: lease,
      cancellation: cancellation,
    );
    final binding = ProfileBinding(
      profile,
      lease,
      bindSelection: _bindSelection,
    );
    try {
      lease.check();
      cancellation.check();
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

  /// Drop stale or uncertain profile evidence; never resumes or retries.
  void discardProfile(ProfileBinding binding) {
    binding.close();
    if (identical(_profile, binding)) _profile = null;
  }

  /// Runs one prepared libcanokey operation and records [lastStatusWord].
  ///
  /// - [selectApplet]: the operation SELECTs its applet first, expiring other
  ///   applets' selection evidence.
  /// - [verifyProfileIdentity]: a profile replaced during the operation fails
  ///   instead of publishing a result.
  /// - [recheckOnProtocolError]: revalidate binding/cancellation on a protocol
  ///   failure before recording the status word.
  /// - [discardOnOtherError]: non-protocol failures discard the profile.
  /// - [discardOnProtocolError]: decides per protocol failure whether the
  ///   profile evidence survives (e.g. expected credential rejections).
  Future<Uint8List> executePrepared(
    ProtocolOperation Function(ProtocolProfile profile) create, {
    bool selectApplet = false,
    bool verifyProfileIdentity = false,
    bool recheckOnProtocolError = true,
    bool discardOnOtherError = false,
    bool Function(ProtocolException error)? discardOnProtocolError,
  }) => executePreparedResult(
    create,
    result: (step) => step.data!,
    selectApplet: selectApplet,
    verifyProfileIdentity: verifyProfileIdentity,
    recheckOnProtocolError: recheckOnProtocolError,
    discardOnOtherError: discardOnOtherError,
    discardOnProtocolError: discardOnProtocolError,
  );

  Future<T> executePreparedResult<T>(
    ProtocolOperation Function(ProtocolProfile profile) create, {
    required T Function(ProtocolStep) result,
    bool selectApplet = false,
    bool verifyProfileIdentity = false,
    bool recheckOnProtocolError = true,
    bool discardOnOtherError = false,
    bool Function(ProtocolException error)? discardOnProtocolError,
  }) async {
    final binding = preparedBinding;
    lastStatusWord = null;
    if (selectApplet) binding.lease.willSelectApplet();
    try {
      final data = await executeProtocolResult(
        create(binding.profile),
        transport,
        result: result,
        lease: binding.lease,
        cancellation: cancellation,
      );
      binding.check();
      cancellation.check();
      if (verifyProfileIdentity && !identical(_profile, binding)) {
        throw StateError('Card profile replaced');
      }
      lastStatusWord = '9000';
      return data;
    } on ProtocolException catch (error) {
      if (recheckOnProtocolError) {
        binding.check();
        cancellation.check();
      }
      lastStatusWord = formatStatusWord(error.details.statusWord);
      if (discardOnProtocolError?.call(error) ?? false) {
        discardProfile(binding);
      }
      rethrow;
    } catch (_) {
      if (discardOnOtherError) discardProfile(binding);
      rethrow;
    }
  }
}
