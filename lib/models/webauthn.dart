import 'package:fido2/fido2.dart';

class WebAuthnItem {
  String rpId;
  String userName;
  String userDisplayName;
  PublicKeyCredentialDescriptor credentialId;

  WebAuthnItem({
    required this.rpId,
    required this.userName,
    required this.userDisplayName,
    required this.credentialId,
  });
}
