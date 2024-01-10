import 'package:canokey_console/helper/widgets/responsive.dart';

class MyScreenMedia {
  static int flexColumns = 12;
  static double flexSpacing = 24;

  static MyScreenMediaType getTypeFromWidth(double width) {
    for (var i in MyScreenMediaType.values) {
      if (width < i.width) {
        return i;
      }
    }
    return MyScreenMediaType.xxl;
  }

  static Map<MyScreenMediaType, T> getFilledMedia<T>(
      Map<MyScreenMediaType, T>? map, T defaultValue,
      [bool reversed = false]) {
    Map<MyScreenMediaType, T> d = {};
    map ??= {};
    List list = MyScreenMediaType.list;
    if (reversed) {
      list = list.reversed.toList();
    }
    for (var i = 0; i < list.length; i++) {
      d[list[i]] =
          map[list[i]] ?? (i > 0 ? d[list[i - 1]] : null) ?? defaultValue;
    }
    return d;
  }

  static Map<MyScreenMediaType, int> getFlexedDataFromString(String? string) {
    string ??= "";
    Map<MyScreenMediaType, int> d = {};

    List<String> data = string.split(" ");
    for (String item in data) {
      for (var type in MyScreenMediaType.values) {
        if (item.contains(type.className)) {
          int? flex = int.tryParse(item.replaceAll("${type.className}-", ""));
          if (flex != null) {
            d[type] = flex;
            break;
          }
        }
      }
    }

    return getFilledMedia(d, MyScreenMedia.flexColumns);
  }

  static Map<MyScreenMediaType, MyDisplayType> getDisplayDataFromString(
      String? string) {
    string ??= "";
    Map<MyScreenMediaType, MyDisplayType> d = {};

    List<String> data = string.split(" ");
    for (String item in data) {
      for (var type in MyScreenMediaType.values) {
        if (item.contains(type.className)) {
          MyDisplayType displayType = MyDisplayType.fromString(
              item.replaceAll("${type.className}-", ""));
          d[type] = displayType;
          break;
        }
      }
    }

    return getFilledMedia(d, MyDisplayType.block);
  }
}
