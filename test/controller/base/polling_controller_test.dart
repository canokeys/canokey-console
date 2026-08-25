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
}
