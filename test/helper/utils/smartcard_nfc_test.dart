@TestOn('vm')
library;

import 'dart:convert';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    GetMaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: const Scaffold(body: SizedBox.shrink()),
    ),
  );
  await tester.pumpAndSettle();
}

String _tag() =>
    jsonEncode({'type': 'iso7816', 'id': '00', 'standard': 'ISO 14443'});

void main() {
  const channel = MethodChannel('flutter_nfc_kit/method');
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    Get.testMode = true;
    SmartCard.connectionType = ConnectionType.none;
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    SmartCard.connectionType = ConnectionType.none;
    Get.reset();
  });

  testWidgets('iOS connection polls only ISO 14443 without NDEF discovery', (
    tester,
  ) async {
    await _pumpApp(tester);
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'poll' ? _tag() : null;
    });

    expect(await SmartCard.pollNfcOrWebUsb(), isTrue);
    final arguments = calls.single.arguments as Map;
    // 0x80 is Android's NDEF skip bit; iOS ignores it.
    expect(arguments['technologies'], 0x83);
    expect(arguments['checkNDEF'], isFalse);
    expect(arguments['iosAlertMessage'], S.current.iosAlertMessage);
    await SmartCard.stopPollingNfc();
    expect(calls.map((call) => call.method), ['poll', 'finish']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('failed iOS setup finishes before the next scan', (tester) async {
    await _pumpApp(tester);
    final calls = <String>[];
    var failed = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'finish') return null;
      if (!failed) {
        failed = true;
        throw PlatformException(
          code: '500',
          message: 'Error connecting to card',
        );
      }
      return _tag();
    });

    await expectLater(
      SmartCard.pollNfcOrWebUsb(),
      throwsA(isA<PlatformException>()),
    );
    expect(await SmartCard.pollNfcOrWebUsb(), isTrue);
    await SmartCard.stopPollingNfc();
    expect(calls, ['poll', 'finish', 'poll', 'finish']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('iOS cleanup failure preserves the original setup error', (
    tester,
  ) async {
    await _pumpApp(tester);
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      throw PlatformException(code: call.method == 'poll' ? '500' : '406');
    });

    await expectLater(
      SmartCard.pollNfcOrWebUsb(),
      throwsA(
        isA<PlatformException>().having((error) => error.code, 'code', '500'),
      ),
    );
    expect(calls, ['poll', 'finish']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('non-iOS connection keeps default polling options', (
    tester,
  ) async {
    await _pumpApp(tester);
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'poll' ? _tag() : null;
    });

    expect(await SmartCard.pollNfcOrWebUsb(), isTrue);
    final arguments = calls.single.arguments as Map;
    expect(arguments['technologies'], 0x0b);
    expect(arguments['checkNDEF'], isTrue);
    await SmartCard.stopPollingNfc();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('non-iOS poll failure leaves backend cleanup to its caller', (
    tester,
  ) async {
    await _pumpApp(tester);
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      throw PlatformException(code: '500', message: 'No device selected');
    });

    await expectLater(
      SmartCard.pollNfcOrWebUsb(),
      throwsA(isA<PlatformException>().having((e) => e.code, 'code', '500')),
    );
    expect(calls, ['poll']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
