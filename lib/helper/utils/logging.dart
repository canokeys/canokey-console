import 'package:logger/logger.dart';
import 'package:canokey_console/helper/utils/log_store.dart';

export 'log_store.dart';

class Logging {
  static final store = LogStore();

  static Logger logger(String tag) {
    return DiagnosticLogger(tag, store: store);
  }
}

class DiagnosticLogger extends Logger {
  DiagnosticLogger(this.tag, {required this.store, super.output, super.filter})
      : super(printer: SimplePrinter(tag));

  final String tag;
  final LogStore store;

  @override
  void log(Level level, dynamic message,
      {DateTime? time, Object? error, StackTrace? stackTrace}) {
    if (store.enabled) {
      // Evaluate lazy messages once for both the viewer and console.
      message = stringifyLogMessage(message);
      time ??= DateTime.now();
      store.record(
          tag,
          LogEvent(level, message,
              time: time, error: error, stackTrace: stackTrace));
    }
    super.log(level, message, time: time, error: error, stackTrace: stackTrace);
  }
}

class SimplePrinter extends LogPrinter {
  static final levelPrefixes = {
    Level.trace: '[T]',
    Level.debug: '[D]',
    Level.info: '[I]',
    Level.warning: '[W]',
    Level.error: '[E]',
    Level.fatal: '[FATAL]',
  };

  static final levelColors = {
    Level.trace: AnsiColor.fg(AnsiColor.grey(0.5)),
    Level.debug: const AnsiColor.none(),
    Level.info: const AnsiColor.fg(12),
    Level.warning: const AnsiColor.fg(208),
    Level.error: const AnsiColor.fg(196),
    Level.fatal: const AnsiColor.fg(199),
  };

  final String tag;

  SimplePrinter(this.tag);

  @override
  List<String> log(LogEvent event) {
    var messageStr = stringifyLogMessage(event.message);
    var errorStr = event.error != null ? '  ERROR: ${event.error}' : '';
    var timeStr = event.time.toIso8601String();
    return [
      '${_labelFor(event.level)} [$tag] $timeStr $messageStr$errorStr',
      if (event.stackTrace != null) event.stackTrace.toString()
    ];
  }

  String _labelFor(Level level) {
    var prefix = levelPrefixes[level]!;
    var color = levelColors[level]!;

    return color(prefix);
  }
}
