// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';

enum MyShadowPosition {
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

  const MyShadowPosition(this.humanReadable);
}

class MyShadow {
  late int alpha;
  late double elevation, spreadRadius, blurRadius;
  Offset? offset;
  MyShadowPosition? position;
  Color? color;
  bool? darkShadow;

  MyShadow(
      {this.elevation = 3,
      double? spreadRadius,
      double? blurRadius,
      Offset? offset,
      MyShadowPosition position = MyShadowPosition.bottom,
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
        case MyShadowPosition.topLeft:
          this.offset = Offset(-elevation, -elevation);
          break;
        case MyShadowPosition.top:
          this.offset = Offset(0, -elevation);
          break;
        case MyShadowPosition.topRight:
          this.offset = Offset(elevation, -elevation);
          break;
        //TODO: Shadow problem
        case MyShadowPosition.centerLeft:
          this.offset = Offset(-elevation, elevation * 0.25);
          break;
        case MyShadowPosition.center:
          this.offset = Offset(0, 0);
          break;
        //TODO: Shadow problem
        case MyShadowPosition.centerRight:
          this.offset = Offset(elevation, elevation * 0.25);
          break;
        case MyShadowPosition.bottomLeft:
          this.offset = Offset(-elevation, elevation);
          break;
        case MyShadowPosition.bottom:
          this.offset = Offset(0, elevation);
          break;
        case MyShadowPosition.bottomRight:
          this.offset = Offset(elevation, elevation);
          break;
      }
    }
  }

  MyShadow.none(
      {this.elevation = 0,
      double? spreadRadius,
      double? blurRadius,
      Offset? offset,
      MyShadowPosition position = MyShadowPosition.bottom,
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
        case MyShadowPosition.topLeft:
          this.offset = Offset(-elevation, -elevation);
          break;
        case MyShadowPosition.top:
          this.offset = Offset(0, -elevation);
          break;
        case MyShadowPosition.topRight:
          this.offset = Offset(elevation, -elevation);
          break;
        //TODO: Shadow problem
        case MyShadowPosition.centerLeft:
          this.offset = Offset(-elevation, elevation * 0.25);
          break;
        case MyShadowPosition.center:
          this.offset = Offset(0, 0);
          break;
        //TODO: Shadow problem
        case MyShadowPosition.centerRight:
          this.offset = Offset(elevation, elevation * 0.25);
          break;
        case MyShadowPosition.bottomLeft:
          this.offset = Offset(-elevation, elevation);
          break;
        case MyShadowPosition.bottom:
          this.offset = Offset(0, elevation);
          break;
        case MyShadowPosition.bottomRight:
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
