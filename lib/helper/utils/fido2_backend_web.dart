import 'package:fido2/fido2.dart';

Future<void> initializeFido2Backend() =>
    RustCrypto.initialize(wasmModuleUrl: 'fido2/fido2_crypto.js');
