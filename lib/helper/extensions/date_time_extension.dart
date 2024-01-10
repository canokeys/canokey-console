import 'package:flutter/material.dart';

extension DateTimeExtension on DateTime {
  DateTime applied(TimeOfDay time) {
    return DateTime(year, month, day, time.hour, time.minute);
  }

  TimeOfDay get timeOfDay {
    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  String getMonthName({bool short = true}) {
    String cMonth = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ][month - 1];
    return short ? cMonth.substring(0, 3) : cMonth;
  }
}
