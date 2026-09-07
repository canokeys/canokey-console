import 'package:canokey_console/helper/services/log_navigation_observer.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('named navigation logs push, replace, pop and removal',
      (tester) async {
    final store = LogStore();
    addTearDown(store.dispose);
    final observer = LogNavigationObserver(
        logger: DiagnosticLogger('Navigation', store: store));
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      navigatorObservers: [observer],
      routes: {
        '/': (_) => const SizedBox(),
        '/settings': (_) => const SizedBox(),
        '/logs': (_) => const SizedBox(),
      },
    ));
    await tester.pumpAndSettle();
    key.currentState!.pushNamed('/settings');
    await tester.pumpAndSettle();
    key.currentState!.pushReplacementNamed('/logs');
    await tester.pumpAndSettle();
    key.currentState!.pop();
    await tester.pumpAndSettle();
    key.currentState!.pushNamed('/settings');
    await tester.pumpAndSettle();
    key.currentState!
        .pushNamedAndRemoveUntil('/logs', (route) => route.isFirst);
    await tester.pumpAndSettle();

    expect(store.text, contains('Push: <none> -> /'));
    expect(store.text, contains('Push: / -> /settings'));
    expect(store.text, contains('Replace: /settings -> /logs'));
    expect(store.text, contains('Pop: /logs -> /'));
    expect(store.text, contains('Remove: /settings; previous=/'));

    final before = store.text;
    store.setEnabled(false);
    key.currentState!.pop();
    await tester.pumpAndSettle();
    expect(store.text, before);
    expect(tester.takeException(), isNull);
  });
}
