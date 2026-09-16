import 'dart:typed_data';

import 'package:canokey_console/helper/utils/admin_card.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:canokey_console/src/rust/api/protocol.dart';
import 'package:convert/convert.dart';

/// Pass slot operations share the upstream Admin facade: each operation either
/// SELECTs Admin (a protected write verifying its own explicit PIN) or reuses
/// the lease's recorded Admin authentication via `Access::Existing`. A UI PIN
/// cache is never authorization evidence.
class PassCardClient extends AdminSessionCardClient {
  PassCardClient({super.transport, super.lease});

  /// Explicit minimal Admin discovery, before any slot operation. Repeat after
  /// a slot write, including an uncertain write; never auto-reprobe.
  Future<void> prepare() => prepareProfile(ProtocolOperation.probeAdmin);

  /// Reads both slots. Firmware gates INS 43 behind Admin authentication, so
  /// callers pass the lease's verified PIN; a still-valid recorded Admin
  /// authentication takes precedence and the PIN is not sent at all.
  Future<List<PassSlot>> readSlots({String? pin}) async {
    final result = await executeAdminRequest(
      (profile, pinBytes, existing) =>
          profile.adminPassSlots(pin: pinBytes, existing: existing),
      pin: pin,
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
      await executeAdminRequest(
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
