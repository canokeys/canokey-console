import 'package:canokey_console/helper/widgets/responsive.dart';

class ScreenMedia {
  static int flexColumns = 12;
  static double flexSpacing = 24;

  static ScreenMediaType getTypeFromWidth(double width) {
    for (var i in ScreenMediaType.values) {
      if (width < i.width) {
        return i;
      }
    }
    return ScreenMediaType.xxl;
  }

  static Map<ScreenMediaType, T> getFilledMedia<T>(Map<ScreenMediaType, T>? map, T defaultValue, [bool reversed = false]) {
    Map<ScreenMediaType, T> d = {};
    map ??= {};
    List list = ScreenMediaType.list;
    if (reversed) {
      list = list.reversed.toList();
    }
    for (var i = 0; i < list.length; i++) {
      d[list[i]] = map[list[i]] ?? (i > 0 ? d[list[i - 1]] : null) ?? defaultValue;
    }
    return d;
  }

  static Map<ScreenMediaType, int> getFlexedDataFromString(String? string) {
    string ??= "";
    Map<ScreenMediaType, int> d = {};

    List<String> data = string.split(" ");
    for (String item in data) {
      for (var type in ScreenMediaType.values) {
        if (item.contains(type.className)) {
          int? flex = int.tryParse(item.replaceAll("${type.className}-", ""));
          if (flex != null) {
            d[type] = flex;
            break;
          }
        }
      }
    }

    return getFilledMedia(d, ScreenMedia.flexColumns);
  }

  static Map<ScreenMediaType, DisplayType> getDisplayDataFromString(String? string) {
    string ??= "";
    Map<ScreenMediaType, DisplayType> d = {};

    List<String> data = string.split(" ");
    for (String item in data) {
      for (var type in ScreenMediaType.values) {
        if (item.contains(type.className)) {
          DisplayType displayType = DisplayType.fromString(item.replaceAll("${type.className}-", ""));
          d[type] = displayType;
          break;
        }
      }
    }

    return getFilledMedia(d, DisplayType.block);
  }
}
