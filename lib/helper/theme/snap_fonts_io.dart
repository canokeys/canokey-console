import 'dart:io';

import 'package:canokey_console/helper/theme/app_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

Future<bool> loadSnapChineseFont() async {
  if (!Platform.isLinux) return false;

  final snapRoot = Platform.environment['SNAP'];
  if (snapRoot == null) return false;

  final font = File(
    '$snapRoot/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf',
  );
  if (!await font.exists()) return false;

  try {
    final bytes = await font.readAsBytes();
    final loader = FontLoader(snapChineseFontFamily);
    loader.addFont(
      Future.value(
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes),
      ),
    );
    await loader.load();
    return true;
  } on Object catch (error) {
    debugPrint('Unable to load the Snap Chinese font: $error');
    return false;
  }
}
