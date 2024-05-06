import 'package:canokey_console/helper/widgets/screen_media.dart';
import 'package:canokey_console/helper/widgets/screen_media_type.dart';
import 'package:flutter/material.dart';

export 'display_type.dart';
export 'screen_media.dart';
export 'screen_media_type.dart';

double get flexSpacing => ScreenMedia.flexSpacing;

int get flexColumns => ScreenMedia.flexColumns;

class Responsive extends StatelessWidget {
  final Widget Function(BuildContext, BoxConstraints, ScreenMediaType) builder;

  const Responsive({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) =>
            builder(context, constraints, ScreenMedia.getTypeFromWidth(MediaQuery.of(context).size.width)));
  }
}
