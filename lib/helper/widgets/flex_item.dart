import 'package:flutter/material.dart';
import 'package:canokey_console/helper/widgets/display_type.dart';
import 'package:canokey_console/helper/widgets/screen_media.dart';
import 'package:canokey_console/helper/widgets/screen_media_type.dart';

class MyFlexItem extends StatelessWidget {
  final Widget child;
  final String? sizes;
  final String? displays;

  Map<ScreenMediaType, int> get flex =>
      ScreenMedia.getFlexedDataFromString(sizes);
  Map<ScreenMediaType, DisplayType> get display =>
      ScreenMedia.getDisplayDataFromString(displays);

  MyFlexItem({
    super.key,
    required this.child,
    this.sizes,
    this.displays,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
