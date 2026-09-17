import 'package:canokey_console/helper/widgets/screen_media_type.dart';

class ScreenMedia {
  static double flexSpacing = 24;

  static ScreenMediaType getTypeFromWidth(double width) {
    for (var i in ScreenMediaType.values) {
      if (width < i.width) {
        return i;
      }
    }
    return ScreenMediaType.xxl;
  }
}
