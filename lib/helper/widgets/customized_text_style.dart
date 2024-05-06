// ignore_for_file: prefer_generic_function_type_aliases

import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum TextType {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
}

// TextStyle
typedef TextStyle GoogleFontFunction({
  TextStyle? textStyle,
  Color? color,
  Color? backgroundColor,
  double? fontSize,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  double? letterSpacing,
  double? wordSpacing,
  TextBaseline? textBaseline,
  double? height,
  Locale? locale,
  Paint? foreground,
  Paint? background,
  List<Shadow>? shadows,
  List<FontFeature>? fontFeatures,
  TextDecoration? decoration,
  Color? decorationColor,
  TextDecorationStyle? decorationStyle,
  double? decorationThickness,
});

class CustomizedTextStyle {
  static GoogleFontFunction _fontFamily = GoogleFonts.ibmPlexSans;

  static changeFontFamily(GoogleFontFunction value) {
    _fontFamily = value;
  }

  static Map<int, FontWeight> _defaultFontWeight = {};

  static Map<TextType, double> _defaultTextSize = {
    TextType.displayLarge: 57,
    TextType.displayMedium: 45,
    TextType.displaySmall: 36,
    TextType.headlineLarge: 32,
    TextType.headlineMedium: 28,
    TextType.headlineSmall: 26,
    TextType.titleLarge: 22,
    TextType.titleMedium: 16,
    TextType.titleSmall: 14,
    TextType.labelLarge: 14,
    TextType.labelMedium: 12,
    TextType.labelSmall: 11,
    TextType.bodyLarge: 16,
    TextType.bodyMedium: 14,
    TextType.bodySmall: 12,
  };

  static Map<TextType, int> _defaultTextFontWeight = {};

  static Map<TextType, double> _defaultLetterSpacing = {};

  static TextStyle getStyle(
      {TextStyle? textStyle,
      int? fontWeight = 500,
      bool muted = false,
      bool xMuted = false,
      double? letterSpacing,
      Color? color,
      TextDecoration decoration = TextDecoration.none,
      double? height,
      double? wordSpacing,
      double? fontSize}) {
    double? finalFontSize = fontSize ?? (textStyle == null ? 40 : textStyle.fontSize);

    Color finalColor = color ?? theme.colorScheme.onBackground;
    finalColor = xMuted ? finalColor.withAlpha(160) : (muted ? finalColor.withAlpha(200) : finalColor);

    return _fontFamily(
        fontSize: finalFontSize,
        fontWeight: _defaultFontWeight[fontWeight],
        letterSpacing: letterSpacing,
        color: finalColor,
        decoration: decoration,
        height: height,
        wordSpacing: wordSpacing);
  }

  // Material Design 3
  static TextStyle displayLarge(
      {TextStyle? textStyle,
      int fontWeight = 500,
      bool muted = false,
      bool xMuted = false,
      double? letterSpacing,
      Color? color,
      TextDecoration decoration = TextDecoration.none,
      double? height,
      double? wordSpacing,
      double? fontSize}) {
    return getStyle(
        fontSize: fontSize ?? _defaultTextSize[TextType.displayLarge],
        color: color,
        height: height,
        muted: muted,
        letterSpacing: letterSpacing ?? _defaultLetterSpacing[TextType.displayLarge],
        fontWeight: _defaultTextFontWeight[TextType.displayLarge],
        decoration: decoration,
        textStyle: textStyle,
        wordSpacing: wordSpacing,
        xMuted: xMuted);
  }

  static TextStyle displayMedium(
      {TextStyle? textStyle,
      int fontWeight = 500,
      bool muted = false,
      bool xMuted = false,
      double? letterSpacing,
      Color? color,
      TextDecoration decoration = TextDecoration.none,
      double? height,
      double? wordSpacing,
      double? fontSize}) {
    return getStyle(
        fontSize: fontSize ?? _defaultTextSize[TextType.displayMedium],
        color: color,
        height: height,
        muted: muted,
        letterSpacing: letterSpacing ?? _defaultLetterSpacing[TextType.displayMedium],
        fontWeight: _defaultTextFontWeight[TextType.displayMedium],
        decoration: decoration,
        textStyle: textStyle,
        wordSpacing: wordSpacing,
        xMuted: xMuted);
  }

