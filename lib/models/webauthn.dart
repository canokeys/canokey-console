import 'package:fido2/fido2.dart';

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
