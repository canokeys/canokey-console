import 'dart:io';
import 'dart:math';

import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/widgets/my.dart';
import 'package:canokey_console/helper/widgets/my_constant.dart';
import 'package:canokey_console/helper/widgets/my_text_style.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MaterialRadius {
  double xs, small, medium, large;

  MaterialRadius({this.xs = 2, this.small = 4, this.medium = 6, this.large = 8});
}

class ColorGroup {
  final Color color, onColor;

  ColorGroup(this.color, this.onColor);
}

class AppStyle {
  static void init() {
    initMyStyle();
    AdminTheme.setTheme();
  }

  static void initMyStyle() {
    MyTextStyle.resetFontStyles();
    MyTextStyle.changeFontFamily(GoogleFonts.poppins);
    My.setConstant(MyConstantData(
      containerRadius: AppStyle.containerRadius.medium,
      cardRadius: AppStyle.cardRadius.medium,
      buttonRadius: AppStyle.buttonRadius.medium,
    ));
    bool isMobile = true;
    try {
      isMobile = Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      isMobile = false;
    }
    My.setFlexSpacing(isMobile ? 16 : 24);
  }

  /// -------------------------- Styles  -------------------------------------------- ///

  static MaterialRadius buttonRadius = MaterialRadius(small: 2, medium: 4, large: 8);
  static MaterialRadius cardRadius = MaterialRadius(xs: 2, small: 4, medium: 4, large: 8);
  static MaterialRadius containerRadius = MaterialRadius(xs: 2, small: 4, medium: 4, large: 8);
  static MaterialRadius imageRadius = MaterialRadius(xs: 2, small: 4, medium: 4, large: 8);
}

class AppColors {
  static final Color star = Color(0xffFFC233);
  static Color ratingStarColor = Color(0xFFF9A825);
  static Color success = Color(0xff1abc9c);

  static ColorGroup pink = ColorGroup(Color(0xffFFC2D9), Color(0xffF5005E));
  static ColorGroup violet = ColorGroup(Color(0xffD0BADE), Color(0xff4E2E60));

  static ColorGroup blue = ColorGroup(Color(0xffADD8FF), Color(0xff004A8F));
  static ColorGroup green = ColorGroup(Color(0xffAFE9DA), Color(0xff165041));
  static ColorGroup orange = ColorGroup(Color(0xffFFCEC2), Color(0xffFF3B0A));
  static ColorGroup skyBlue = ColorGroup(Color(0xffC2F0FF), Color(0xff0099CC));
  static ColorGroup lavender = ColorGroup(Color(0xffEAE2F3), Color(0xff7748AD));
  static ColorGroup queenPink = ColorGroup(Color(0xffE8D9DC), Color(0xff804D57));
  static ColorGroup blueViolet = ColorGroup(Color(0xffC5C6E7), Color(0xff3B3E91));
  static ColorGroup rosePink = ColorGroup(Color(0xffFCB1E0), Color(0xffEC0999));

  static ColorGroup rubinRed = ColorGroup(Color(0x98f6a8bd), Color(0xffd03760));
  static ColorGroup favorite = rubinRed;
  static ColorGroup redOrange = ColorGroup(Color(0xffFFAD99), Color(0xffF53100));

  static Color notificationSuccessBGColor = Color(0xff117E68);
  static Color notificationSuccessTextColor = Color(0xffffffff);
  static Color notificationSuccessActionColor = Color(0xffFFE815);

  static Color notificationErrorBGColor = Color(0xfffcd9df);
  static Color notificationErrorTextColor = Color(0xffFF3B0A);
  static Color notificationErrorActionColor = Color(0xff3874ff);

  // static Color notificationErrorActionColor = Color(0xff006784);

  static List<ColorGroup> list = [redOrange, violet, blue, green, orange, skyBlue, lavender, blueViolet];

  static ColorGroup get random => list[Random().nextInt(list.length)];

  static ColorGroup get(int index) {
    return list[index % list.length];
  }

  static Color getColorByRating(int rating) {
    var colors = {1: Color(0xfff0323c), 2: Color(0xcdf0323c), 3: star, 4: Color(0xcd3cd278), 5: Color(0xff3cd278)};

    return colors[rating] ?? colors[1]!;
  }

  AppColors() {
    list.addAll([pink, violet, blue, green, orange]);
  }
}
