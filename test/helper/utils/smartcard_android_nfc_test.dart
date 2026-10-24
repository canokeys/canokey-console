@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';

import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

String _tag() =>
    jsonEncode({'type': 'iso7816', 'id': '00', 'standard': 'ISO 14443'});

void main() {
  const channel = MethodChannel('flutter_nfc_kit/method');
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  testWidgets('Android recovers from card errors and NFC unavailability', (
    tester,
  ) async {
    Get.testMode = true;
    addTearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
      SmartCard.connectionType = ConnectionType.none;
      SmartCard.refreshHandler = null;
      Get.reset();
    });
    Get.put(RxBool(false), tag: 'dialog_polling');
    const audioChannel = MethodChannel('org.canokeys.console/audio');
    messenger.setMockMethodCallHandler(audioChannel, (_) async => null);
    addTearDown(() => messenger.setMockMethodCallHandler(audioChannel, null));
    SmartCard.nfcState = NfcState.mute;
    addTearDown(() => SmartCard.nfcState = NfcState.mute);

    final polls = <Completer<String>>[];
    final finish = Completer<void>();
    var exchanges = 0;
    var finishes = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'poll':
          final poll = Completer<String>();
          polls.add(poll);
          return poll.future;
        case 'transceive':
          if (++exchanges == 1) {
            throw PlatformException(code: '500', message: 'Tag lost');
          }
          return '9000';
        case 'finish':
          finishes++;
          // Android disables reader mode and cancels the timeout, leaving
          // the outstanding poll unresolved even after finish returns.
          await finish.future;
          return null;
      }
      throw StateError('Unexpected method: ${call.method}');
    });

    unawaited(SmartCard.startAndroidNfcHandler());
    await tester.pump();
    polls[0].complete(_tag());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(polls, hasLength(2));

    final failedExchange = expectLater(
      SmartCard.transceive('00A4040000'),
      throwsA(isA<PlatformException>().having((e) => e.code, 'code', '500')),
    );
    await tester.pump();
    expect(finishes, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(polls, hasLength(2), reason: 'Do not poll during backend cleanup');
    finish.complete();
    await tester.pump();
    await failedExchange;
    await tester.pump(const Duration(milliseconds: 100));
    expect(polls, hasLength(3), reason: 'Do not wait for the abandoned poll');
    expect(exchanges, 1, reason: 'Never replay a failed APDU');

    polls[2].completeError(PlatformException(code: '500'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(polls, hasLength(4), reason: 'Poll errors must not kill the loop');
    polls[3].completeError(PlatformException(code: '408'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(polls, hasLength(5));

    SmartCard.nfcState = NfcState.processWithoutInput;
    var scanCompleted = false;
    final nextScan = SmartCard.pollNfcOrWebUsb().then((found) {
      scanCompleted = true;
      return found;
    });
    await tester.pump();
    // Even a late result from the abandoned poll cannot satisfy a new scan.
    polls[1].complete(_tag());
    await tester.pump();
    expect(scanCompleted, isFalse);
    expect(Get.find<RxBool>(tag: 'dialog_polling').value, isTrue);
    polls[4].complete(_tag());
    await tester.pump();
    expect(await nextScan, isTrue);
    final pollsDuringRead = polls.length;
    await tester.pump(const Duration(seconds: 1));
    expect(
      polls,
      hasLength(pollsDuringRead),
      reason: 'Keep reader mode stable',
    );
    expect(await SmartCard.transceive('00A4040000'), '9000');
    expect(exchanges, 2);
    final cleanup = SmartCard.stopPollingNfc();
    await tester.pump(const Duration(milliseconds: 500));
    await cleanup;
    await tester.pump(const Duration(milliseconds: 100));
    expect(Get.find<RxBool>(tag: 'dialog_polling').value, isFalse);

    SmartCard.nfcState = NfcState.mute;
    int unavailableLogs() => Logging.store.entries
        .where((entry) => entry.contains('[nfcHandler] NFC unavailable;'))
        .length;
    final initialLogs = unavailableLogs();
    final initialPolls = polls.length;
    polls.last.completeError(PlatformException(code: '404'));
    await tester.pump();
    expect(unavailableLogs(), initialLogs + 1);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(polls, hasLength(initialPolls));
    await tester.pump(const Duration(milliseconds: 1));
    expect(polls, hasLength(initialPolls + 1));

    polls.last.completeError(PlatformException(code: '404'));
    await tester.pump();
    expect(
      unavailableLogs(),
      initialLogs + 1,
      reason: 'Log an ongoing outage only once',
    );
    await tester.pump(const Duration(seconds: 2));
    expect(polls, hasLength(initialPolls + 2));

    // A normal timeout also proves that NFC is available again.
    polls.last.completeError(PlatformException(code: '408'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(polls, hasLength(initialPolls + 3));
    polls.last.completeError(PlatformException(code: '404'));
    await tester.pump();
    expect(unavailableLogs(), initialLogs + 2);
    await tester.pump(const Duration(seconds: 2));

    // A discovered tag restores normal polling and ends the outage too.
    polls.last.complete(_tag());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(polls, hasLength(initialPolls + 5));
    polls.last.completeError(PlatformException(code: '404'));
    await tester.pump();
    expect(unavailableLogs(), initialLogs + 3);
    await tester.pump(const Duration(seconds: 2));
    polls.last.complete(_tag());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(polls, hasLength(initialPolls + 7));

    // Reproduce recovery on a page: finish() returns before controller cleanup
    // ends. A second scan must not join that still-active failed refresh.
    final controllerCleanup = Completer<void>();
    var refreshes = 0;
    var failNextExchange = true;
    var failNextFinish = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'poll':
          final poll = Completer<String>();
          polls.add(poll);
          return poll.future;
        case 'finish':
          if (failNextFinish) {
            failNextFinish = false;
            throw PlatformException(
              code: '503',
              message: 'Tag already removed',
            );
          }
          return null;
        case 'transceive':
          exchanges++;
          if (failNextExchange) {
            failNextExchange = false;
            throw PlatformException(code: '500', message: 'Tag lost');
          }
          return '9000';
      }
      throw StateError('Unexpected method: ${call.method}');
    });
    SmartCard.nfcState = NfcState.idle;
    SmartCard.refreshHandler = () async {
      refreshes++;
      try {
        await SmartCard.transceive('00A4040000');
      } on PlatformException {
        SmartCard.nfcState = NfcState.idle;
        await controllerCleanup.future;
      }
    };
    final beforeFailure = polls.length;
    final exchangesBeforeFailure = exchanges;
    polls.last.complete(_tag());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(refreshes, 1);
    expect(
      exchanges,
      exchangesBeforeFailure + 1,
      reason: 'Do not replay APDUs',
    );
    expect(
      polls,
      hasLength(beforeFailure),
      reason: 'Wait for controller cleanup',
    );
    controllerCleanup.complete();
    await tester.pump();
    expect(Get.find<RxBool>(tag: 'dialog_polling').value, isFalse);
    expect(polls, hasLength(beforeFailure + 1));
    polls.last.complete(_tag());
    await tester.pump();
    expect(refreshes, 2, reason: 'The next tap must perform a new refresh');
    expect(exchanges, exchangesBeforeFailure + 2);
    expect(SmartCard.nfcState, NfcState.idle);
    await tester.pump(const Duration(milliseconds: 100));

    // On the real device, finish() itself threw for an out-of-date Tag. Reject
    // reuse of that handle, but recover when a subsequent poll supplies a tag.
    failNextExchange = true;
    failNextFinish = true;
    polls.last.complete(_tag());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final beforeFreshTag = exchanges;
    await expectLater(SmartCard.transceive('00A4040000'), throwsStateError);
    expect(
      exchanges,
      beforeFreshTag,
      reason: 'Do not reuse the obsolete handle',
    );
    expect(SmartCard.connectionError, contains('scan the card again'));
    polls.last.complete(_tag());
    await tester.pump();
    expect(exchanges, beforeFreshTag + 1);
    expect(SmartCard.connectionError, isNull);
    await tester.pump(const Duration(milliseconds: 100));

    // A failure before SmartCard.process starts must also dismiss the notice.
    SmartCard.refreshHandler = () => throw StateError('Refresh setup failed');
    polls.last.complete(_tag());
    await tester.pump();
    expect(Get.find<RxBool>(tag: 'dialog_polling').value, isFalse);
    expect(SmartCard.nfcState, NfcState.idle);
    await tester.pump(const Duration(milliseconds: 100));

    // A refresh may retain its card session while waiting for PIN entry. It
    // must release the scan gate at that boundary and accept another tap.
    final dialogClosed = Completer<void>();
    var dialogRefreshes = 0;
    SmartCard.refreshHandler = () async {
      dialogRefreshes++;
      await SmartCard.stopPollingNfc(withInput: true);
      await dialogClosed.future;
    };
    polls.last.complete(_tag());
    await tester.pump();
    final beforeInput = polls.length;
    await tester.pump(const Duration(milliseconds: 500));
    expect(SmartCard.nfcState, NfcState.input);
    expect(polls, hasLength(beforeInput + 1));
    // Dialog dismissal may restore idle before its owning future settles.
    SmartCard.nfcState = NfcState.idle;
    polls.last.complete(_tag());
    await tester.pump();
    expect(dialogRefreshes, 1);
    expect(SmartCard.nfcState, NfcState.idle);
    await tester.pump(const Duration(milliseconds: 100));
    SmartCard.nfcState = NfcState.processWithInput;
    final pinScan = SmartCard.pollNfcOrWebUsb();
    await tester.pump();
    polls.last.complete(_tag());
    await tester.pump();
    expect(await pinScan, isTrue);
    final duringPinRead = polls.length;
    await tester.pump(const Duration(seconds: 1));
    expect(polls, hasLength(duringPinRead));
    dialogClosed.complete();
    await tester.pump();
    expect(polls, hasLength(duringPinRead + 1));
    // Complete the operation's timer/notice before leaving the fake clock.
    final pinCleanup = SmartCard.stopPollingNfc();
    await tester.pump(const Duration(milliseconds: 500));
    await pinCleanup;

    // A genuine re-tap immediately after cleanup must not be discarded by a
    // wall-clock debounce. The ownership gate already prevents overlap.
    SmartCard.nfcState = NfcState.idle;
    var quickRefreshes = 0;
    SmartCard.refreshHandler = () async {
      quickRefreshes++;
      await SmartCard.stopPollingNfc();
    };
    polls.last.complete(_tag());
    await tester.pump();
    expect(quickRefreshes, 1);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 100));
    polls.last.complete(_tag());
    await tester.pump();
    expect(quickRefreshes, 2, reason: 'Accept a re-tap within two seconds');
    await tester.pump(const Duration(milliseconds: 500));
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