  static TextStyle displaySmall(
      {TextStyle? textStyle,
      int fontWeight = 500,
      bool muted = false,
      bool xMuted = false,
      double? letterSpacing,
      Color? color,
      TextDecoration decoration = TextDecoration.none,
      double? height,
      double? wordSpacing,
      double? fontSize}) {
    return getStyle(
        fontSize: fontSize ?? _defaultTextSize[TextType.displaySmall],
        color: color,
        height: height,
        muted: muted,
        letterSpacing: letterSpacing ?? _defaultLetterSpacing[TextType.displaySmall],
        fontWeight: _defaultTextFontWeight[TextType.displaySmall],
        decoration: decoration,
        textStyle: textStyle,
        wordSpacing: wordSpacing,
        xMuted: xMuted);
  }

  static TextStyle headlineLarge(
      {TextStyle? textStyle,
      int fontWeight = 500,
      bool muted = false,
      bool xMuted = false,
      double? letterSpacing,
      Color? color,
      TextDecoration decoration = TextDecoration.none,
      double? height,
      double? wordSpacing,
      double? fontSize}) {
    return getStyle(
        fontSize: fontSize ?? _defaultTextSize[TextType.headlineLarge],
        color: color,
        height: height,
        muted: muted,
        letterSpacing: letterSpacing ?? _defaultLetterSpacing[TextType.headlineLarge],
        fontWeight: _defaultTextFontWeight[TextType.headlineLarge],
        decoration: decoration,
        textStyle: textStyle,
        wordSpacing: wordSpacing,
        xMuted: xMuted);
  }

  static TextStyle headlineMedium(
      {TextStyle? textStyle,
      int fontWeight = 500,
      bool muted = false,
      bool xMuted = false,
      double? letterSpacing,
      Color? color,
      TextDecoration decoration = TextDecoration.none,
      double? height,
      double? wordSpacing,
      double? fontSize}) {
    return getStyle(
        fontSize: fontSize ?? _defaultTextSize[TextType.headlineMedium],
        color: color,
        height: height,
        muted: muted,
        letterSpacing: letterSpacing ?? _defaultLetterSpacing[TextType.headlineMedium],
        fontWeight: _defaultTextFontWeight[TextType.headlineMedium],
        decoration: decoration,
        textStyle: textStyle,
        wordSpacing: wordSpacing,
        xMuted: xMuted);
  }

  static TextStyle headlineSmall(
      {TextStyle? textStyle,
      int fontWeight = 500,
      bool muted = false,
      bool xMuted = false,
      double? letterSpacing,
      Color? color,
      TextDecoration decoration = TextDecoration.none,
      double? height,
      double? wordSpacing,
      double? fontSize}) {
    return getStyle(
        fontSize: fontSize ?? _defaultTextSize[TextType.headlineSmall],
        color: color,
        height: height,
        muted: muted,
        letterSpacing: letterSpacing ?? _defaultLetterSpacing[TextType.headlineSmall],
        fontWeight: _defaultTextFontWeight[TextType.headlineSmall],
        decoration: decoration,
        textStyle: textStyle,
        wordSpacing: wordSpacing,
        xMuted: xMuted);
  }

  static TextStyle titleLarge(
      {TextStyle? textStyle,
      int fontWeight = 500,
      bool muted = false,
      bool xMuted = false,
      double? letterSpacing,
      Color? color,
      TextDecoration decoration = TextDecoration.none,
      double? height,
      double? wordSpacing,
      double? fontSize}) {
    return getStyle(
        fontSize: fontSize ?? _defaultTextSize[TextType.titleLarge],
        color: color,
        height: height,
        muted: muted,
        letterSpacing: letterSpacing ?? _defaultLetterSpacing[TextType.titleLarge],
        fontWeight: _defaultTextFontWeight[TextType.titleLarge],
        decoration: decoration,
        textStyle: textStyle,
        wordSpacing: wordSpacing,
        xMuted: xMuted);
  }

  static TextStyle titleMedium(
      {TextStyle? textStyle,
      int fontWeight = 500,
      bool muted = false,
      bool xMuted = false,
      double? letterSpacing,
      Color? color,
      TextDecoration decoration = TextDecoration.none,
      double? height,
      double? wordSpacing,
      double? fontSize}) {
    return getStyle(
        fontSize: fontSize ?? _defaultTextSize[TextType.titleMedium],
        color: color,
        height: height,
        muted: muted,
        letterSpacing: letterSpacing ?? _defaultLetterSpacing[TextType.titleMedium],
        fontWeight: _defaultTextFontWeight[TextType.titleMedium],
        decoration: decoration,
        textStyle: textStyle,
        wordSpacing: wordSpacing,
        xMuted: xMuted);
  }

