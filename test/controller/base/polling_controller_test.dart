import 'dart:async';

import 'package:canokey_console/controller/base/polling_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

void main() {
  test('refreshData reuses an in-progress refresh', () async {
    final controller = _TestPollingController();

    final first = controller.refreshData();
    final second = controller.refreshData();

    expect(identical(first, second), isTrue);
    expect(controller.refreshCount, 1);

    controller.completeRefresh();
    await Future.wait([first, second]);

    final third = controller.refreshData();
    expect(controller.refreshCount, 2);
    controller.completeRefresh();
    await third;
  });

  test('refresh preserves failures and allows retry', () async {
    final controller = _TestPollingController();
    final error = StateError('raw device error');
    final stack = StackTrace.fromString('original refresh stack');
    final first = controller.refreshData();
    final assertion = expectLater(first, throwsA(same(error)));
    controller.failRefresh(error, stack);
    await assertion;

    final retry = controller.refreshData();
    expect(controller.refreshCount, 2);
    controller.completeRefresh();
    await retry;
  });
}

class _TestPollingController extends PollingController {
  Completer<void> _completer = Completer<void>();
  int refreshCount = 0;

  @override
  final Logger log = Logger(printer: SimplePrinter());

  @override
  Future<void> doRefreshData() {
    refreshCount++;
    return _completer.future;
  }

  void completeRefresh() {
    _completer.complete();
    _completer = Completer<void>();
  }

  void failRefresh(Object error, StackTrace stack) {
    _completer.completeError(error, stack);
    _completer = Completer<void>();
  }
}
