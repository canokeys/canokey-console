import 'dart:io';

import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/widgets/constant.dart';
import 'package:canokey_console/helper/widgets/customized_text_style.dart';
import 'package:canokey_console/helper/widgets/screen_media.dart';
import 'package:google_fonts/google_fonts.dart';

class AppStyle {
  static void init() {
    CustomizedTextStyle.resetFontStyles();
    CustomizedTextStyle.changeFontFamily(GoogleFonts.poppins);
    WidgetConstant.setConstant(WidgetConstantData());
    var isMobile = false;
    try {
      isMobile = Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      // Platform queries are unavailable on web.
    }
    ScreenMedia.flexSpacing = isMobile ? 16 : 24;
    AdminTheme.setTheme();
  }
}