  static TextStyle titleSmall(
      {TextStyle? textStyle,
      int fontWeight = 500,
      bool muted = false,
      bool xMuted = false,
      double? letterSpacing,
      Color? color,
      TextDecoration decoration = TextDecoration.none,
      double? height,
      double? wordSpacing,
      double? fontSize}) {
    return getStyle(
        fontSize: fontSize ?? _defaultTextSize[TextType.titleSmall],
        color: color,
        height: height,
        muted: muted,
        letterSpacing: letterSpacing ?? _defaultLetterSpacing[TextType.titleSmall],
        fontWeight: _defaultTextFontWeight[TextType.titleSmall],
        decoration: decoration,
        textStyle: textStyle,
        wordSpacing: wordSpacing,
        xMuted: xMuted);
  }

  static TextStyle labelLarge(
      {TextStyle? textStyle,
      int fontWeight = 500,
      bool muted = false,
      bool xMuted = false,
      double? letterSpacing,
      Color? color,
      TextDecoration decoration = TextDecoration.none,
      double? height,
      double? wordSpacing,
      double? fontSize}) {
    return getStyle(
        fontSize: fontSize ?? _defaultTextSize[TextType.labelLarge],
        color: color,
        height: height,
        muted: muted,
        letterSpacing: letterSpacing ?? _defaultLetterSpacing[TextType.labelLarge],
        fontWeight: _defaultTextFontWeight[TextType.labelLarge],
        decoration: decoration,
        textStyle: textStyle,
        wordSpacing: wordSpacing,
        xMuted: xMuted);
  }

  static TextStyle labelMedium(
      {TextStyle? textStyle,
      int fontWeight = 500,
      bool muted = false,
      bool xMuted = false,
      double? letterSpacing,
      Color? color,
      TextDecoration decoration = TextDecoration.none,
      double? height,
      double? wordSpacing,
      double? fontSize}) {
    return getStyle(
        fontSize: fontSize ?? _defaultTextSize[TextType.labelMedium],
        color: color,
        height: height,
        muted: muted,
        letterSpacing: letterSpacing ?? _defaultLetterSpacing[TextType.labelMedium],
        fontWeight: _defaultTextFontWeight[TextType.labelMedium],
        decoration: decoration,
        textStyle: textStyle,
        wordSpacing: wordSpacing,
        xMuted: xMuted);
  }

  static TextStyle labelSmall(
      {TextStyle? textStyle,
      int fontWeight = 500,
      bool muted = false,
      bool xMuted = false,
      double? letterSpacing,
      Color? color,
      TextDecoration decoration = TextDecoration.none,
      double? height,
      double? wordSpacing,
      double? fontSize}) {
    return getStyle(
        fontSize: fontSize ?? _defaultTextSize[TextType.labelSmall],
        color: color,
        height: height,
        muted: muted,
        letterSpacing: letterSpacing ?? _defaultLetterSpacing[TextType.labelSmall],
        fontWeight: _defaultTextFontWeight[TextType.labelSmall],
        decoration: decoration,
        textStyle: textStyle,
        wordSpacing: wordSpacing,
        xMuted: xMuted);
  }

  static TextStyle bodyLarge(
      {TextStyle? textStyle,
      int? fontWeight,
      bool muted = false,
      bool xMuted = false,
      double? letterSpacing,
      Color? color,
      TextDecoration decoration = TextDecoration.none,
      double? height,
      double? wordSpacing,
      double? fontSize}) {
    return getStyle(
        fontSize: fontSize ?? _defaultTextSize[TextType.bodyLarge],
        color: color,
        height: height,
        muted: muted,
        letterSpacing: letterSpacing ?? _defaultLetterSpacing[TextType.bodyLarge],
        fontWeight: fontWeight ?? _defaultTextFontWeight[TextType.bodyLarge],
        decoration: decoration,
        textStyle: textStyle,
        wordSpacing: wordSpacing,
        xMuted: xMuted);
  }

  static TextStyle bodyMedium(
      {TextStyle? textStyle,
      int fontWeight = 500,
      bool muted = false,
      bool xMuted = false,
      double? letterSpacing,
      Color? color,
      TextDecoration decoration = TextDecoration.none,
      double? height,
      double? wordSpacing,
      double? fontSize}) {
    return getStyle(
        fontSize: fontSize ?? _defaultTextSize[TextType.bodyMedium],
        color: color,
        height: height,
        muted: muted,
        letterSpacing: letterSpacing ?? _defaultLetterSpacing[TextType.bodyMedium],
        fontWeight: _defaultTextFontWeight[TextType.bodyMedium],
        decoration: decoration,
        textStyle: textStyle,
        wordSpacing: wordSpacing,
        xMuted: xMuted);
  }

