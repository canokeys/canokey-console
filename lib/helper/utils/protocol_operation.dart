import 'dart:typed_data';

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/card_session.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/src/rust/api/protocol.dart';
import 'package:convert/convert.dart';

/// Uppercase four-digit hex rendering of a card status word.
String? formatStatusWord(int? status) =>
    status?.toRadixString(16).padLeft(4, '0').toUpperCase();

/// Protocol failures retain card status/context; transport exceptions pass through.
class ProtocolException implements Exception {
  const ProtocolException(this.details, {this.exchangeAttempted = false});

  final ProtocolError details;

  /// Local executor evidence, independent of the protocol error phase.
  final bool exchangeAttempted;

  @override
  String toString() {
    final status = formatStatusWord(details.statusWord);
    return 'libcanokey: ${details.kind} during ${details.phase}'
        '${status == null ? '' : ' (SW=$status)'}';
  }
}

/// The caller retains its selected card session for this entire future.
/// This executor only performs raw exchanges; libcanokey owns continuation,
/// bounded response parsing, and safe Le correction. No implicit replay occurs.
Future<Uint8List> executeProtocolOperation(
  ProtocolOperation operation,
  ApduTransport transport, {
  CardLease? lease,
  CardCancellation? cancellation,
}) => executeProtocolResult(
  operation,
  transport,
  lease: lease,
  cancellation: cancellation,
  result: (step) => step.data ?? (throw StateError('Expected byte result')),
);

Future<ProtocolProfile> executeProfileProbe(
  ProtocolOperation operation,
  ApduTransport transport, {
  required CardLease lease,
  CardCancellation? cancellation,
}) => executeProtocolResult(
  operation,
  transport,
  lease: lease,
  cancellation: cancellation,
  result: (step) =>
      step.profile ?? (throw StateError('Expected profile result')),
);

Future<AdminResult> executeAdminOperation(
  ProtocolOperation operation,
  ApduTransport transport, {
  required CardLease lease,
  CardCancellation? cancellation,
  required void Function(AdminProgress) onProgress,
}) => executeProtocolResult(
  operation,
  transport,
  lease: lease,
  cancellation: cancellation,
  onAdminProgress: onProgress,
  result: (step) {
    final result = step.admin ?? (throw StateError('Expected Admin result'));
    onProgress(result.progress);
    return result;
  },
);

/// Executes a typed result under the same lease and cleanup rules as byte results.
Future<T> executeProtocolResult<T>(
  ProtocolOperation operation,
  ApduTransport transport, {
  CardLease? lease,
  CardCancellation? cancellation,
  required T Function(ProtocolStep) result,
  void Function(AdminProgress)? onAdminProgress,
}) async {
  CardOperationLease? reservation;
  var exchangeAttempted = false;
  try {
    lease ??= transport is SmartCardApduTransport
        ? SmartCard.currentLease
        : null;
    reservation = lease?.beginOperation();
    void check() {
      reservation?.check();
      cancellation?.check();
    }

    check();
    var step = operation.start();
    while (true) {
      if (step.error case final error?) {
        throw ProtocolException(error, exchangeAttempted: exchangeAttempted);
      }
      if (step.data != null ||
          step.profile != null ||
          step.admin != null ||
          step.pinSession != null ||
          step.pinToken != null ||
          step.oathSelection != null ||
          step.oathCalculations != null ||
          step.ctapInfo != null ||
          step.ndefCapability != null ||
          step.ctapRps != null ||
          step.ctapCredentials != null) {
        try {
          check();
          return result(step);
        } catch (_) {
          final data = step.data ?? step.admin?.data;
          data?.fillRange(0, data.length, 0);
          for (final calculation
              in step.oathCalculations ?? <OathCalculation>[]) {
            final code = calculation.fullCode;
            code?.fillRange(0, code.length, 0);
          }
          final profile = step.profile;
          if (profile != null) {
            try {
              profile.close();
            } finally {
              profile.dispose();
            }
          }
          final pinSession = step.pinSession;
          if (pinSession != null) {
            try {
              pinSession.close();
            } finally {
              pinSession.dispose();
            }
          }
          final pinToken = step.pinToken;
          if (pinToken != null) {
            try {
              pinToken.close();
            } finally {
              pinToken.dispose();
            }
          }
          rethrow;
        }
      }
      final command = step.command;
      if (command == null) throw StateError('Missing libcanokey command');
      Uint8List? response;
      try {
        check();
        final encoded = hex.encode(command).toUpperCase();
        exchangeAttempted = true;
        response = Uint8List.fromList(
          hex.decode(
            await (reservation?.exchange(encoded) ??
                transport.transceive(encoded)),
          ),
        );
        check();
        step = operation.advance(response: response);
      } finally {
        command.fillRange(0, command.length, 0);
        response?.fillRange(0, response.length, 0);
      }
    }
  } finally {
    try {
      try {
        if (onAdminProgress != null) {
          final progress = operation.adminProgress();
          if (progress != null) onAdminProgress(progress);
        }
      } finally {
        operation.close();
      }
    } finally {
      try {
        operation.dispose();
      } finally {
        reservation?.close();
      }
    }
  }
}

typedef PivCertificateExecutor = Future<Uint8List> Function(int objectId);
