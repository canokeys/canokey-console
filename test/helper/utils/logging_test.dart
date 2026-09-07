import 'package:canokey_console/helper/utils/logging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

class _Output extends LogOutput {
  final lines = <String>[];
  @override
  void output(OutputEvent event) => lines.addAll(event.lines);
}

void main() {
  late LogStore store;
  setUp(() => store = LogStore());
  tearDown(() => store.dispose());

  test('full payloads, errors and stacks reach storage and the console', () {
    final output = _Output();
    final logger = DiagnosticLogger('SmartCard', store: store, output: output);
    final payload = '0020000006313233343536' * 300;
    final error = PlatformException(
      code: '500',
      message: 'PIN=123456',
      details: {'secret': 'JBSWY3DPEHPK3PXP'},
    );
    final stack = StackTrace.fromString(
      '#0 f (file:///Users/private-account/secret.dart:2:1)',
    );
    logger.e('C-APDU: $payload', error: error, stackTrace: stack);
    for (final text in [store.text, output.lines.join('\n')]) {
      expect(text, contains(payload));
      expect(text, contains(error.toString()));
      expect(text, contains(stack.toString()));
    }
  });

  test('all levels are captured independently of the console filter', () {
    final previous = Logger.level;
    addTearDown(() => Logger.level = previous);
    Logger.level = Level.warning;
    final output = _Output();
    final logger = DiagnosticLogger(
      'Test',
      store: store,
      output: output,
      filter: ProductionFilter(),
    );
    for (final level in [
      Level.trace,
      Level.debug,
      Level.info,
      Level.warning,
      Level.error,
      Level.fatal,
    ]) {
      logger.log(level, 'message-${level.name}');
    }
    expect(store.entries, hasLength(6));
    expect(store.text, contains('[TRACE] [Test] message-trace'));
    expect(output.lines.join(), isNot(contains('message-trace')));
    expect(output.lines.join(), contains('message-warning'));
    expect(Logger.level, Level.warning);
  });

  test('recording switch retains text and leaves Debug output active', () {
    final output = _Output();
    final logger = DiagnosticLogger('Test', store: store, output: output);
    logger.i('Before pause');
    final before = store.text;
    store.setEnabled(false);
    logger.i('Console while paused');
    expect(store.text, before);
    expect(output.lines.join(), contains('Console while paused'));
    store.setEnabled(true);
    logger.t('After resume');
    expect(store.entries, hasLength(2));
    expect(store.text, contains('After resume'));
  });

  test('latest 500 events retain order and repeated events stay separate', () {
    for (var i = 0; i < 510; i++) {
      store.record('Test', LogEvent(Level.trace, 'Event $i'));
    }
    expect(store.entries, hasLength(500));
    expect(store.entries.first, endsWith('Event 10'));
    expect(store.entries.last, endsWith('Event 509'));
    final event = LogEvent(Level.trace, 'Repeated');
    store.record('Test', event);
    store.record('Test', event);
    expect(store.entries, hasLength(500));
    expect(store.entries.first, endsWith('Event 12'));
    expect(store.entries.sublist(498), everyElement(endsWith('Repeated')));
  });

  test('lazy and structured messages preserve contents and evaluate once', () {
    var calls = 0;
    final output = _Output();
    final logger = DiagnosticLogger('Test', store: store, output: output);
    logger.i(() {
      calls++;
      return {'pin': '987654'};
    });
    logger.i(['otpauth://totp/account?secret=ABCDEF']);
    expect(calls, 1);
    expect(store.entries.first, contains('{"pin":"987654"}'));
    expect(
      store.entries.last,
      contains('otpauth://totp/account?secret=ABCDEF'),
    );
    expect(output.lines.join(), contains('{"pin":"987654"}'));
  });

  testWidgets('notifications are batched', (tester) async {
    var notifications = 0;
    store.addListener(() => notifications++);
    for (var i = 0; i < 500; i++) {
      store.record('NFC', LogEvent(Level.trace, 'Step $i'));
    }
    expect(notifications, 0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(notifications, 1);
  });

  testWidgets('disposing cancels pending notifications', (tester) async {
    final other = LogStore();
    var notifications = 0;
    other.addListener(() => notifications++);
    other.record('Test', LogEvent(Level.trace, 'Pending'));
    other.dispose();
    await tester.pump(const Duration(milliseconds: 100));
    expect(notifications, 0);
  });
}
