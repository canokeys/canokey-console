import 'package:canokey_console/helper/widgets/constant.dart';
import 'package:canokey_console/helper/widgets/customized_text_style.dart';
import 'package:canokey_console/helper/widgets/screen_media.dart';
import 'package:flutter/material.dart';

class Widgets {
  // entry point of the package
  init() {}

  static void changeFontFamily(GoogleFontFunction fontFamily) {
    CustomizedTextStyle.changeFontFamily(fontFamily);
  }

  static void changeDefaultFontWeight(Map<int, FontWeight> defaultFontWeight) {
    CustomizedTextStyle.changeDefaultFontWeight(defaultFontWeight);
  }

  static void changeDefaultTextFontWeight(Map<TextType, int> defaultFontWeight) {
    CustomizedTextStyle.changeDefaultTextFontWeight(defaultFontWeight);
  }

  static void changeDefaultTextSize(Map<TextType, double> defaultTextSize) {
    CustomizedTextStyle.changeDefaultTextSize(defaultTextSize);
  }

  static void changeDefaultLetterSpacing(Map<TextType, double> defaultLetterSpacing) {
    CustomizedTextStyle.changeDefaultLetterSpacing(defaultLetterSpacing);
  }

  static setConstant(WidgetConstantData constantData) {
    WidgetConstant.setConstant(constantData);
  }

  static setFlexSpacing(double spacing) {
    ScreenMedia.flexSpacing = spacing;
  }

  static setFlexColumns(int columns) {
    ScreenMedia.flexColumns = columns;
  }
}
