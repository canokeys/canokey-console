@Tags(['native'])
library;

import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _waitUntil(bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (!ready()) {
    if (DateTime.now().isAfter(deadline)) fail('CCID polling timed out');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => RustLib.init());
  tearDownAll(RustLib.dispose);

  test(
    'unplugged reader cleanup allows another key; real failures quarantine',
    () async {
      const channel = MethodChannel('ccid');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var readers = ['CanoKey Canary'];
      final connections = <String>[];
      var disconnects = 0;
      var listings = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'listReaders':
            listings++;
            return readers;
          case 'connect':
            connections.add(call.arguments as String);
            return null;
          case 'transceive':
            final command = (call.arguments as Map)['capdu'] as String;
            if (command == '00FE679D04A1A2A3A4') return 'B1B2B3B49000';
            return command.startsWith('00A4') ? '9000' : '001145149000';
          case 'disconnect':
            disconnects++;
            throw PlatformException(
              code: disconnects == 1
                  ? 'CCID_READER_NOT_FOUND'
                  : 'CCID_DISCONNECT_ERROR',
            );
        }
        throw StateError('Unexpected method ${call.method}');
      });
      final timer = SmartCard.pollCcid();
      addTearDown(() {
        timer.cancel();
        messenger.setMockMethodCallHandler(channel, null);
        SmartCard.connectionType = ConnectionType.none;
      });

      await _waitUntil(() => SmartCard.connectionType == ConnectionType.ccid);
      expect(await SmartCard.transceive('00FE679D04A1A2A3A4'), 'B1B2B3B49000');
      expect(Logging.store.text, contains('C-APDU: 00FE679D (9 bytes)'));
      expect(Logging.store.text, contains('R-APDU: SW=9000 (6 bytes)'));
      expect(Logging.store.text, isNot(contains('A1A2A3A4')));
      expect(Logging.store.text, isNot(contains('B1B2B3B4')));
      readers = [];
      await _waitUntil(() => SmartCard.connectionType == ConnectionType.none);
      readers = ['CanoKey Pigeon'];
      await _waitUntil(() => SmartCard.connectionType == ConnectionType.ccid);
      expect(connections, ['CanoKey Canary', 'CanoKey Pigeon']);
      expect(SmartCard.connectionError, isNull);

      readers = [];
      await _waitUntil(() => SmartCard.connectionType == ConnectionType.none);
      expect(SmartCard.connectionError, contains('cleanup failed'));
      final listingsAtFailure = listings;
      readers = ['CanoKey Canary'];
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(listings, listingsAtFailure);
      expect(connections, hasLength(2));
    },
  );
}
