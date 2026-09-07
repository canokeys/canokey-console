import 'dart:io';

import 'package:fido2/fido2.dart';

Future<void> initializeFido2Backend() async {
  if (RustCrypto.isInitialized) return;
  const stem = 'rust_lib_canokey_console';
  final name = Platform.isWindows
      ? '$stem.dll'
      : Platform.isMacOS || Platform.isIOS
      ? 'lib$stem.dylib'
      : 'lib$stem.so';
  final directory =
      Platform.environment['FRB_DART_LOAD_EXTERNAL_LIBRARY_NATIVE_LIB_DIR'] ??
      'rust/target/release';
  final developmentLibrary = File.fromUri(
    Uri.directory(directory).resolve(name),
  );
  final path = !Platform.isAndroid && developmentLibrary.existsSync()
      ? developmentLibrary.absolute.path
      : Platform.isMacOS || Platform.isIOS
      ? '$stem.framework/$stem'
      : name;
  await RustCrypto.initialize(
    libraryPath: Platform.environment['FIDO2_CRYPTO_LIBRARY'] ?? path,
  );
}
