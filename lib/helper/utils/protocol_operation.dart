import 'dart:typed_data';

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/src/rust/api/protocol.dart';
import 'package:convert/convert.dart';

/// Protocol failures retain card status/context; transport exceptions pass through.
class ProtocolException implements Exception {
  const ProtocolException(this.details);

  final ProtocolError details;

  @override
  String toString() =>
      'libcanokey: ${details.kind} during ${details.phase}'
      '${details.statusWord == null ? '' : ' (SW=${details.statusWord!.toRadixString(16).padLeft(4, '0').toUpperCase()})'}';
}

/// The caller retains its selected card session for this entire future.
/// This executor only performs raw exchanges; libcanokey owns continuation,
/// bounded response parsing, and safe Le correction. No implicit replay occurs.
Future<Uint8List> executeProtocolOperation(
  ProtocolOperation operation,
  ApduTransport transport,
) async {
  try {
    var step = operation.start();
    while (true) {
      if (step.error case final error?) throw ProtocolException(error);
      if (step.data case final data?) return data;
      final command = step.command;
      if (command == null) throw StateError('Missing libcanokey command');
      Uint8List? response;
      try {
        response = Uint8List.fromList(
          hex.decode(
            await transport.transceive(hex.encode(command).toUpperCase()),
          ),
        );
        step = operation.advance(response: response);
      } finally {
        command.fillRange(0, command.length, 0);
        response?.fillRange(0, response.length, 0);
      }
    }
  } finally {
    operation.close();
    operation.dispose();
  }
}

typedef PivReadExecutor = Future<Uint8List> Function(PivReadOperation kind);
