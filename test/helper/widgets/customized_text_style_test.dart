import 'package:canokey_console/helper/theme/app_fonts.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/widgets/customized_text_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('prefers CJK-capable Linux fonts for Chinese text', () {
    AppTheme.init();

    final fallback = CustomizedTextStyle.bodyMedium().fontFamilyFallback;

    expect(fallback!.first, snapChineseFontFamily);
    expect(fallback, contains('Noto Sans CJK SC'));
    expect(fallback, contains('Droid Sans Fallback'));
    expect(
      fallback.indexOf('Noto Sans CJK SC'),
      lessThan(fallback.indexOf('sans-serif')),
    );
    expect(
      AppTheme.lightTheme.textTheme.bodyMedium!.fontFamilyFallback,
      CustomizedTextStyle.cjkFontFallback,
    );
    expect(
      AppTheme.darkTheme.textTheme.bodyMedium!.fontFamilyFallback,
      CustomizedTextStyle.cjkFontFallback,
    );
  });
}
