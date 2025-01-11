import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';

Stream<LicenseEntry> parseRustLicenses() async* {
  final jsonStr = await rootBundle.loadString('rust/THIRD_PARTY_LICENSES.json');
  final libraries = jsonDecode(jsonStr) as List<dynamic>;
  for (final library in libraries) {
    final name = library['package_name'] as String;
    final version = library['package_version'] as String;
    final repo = library['repository'] as String;
    final license = library['license'] ?? 'Unknown';
    yield LicenseEntryWithLineBreaks(['$name [Rust]'], '''Crate: $name

Version: $version

Repository: $repo

License: $license
'''.trim());
  }
}
