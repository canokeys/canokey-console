import 'package:canokey_console/helper/theme/theme_type.dart';
import 'package:canokey_console/helper/widgets/my_text_style.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData get theme => AppTheme.theme;

class AppTheme {
  static ThemeType themeType = ThemeType.light;
  static ThemeData theme = getTheme();

  AppTheme._();

  static init() {
    initTextStyle();
  }

  static initTextStyle() {
    MyTextStyle.changeFontFamily(GoogleFonts.ibmPlexSans);
    MyTextStyle.changeDefaultFontWeight({
      100: FontWeight.w100,
      200: FontWeight.w200,
      300: FontWeight.w300,
      400: FontWeight.w300,
      500: FontWeight.w400,
      600: FontWeight.w500,
      700: FontWeight.w600,
      800: FontWeight.w700,
      900: FontWeight.w800,
    });

    MyTextStyle.changeDefaultTextFontWeight({
      MyTextType.displayLarge: 500,
      MyTextType.displayMedium: 500,
      MyTextType.displaySmall: 500,
      MyTextType.headlineLarge: 500,
      MyTextType.headlineMedium: 500,
      MyTextType.headlineSmall: 500,
      MyTextType.titleLarge: 500,
      MyTextType.titleMedium: 500,
      MyTextType.titleSmall: 500,
      MyTextType.labelLarge: 500,
      MyTextType.labelMedium: 500,
      MyTextType.labelSmall: 500,
      MyTextType.bodyLarge: 500,
      MyTextType.bodyMedium: 500,
      MyTextType.bodySmall: 500,
    });
  }

  static ThemeData getTheme([ThemeType? themeType]) {
    themeType = themeType ?? AppTheme.themeType;
    if (themeType == ThemeType.light) return lightTheme;
    return darkTheme;
  }

  /// -------------------------- Light Theme  -------------------------------------------- ///
  static final ThemeData lightTheme = ThemeData(
    /// Brightness
    brightness: Brightness.light,

    /// Primary Color
    primaryColor: Color(0xff009678),
    scaffoldBackgroundColor: Color(0xfff0f0f0),
    canvasColor: Colors.transparent,

    /// AppBar Theme
    appBarTheme: AppBarTheme(
        backgroundColor: Color(0xffffffff),
        iconTheme: IconThemeData(color: Color(0xff495057)),
        actionsIconTheme: IconThemeData(color: Color(0xff495057))),

    /// Card Theme
    cardTheme: CardTheme(color: Color(0xffffffff)),
    cardColor: Color(0xffffffff),

    textTheme: TextTheme(
        titleLarge: GoogleFonts.aBeeZee(), bodyLarge: GoogleFonts.abel()),

    /// Floating Action Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(0xff009678),
        splashColor: Color(0xffeeeeee).withAlpha(100),
        highlightElevation: 8,
        elevation: 4,
        focusColor: Color(0xff009678),
        hoverColor: Color(0xff009678),
        foregroundColor: Color(0xffeeeeee)),

    /// Divider Theme
    dividerTheme: DividerThemeData(color: Color(0xffe8e8e8), thickness: 1),
    dividerColor: Color(0xffe8e8e8),

    /// Bottom AppBar Theme
    bottomAppBarTheme:
        BottomAppBarTheme(color: Color(0xffeeeeee), elevation: 2),

