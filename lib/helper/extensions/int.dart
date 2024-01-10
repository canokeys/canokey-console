import 'package:flutter/material.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';

extension IntUtil on int {
  String textFromSeconds(
      {bool withZeros = false,
      bool withHours = false,
      bool withMinutes = false,
      bool withSeconds = false,
      bool withSpace = false}) {
    int time = this;
    int hour = (time / 3600).floor();
    int minute = ((time - 3600 * hour) / 60).floor();
    int second = (time - 3600 * hour - 60 * minute);

    String timeText = "";

    if (withHours && hour != 0) {
      if (hour < 10 && withZeros) {
        timeText += "0$hour${withSpace ? " : " : ":"}";
      } else {
        timeText += hour.toString() + (withSpace ? " : " : "");
      }
    }

    if (withMinutes) {
      if (minute < 10 && withZeros) {
        timeText += "0$minute${withSpace ? " : " : ":"}";
      } else {
        timeText += minute.toString() + (withSpace ? " : " : "");
      }
    }
    if (withSeconds) {
      if (second < 10 && withZeros) {
        timeText += "0$second";
      } else {
        timeText += second.toString();
      }
    }

    return timeText;
  }
}
