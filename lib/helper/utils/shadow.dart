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
  ShadowPosition? position;
  Color? color;
  bool? darkShadow;

  Shadow(
      {this.elevation = 3,
      double? spreadRadius,
      double? blurRadius,
      Offset? offset,
      ShadowPosition position = ShadowPosition.bottom,
      int? alpha,
      Color? color,
      bool darkShadow = false}) {
    this.spreadRadius = spreadRadius ?? elevation * 0.125;
    this.blurRadius = blurRadius ?? elevation * 2;
    this.alpha = alpha ?? (darkShadow ? 80 : 25);
    this.offset = offset;
    this.position = position;
    this.color = color;
    this.darkShadow = darkShadow;

    if (offset == null) {
      switch (position) {
        case ShadowPosition.topLeft:
          this.offset = Offset(-elevation, -elevation);
          break;
        case ShadowPosition.top:
          this.offset = Offset(0, -elevation);
          break;
        case ShadowPosition.topRight:
          this.offset = Offset(elevation, -elevation);
          break;
        //TODO: Shadow problem
        case ShadowPosition.centerLeft:
          this.offset = Offset(-elevation, elevation * 0.25);
          break;
        case ShadowPosition.center:
          this.offset = Offset(0, 0);
          break;
        //TODO: Shadow problem
        case ShadowPosition.centerRight:
          this.offset = Offset(elevation, elevation * 0.25);
          break;
        case ShadowPosition.bottomLeft:
          this.offset = Offset(-elevation, elevation);
          break;
        case ShadowPosition.bottom:
          this.offset = Offset(0, elevation);
          break;
        case ShadowPosition.bottomRight:
          this.offset = Offset(elevation, elevation);
          break;
      }
    }
  }

  Shadow.none(
      {this.elevation = 0,
      double? spreadRadius,
      double? blurRadius,
      Offset? offset,
      ShadowPosition position = ShadowPosition.bottom,
      int? alpha,
      Color? color,
      bool darkShadow = false}) {
    this.spreadRadius = spreadRadius ?? elevation * 0.125;
    this.blurRadius = blurRadius ?? elevation * 2;
    this.alpha = alpha ?? (darkShadow ? 100 : 36);
    this.offset = offset;
    this.position = position;
    this.color = color;
    this.darkShadow = darkShadow;

    if (offset == null) {
      switch (position) {
        case ShadowPosition.topLeft:
          this.offset = Offset(-elevation, -elevation);
          break;
        case ShadowPosition.top:
          this.offset = Offset(0, -elevation);
          break;
        case ShadowPosition.topRight:
          this.offset = Offset(elevation, -elevation);
          break;
        //TODO: Shadow problem
        case ShadowPosition.centerLeft:
          this.offset = Offset(-elevation, elevation * 0.25);
          break;
        case ShadowPosition.center:
          this.offset = Offset(0, 0);
          break;
        //TODO: Shadow problem
        case ShadowPosition.centerRight:
          this.offset = Offset(elevation, elevation * 0.25);
          break;
        case ShadowPosition.bottomLeft:
          this.offset = Offset(-elevation, elevation);
          break;
        case ShadowPosition.bottom:
          this.offset = Offset(0, elevation);
          break;
        case ShadowPosition.bottomRight:
          this.offset = Offset(elevation, elevation);
          break;
      }
    }
  }

  @override
  String toString() {
    return 'MyShadow{alpha: $alpha, elevation: $elevation, spreadRadius: $spreadRadius, blurRadius: $blurRadius, offset: $offset, position: $position, color: $color, darkShadow: $darkShadow}';
  }
}