    /// Tab bar Theme
    tabBarTheme: TabBarTheme(
      unselectedLabelColor: Color(0xff495057),
      labelColor: Color(0xff009678),
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: Color(0xff009678), width: 2.0),
      ),
    ),

    /// CheckBox theme
    checkboxTheme: CheckboxThemeData(
      checkColor: MaterialStateProperty.all(Color(0xffeeeeee)),
      fillColor: MaterialStateProperty.all(Color(0xff009678)),
    ),

    /// Radio theme
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.all(Color(0xff009678)),
    ),

    ///Switch Theme
    switchTheme: SwitchThemeData(
      trackColor: MaterialStateProperty.resolveWith((state) {
        const Set<MaterialState> interactiveStates = <MaterialState>{
          MaterialState.pressed,
          MaterialState.hovered,
          MaterialState.focused,
          MaterialState.selected,
        };
        if (state.any(interactiveStates.contains)) {
          return Color(0xffabb3ea);
        }
        return null;
      }),
      thumbColor: MaterialStateProperty.resolveWith((state) {
        const Set<MaterialState> interactiveStates = <MaterialState>{
          MaterialState.pressed,
          MaterialState.hovered,
          MaterialState.focused,
          MaterialState.selected,
        };
        if (state.any(interactiveStates.contains)) {
          return Color(0xff009678);
        }
        return null;
      }),
    ),

    /// Slider Theme
    sliderTheme: SliderThemeData(
      activeTrackColor: Color(0xff009678),
      inactiveTrackColor: Color(0xff009678).withAlpha(140),
      trackShape: RoundedRectSliderTrackShape(),
      trackHeight: 4.0,
      thumbColor: Color(0xff009678),
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.0),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 24.0),
      tickMarkShape: RoundSliderTickMarkShape(),
      inactiveTickMarkColor: Colors.red[100],
      valueIndicatorShape: PaddleSliderValueIndicatorShape(),
      valueIndicatorTextStyle: TextStyle(
        color: Color(0xffeeeeee),
      ),
    ),

    /// Other Colors
    splashColor: Colors.white.withAlpha(100),
    indicatorColor: Color(0xffeeeeee),
    highlightColor: Color(0xffeeeeee),
    colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xff009678),
            brightness: Brightness.light,
            surfaceTint: Colors.transparent)
        .copyWith(background: Color(0xffffffff))
        .copyWith(error: Color(0xfff0323c)),
  );

  /// -------------------------- Dark Theme  -------------------------------------------- ///
  static final ThemeData darkTheme = ThemeData(
    /// Brightness
    brightness: Brightness.dark,

    /// Primary Color
    primaryColor: Color(0xff009678),

    /// Scaffold and Background color
    scaffoldBackgroundColor: Color(0xff161616),
    canvasColor: Colors.transparent,

    /// AppBar Theme
    appBarTheme: AppBarTheme(backgroundColor: Color(0xff161616)),

    /// Card Theme
    cardTheme: CardTheme(color: Color(0xff222327)),
    cardColor: Color(0xff222327),

    /// Input (Text-Field) Theme
    inputDecorationTheme: InputDecorationTheme(
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(width: 1, color: Color(0xff009678)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(width: 1, color: Colors.white70),
      ),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(width: 1, color: Colors.white70)),
    ),

    /// Divider Color
    dividerTheme: DividerThemeData(color: Color(0xff363636), thickness: 1),
    dividerColor: Color(0xff363636),

    /// Floating Action Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(0xff009678),
        splashColor: Colors.white.withAlpha(100),
        highlightElevation: 8,
        elevation: 4,
        focusColor: Color(0xff009678),
        hoverColor: Color(0xff009678),
        foregroundColor: Colors.white),

    /// Bottom AppBar Theme
    bottomAppBarTheme:
        BottomAppBarTheme(color: Color(0xff464c52), elevation: 2),

    /// Tab bar Theme
    tabBarTheme: TabBarTheme(
      unselectedLabelColor: Color(0xff495057),
      labelColor: Color(0xff009678),
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: Color(0xff009678), width: 2.0),
      ),
    ),

    ///Switch Theme
    switchTheme: SwitchThemeData(
      trackColor: MaterialStateProperty.resolveWith((state) {
        const Set<MaterialState> interactiveStates = <MaterialState>{
          MaterialState.pressed,
          MaterialState.hovered,
          MaterialState.focused,
          MaterialState.selected,
        };
        if (state.any(interactiveStates.contains)) {
          return Color(0xffabb3ea);
        }
        return null;
      }),
      thumbColor: MaterialStateProperty.resolveWith((state) {
        const Set<MaterialState> interactiveStates = <MaterialState>{
          MaterialState.pressed,
          MaterialState.hovered,
          MaterialState.focused,
          MaterialState.selected,
        };
        if (state.any(interactiveStates.contains)) {
          return Color(0xff009678);
        }
        return null;
      }),
    ),

    /// Slider Theme
    sliderTheme: SliderThemeData(
      activeTrackColor: Color(0xff009678),
      inactiveTrackColor: Color(0xff009678).withAlpha(100),
      trackShape: RoundedRectSliderTrackShape(),
      trackHeight: 4.0,
      thumbColor: Color(0xff009678),
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.0),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 24.0),
      tickMarkShape: RoundSliderTickMarkShape(),
      inactiveTickMarkColor: Colors.red[100],
      valueIndicatorShape: PaddleSliderValueIndicatorShape(),
      valueIndicatorTextStyle: TextStyle(
        color: Colors.white,
      ),
    ),

    ///Other Color
    indicatorColor: Colors.white,
    disabledColor: Color(0xffa3a3a3),
    highlightColor: Colors.white.withAlpha(28),
    splashColor: Colors.white.withAlpha(56),
    colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xff009678), brightness: Brightness.dark)
        .copyWith(background: Color(0xff161616))
        .copyWith(error: Colors.orange),
  );
}
