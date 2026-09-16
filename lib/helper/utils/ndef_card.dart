import 'dart:typed_data';

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/card_session.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/src/rust/api/protocol.dart';

class NdefCardData {
  const NdefCardData({
    required this.maxMessageLength,
    required this.readOnly,
    required this.message,
  });

  final int maxMessageLength;
  final bool readOnly;
  final Uint8List message;
}

class NdefReadOnlyException implements Exception {
  const NdefReadOnlyException();
}

/// libcanokey-backed NDEF operations. These profile-free operations SELECT the
/// NDEF applet and own CC/file selection, 240-byte chunking, continuation and
/// the crash-safe write order (zero NLEN, message, real NLEN). A failed write
/// is never replayed; transport errors propagate unchanged.
class NdefCardClient {
  NdefCardClient({
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

  CardLease get _lease => _transport is SmartCardApduTransport
      ? SmartCard.currentLease
      : _injectedLease ??
            _injectedSessions.current?.lease ??
            (throw StateError('Injected NDEF transport requires withSession'));

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
  void cancelPendingOperations() => _cancellation.cancel();

  Future<NdefCardData?> read() async {
    final capability = await _execute(ProtocolOperation.ndefReadCapability());
    if (capability == null) return null;
    if (capability.length != 3) {
      throw const FormatException('Invalid NDEF capability data');
    }
    final message = await _execute(ProtocolOperation.ndefReadMessage());
    if (message == null) return null;
    return NdefCardData(
      maxMessageLength: (capability[0] << 8) | capability[1],
      readOnly: capability[2] != 0,
      message: message,
    );
  }

  Future<bool> write(Uint8List message) async =>
      await _execute(ProtocolOperation.ndefWriteMessage(message: message)) !=
      null;

  /// Null only when the NDEF applet is absent (6A82 at SELECT).
  Future<Uint8List?> _execute(ProtocolOperation operation) async {
    _cancellation.check();
    final lease = _lease;
    // Every NDEF operation selects the applet before its target commands.
    lease.willSelectApplet();
    try {
      return await executeProtocolOperation(
        operation,
        _transport,
        lease: lease,
        cancellation: _cancellation,
      );
    } on ProtocolException catch (error) {
      if (error.details.kind == 'UnsupportedDevice' &&
          error.details.phase == 'Select') {
        return null;
      }
      if (error.details.statusWord == 0x6982) {
        throw const NdefReadOnlyException();
      }
      rethrow;
    }
  }
}
