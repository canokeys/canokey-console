import 'package:canokey_console/models/piv.dart';
import 'package:flutter/foundation.dart';

enum PivMacOsSetupAction {
  keep,
  create,
  issueCertificate,
  replaceCertificate,
  replaceKey,
}

class PivMacOsSetupSlot {
  PivMacOsSetupSlot({
    required this.slotNumber,
    required this.key,
    required List<int>? certificate,
    required this.compatible,
  }) : certificate = certificate == null
           ? null
           : Uint8List.fromList(certificate),
       publicKey = List<int>.unmodifiable(key?.public ?? const []);

  final String slotNumber;
  final SlotInfo? key;
  final Uint8List? certificate;
  final List<int> publicKey;
  final bool compatible;

  bool get canReuseKey =>
      key != null &&
      publicKey.isNotEmpty &&
      (key!.algorithm == AlgorithmType.eccp256 ||
          key!.algorithm == AlgorithmType.rsa2048);

  PivMacOsSetupAction get action => compatible
      ? PivMacOsSetupAction.keep
      : key == null && certificate == null
      ? PivMacOsSetupAction.create
      : canReuseKey
      ? (certificate == null
            ? PivMacOsSetupAction.issueCertificate
            : PivMacOsSetupAction.replaceCertificate)
      : PivMacOsSetupAction.replaceKey;

  bool get needsReplacementConsent =>
      action == PivMacOsSetupAction.replaceCertificate ||
      action == PivMacOsSetupAction.replaceKey;

  bool sameContents(PivMacOsSetupSlot other) =>
      slotNumber == other.slotNumber &&
      key?.algorithm == other.key?.algorithm &&
      key?.pinPolicy == other.key?.pinPolicy &&
      key?.touchPolicy == other.key?.touchPolicy &&
      listEquals(publicKey, other.publicKey) &&
      listEquals(certificate, other.certificate);
}

class PivMacOsSetupPlan {
  PivMacOsSetupPlan({
    required this.serial,
    required List<PivMacOsSetupSlot> slots,
  }) : slots = List.unmodifiable(slots);
  final String serial;
  final List<PivMacOsSetupSlot> slots;

  bool get complete =>
      slots.length == 2 && slots.every((slot) => slot.compatible);
  bool get needsReplacementConsent =>
      slots.any((slot) => slot.needsReplacementConsent);
  bool sameContents(PivMacOsSetupPlan other) =>
      serial == other.serial &&
      slots.length == other.slots.length &&
      List.generate(
        slots.length,
        (i) => slots[i].sameContents(other.slots[i]),
      ).every((same) => same);
}