  static TextStyle bodySmall(
      {TextStyle? textStyle,
      int fontWeight = 500,
      bool muted = false,
      bool xMuted = false,
      double? letterSpacing,
      Color? color,
      TextDecoration decoration = TextDecoration.none,
      double? height,
      double? wordSpacing,
      double? fontSize}) {
    return getStyle(
        fontSize: fontSize ?? _defaultTextSize[TextType.bodySmall],
        color: color,
        height: height,
        muted: muted,
        letterSpacing: letterSpacing ?? _defaultLetterSpacing[TextType.bodySmall],
        fontWeight: _defaultTextFontWeight[TextType.bodySmall],
        decoration: decoration,
        textStyle: textStyle,
        wordSpacing: wordSpacing,
        xMuted: xMuted);
  }

  static void changeDefaultFontWeight(Map<int, FontWeight> defaultFontWeight) {
    CustomizedTextStyle._defaultFontWeight = defaultFontWeight;
  }

  static void changeDefaultTextFontWeight(Map<TextType, int> defaultFontWeight) {
    CustomizedTextStyle._defaultTextFontWeight = defaultFontWeight;
  }

  static void changeDefaultTextSize(Map<TextType, double> defaultTextSize) {
    CustomizedTextStyle._defaultTextSize = defaultTextSize;
  }

  static void changeDefaultLetterSpacing(Map<TextType, double> defaultLetterSpacing) {
    CustomizedTextStyle._defaultLetterSpacing = defaultLetterSpacing;
  }

  static Map<TextType, double> get defaultTextSize => _defaultTextSize;

  static Map<TextType, double> get defaultLetterSpacing => _defaultLetterSpacing;

  static Map<TextType, int> get defaultTextFontWeight => _defaultTextFontWeight;

  static Map<int, FontWeight> get defaultFontWeight => _defaultFontWeight;

  //-------------------Reset Font Styles---------------------------------
  static resetFontStyles() {
    _fontFamily = GoogleFonts.ibmPlexSans;

    _defaultFontWeight = {
      100: FontWeight.w100,
      200: FontWeight.w200,
      300: FontWeight.w300,
      400: FontWeight.w300,
      500: FontWeight.w400,
      600: FontWeight.w500,
      700: FontWeight.w600,
      800: FontWeight.w700,
      900: FontWeight.w800,
    };

    _defaultTextSize = {
      TextType.displayLarge: 57,
      TextType.displayMedium: 45,
      TextType.displaySmall: 36,
      TextType.headlineLarge: 32,
      TextType.headlineMedium: 28,
      TextType.headlineSmall: 26,
      TextType.titleLarge: 22,
      TextType.titleMedium: 16,
      TextType.titleSmall: 14,
      TextType.labelLarge: 14,
      TextType.labelMedium: 12,
      TextType.labelSmall: 11,
      TextType.bodyLarge: 16,
      TextType.bodyMedium: 14,
      TextType.bodySmall: 12,
    };

    _defaultTextFontWeight = {
      TextType.displayLarge: 500,
      TextType.displayMedium: 500,
      TextType.displaySmall: 500,
      TextType.headlineLarge: 500,
      TextType.headlineMedium: 500,
      TextType.headlineSmall: 500,
      TextType.titleLarge: 500,
      TextType.titleMedium: 500,
      TextType.titleSmall: 500,
      TextType.labelLarge: 600,
      TextType.labelMedium: 600,
      TextType.labelSmall: 600,
      TextType.bodyLarge: 500,
      TextType.bodyMedium: 500,
      TextType.bodySmall: 500,
    };

    _defaultLetterSpacing = {
      TextType.displayLarge: -0.25,
      TextType.displayMedium: 0,
      TextType.displaySmall: 0,
      TextType.headlineLarge: -0.2,
      TextType.headlineMedium: -0.15,
      TextType.headlineSmall: 0,
      TextType.titleLarge: 0,
      TextType.titleMedium: 0.1,
      TextType.titleSmall: 0.1,
      TextType.labelLarge: 0.1,
      TextType.labelMedium: 0.5,
      TextType.labelSmall: 0.5,
      TextType.bodyLarge: 0.5,
      TextType.bodyMedium: 0.25,
      TextType.bodySmall: 0.4,
    };
  }
}
