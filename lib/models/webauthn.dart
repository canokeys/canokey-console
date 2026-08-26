import 'package:fido2/fido2.dart';

class WebAuthnSm2Config {
  final bool enabled;
  final int curveId;
  final int algoId;

  const WebAuthnSm2Config({
    required this.enabled,
    required this.curveId,
    required this.algoId,
  });
}

class WebAuthnItem {
  String rpId;
  String userName;
  String userDisplayName;
  List<int> userId;
  PublicKeyCredentialDescriptor credentialId;

  WebAuthnItem({
    required this.rpId,
    required this.userName,
    required this.userDisplayName,
    required this.userId,
    required this.credentialId,
  });
}
