import 'package:canokey_console/models/piv.dart';

/// Editable settings for an end-entity certificate, before any card writes.
class PivSelfSignOptions {
  PivSelfSignOptions({required this.slotNumber, required this.pinPolicy});

  final String slotNumber;

  AlgorithmType algorithm = AlgorithmType.eccp256;
  PinPolicy pinPolicy;
  TouchPolicy touchPolicy = TouchPolicy.never;
  bool includeBasicConstraints = false;
  int keyUsage = 0;
  bool keyUsageCritical = true;
  final Set<String> extendedKeyUsage = {};

  static const clientAuth = '1.3.6.1.5.5.7.3.2';

  bool get supportsMacOsLogin => slotNumber == '9A' || slotNumber == '9D';

  // The documented two-slot setup uses 9A for authentication and 9D for
  // wrapping the login keychain key. See docs/piv-macos-login.md.
  int get _macOsKeyUsage => slotNumber == '9A'
      ? 1 // digitalSignature
      : algorithm == AlgorithmType.rsa2048
      ? 4 // keyEncipherment
      : 16; // keyAgreement

  void applyMacOsLogin() {
    if (!supportsMacOsLogin) {
      throw StateError('The macOS setup uses slots 9A and 9D');
    }
    if (algorithm != AlgorithmType.eccp256 &&
        algorithm != AlgorithmType.rsa2048) {
      algorithm = AlgorithmType.eccp256;
    }
    pinPolicy = PinPolicy.once;
    includeBasicConstraints = true;
    keyUsage = _macOsKeyUsage;
    keyUsageCritical = true;
    extendedKeyUsage.clear();
    if (slotNumber == '9A') extendedKeyUsage.add(clientAuth);
  }

  bool get matchesMacOsLogin =>
      supportsMacOsLogin &&
      (algorithm == AlgorithmType.eccp256 ||
          algorithm == AlgorithmType.rsa2048) &&
      pinPolicy == PinPolicy.once &&
      includeBasicConstraints &&
      keyUsage == _macOsKeyUsage &&
      keyUsageCritical &&
      (slotNumber == '9A'
          ? extendedKeyUsage.length == 1 &&
                extendedKeyUsage.contains(clientAuth)
          : extendedKeyUsage.isEmpty);
}
