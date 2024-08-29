import 'package:flutter/material.dart';

enum ShadowPosition {
  topLeft("Top Left"),
  top("Top"),
  topRight("Top Right"),
  centerLeft("Center Left"),
  center("Center"),
  centerRight("Center Right"),
  bottomLeft("Bottom Left"),
  bottom("Bottom"),
  bottomRight("Bottom Right");

  final String humanReadable;

  const ShadowPosition(this.humanReadable);
}

class Shadow {
  late int alpha;
  late double elevation, spreadRadius, blurRadius;
  Offset? offset;
  ShadowPosition position;
  Color? color;
  bool darkShadow;

  Shadow(
      {this.elevation = 3,
      double? spreadRadius,
      double? blurRadius,
      this.offset,
      this.position = ShadowPosition.bottom,
      int? alpha,
      this.color,
      this.darkShadow = false}) {
    this.spreadRadius = spreadRadius ?? elevation * 0.125;
    this.blurRadius = blurRadius ?? elevation * 2;
    this.alpha = alpha ?? (darkShadow ? 80 : 25);

    if (offset == null) {
      switch (position) {
        case ShadowPosition.topLeft:
          offset = Offset(-elevation, -elevation);
          break;
        case ShadowPosition.top:
          offset = Offset(0, -elevation);
          break;
        case ShadowPosition.topRight:
          offset = Offset(elevation, -elevation);
          break;
        //TODO: Shadow problem
        case ShadowPosition.centerLeft:
          offset = Offset(-elevation, elevation * 0.25);
          break;
        case ShadowPosition.center:
          offset = Offset(0, 0);
          break;
        //TODO: Shadow problem
        case ShadowPosition.centerRight:
          offset = Offset(elevation, elevation * 0.25);
          break;
        case ShadowPosition.bottomLeft:
          offset = Offset(-elevation, elevation);
          break;
        case ShadowPosition.bottom:
          offset = Offset(0, elevation);
          break;
        case ShadowPosition.bottomRight:
          offset = Offset(elevation, elevation);
          break;
      }
    }
  }

  Shadow.none(
      {this.elevation = 0,
      double? spreadRadius,
      double? blurRadius,
      this.offset,
      this.position = ShadowPosition.bottom,
      int? alpha,
      this.color,
      this.darkShadow = false}) {
    this.spreadRadius = spreadRadius ?? elevation * 0.125;
    this.blurRadius = blurRadius ?? elevation * 2;
    this.alpha = alpha ?? (darkShadow ? 100 : 36);

    if (offset == null) {
      switch (position) {
        case ShadowPosition.topLeft:
          offset = Offset(-elevation, -elevation);
          break;
        case ShadowPosition.top:
          offset = Offset(0, -elevation);
          break;
        case ShadowPosition.topRight:
          offset = Offset(elevation, -elevation);
          break;
        //TODO: Shadow problem
        case ShadowPosition.centerLeft:
          offset = Offset(-elevation, elevation * 0.25);
          break;
        case ShadowPosition.center:
          offset = Offset(0, 0);
          break;
        //TODO: Shadow problem
        case ShadowPosition.centerRight:
          offset = Offset(elevation, elevation * 0.25);
          break;
        case ShadowPosition.bottomLeft:
          offset = Offset(-elevation, elevation);
          break;
        case ShadowPosition.bottom:
          offset = Offset(0, elevation);
          break;
        case ShadowPosition.bottomRight:
          offset = Offset(elevation, elevation);
          break;
      }
    }
  }

  @override
  String toString() {
    return 'MyShadow{alpha: $alpha, elevation: $elevation, spreadRadius: $spreadRadius, blurRadius: $blurRadius, offset: $offset, position: $position, color: $color, darkShadow: $darkShadow}';
  }
}
