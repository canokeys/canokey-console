import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

String stringifyLogMessage(dynamic message) {
  final value = message is Function ? message() : message;
  if (value is Map || value is Iterable) {
    return jsonEncode(value);
  }
  return value.toString();
}

class LogStore extends ChangeNotifier {
  static const capacity = 500;
  final _entries = ListQueue<String>();
  Timer? _notification;
  bool _enabled = true;
  bool _disposed = false;

  bool get enabled => _enabled;
  List<String> get entries => List.unmodifiable(_entries);
  String get text => _entries.join('\n');

  void setEnabled(bool enabled) {
    if (_disposed || _enabled == enabled) return;
    _enabled = enabled;
    notifyListeners();
  }

  void record(String tag, LogEvent event) {
    if (_disposed ||
        !_enabled ||
        event.level < Level.trace ||
        event.level == Level.off) {
      return;
    }
    _entries.add('${event.time.toIso8601String()} '
        '[${event.level.name.toUpperCase()}] [$tag] '
        '${stringifyLogMessage(event.message)}'
        '${event.error == null ? '' : '\nERROR: ${event.error}'}'
        '${event.stackTrace == null ? '' : '\n${event.stackTrace}'}');
    if (_entries.length > capacity) _entries.removeFirst();
    // Batch bursts of APDU traffic without delaying or filtering collection.
    if (hasListeners && _notification == null) {
      _notification = Timer(const Duration(milliseconds: 100), () {
        _notification = null;
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _notification?.cancel();
    super.dispose();
  }
}
