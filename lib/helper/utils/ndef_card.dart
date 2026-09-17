import 'dart:typed_data';

import 'package:canokey_console/helper/utils/card_client.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
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
/// NDEF applet and own CC/file selection (the file ID is CC-advertised),
/// 240-byte chunking, continuation and the crash-safe write order (zero NLEN,
/// message, real NLEN), preflighting read-only and oversized writes against
/// the CC. A failed write is never replayed; transport errors propagate
/// unchanged.
class NdefCardClient extends CardClientBase {
  NdefCardClient({super.transport, super.lease});

  Future<NdefCardData?> read() async {
    final capability = await _executeResult(
      ProtocolOperation.ndefReadCapability(),
      (step) => step.ndefCapability!,
    );
    if (capability == null) return null;
    final message = await _execute(ProtocolOperation.ndefReadMessage());
    if (message == null) return null;
    return NdefCardData(
      maxMessageLength: capability.maxMessageLength,
      readOnly: capability.readOnly,
      message: message,
    );
  }

  Future<bool> write(Uint8List message) async =>
      await _execute(ProtocolOperation.ndefWriteMessage(message: message)) !=
      null;

  /// Null only when the NDEF applet is absent (6A82 at SELECT).
  Future<Uint8List?> _execute(ProtocolOperation operation) =>
      _executeResult(operation, (step) => step.data!);

  Future<T?> _executeResult<T>(
    ProtocolOperation operation,
    T Function(ProtocolStep) result,
  ) async {
    cancellation.check();
    final lease = this.lease;
    // Every NDEF operation selects the applet before its target commands.
    lease.willSelectApplet();
    try {
      return await executeProtocolResult(
        operation,
        transport,
        result: result,
        lease: lease,
        cancellation: cancellation,
      );
    } on ProtocolException catch (error) {
      if (error.details.kind == 'UnsupportedDevice' &&
          error.details.phase == 'Select') {
        return null;
      }
      // A read-only file is rejected at the CC preflight (no status word) or,
      // on older library behavior, by the card's 6982 at UPDATE.
      if (error.details.kind == 'SecurityStatusNotSatisfied' ||
          error.details.statusWord == 0x6982) {
        throw const NdefReadOnlyException();
      }
      rethrow;
    }
  }
}
