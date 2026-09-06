import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/views/applets/oath/dialogs/qr_scanner_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class _ScannerPlatform extends MobileScannerPlatform {
  final captures = StreamController<BarcodeCapture?>.broadcast();
  int starts = 0;
  int stops = 0;
  bool permissionDenied = false;
  Completer<void>? permissionRequest;

  @override
  Stream<BarcodeCapture?> get barcodesStream => captures.stream;

  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();

  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();

  @override
  Widget buildCameraView() => const SizedBox.expand();

  @override
  Future<MobileScannerViewAttributes> start(StartOptions options) async {
    starts++;
    await permissionRequest?.future;
    if (permissionDenied) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );
    }
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.unavailable,
      size: Size(640, 480),
    );
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Future<void> dispose() async {}
}

Future<void> _openScanner(
  WidgetTester tester, {
  void Function(String)? onScan,
}) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Scaffold(
      body: Builder(builder: (context) {
        return TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => QrScannerDialog(
              onQrCodeScanned: onScan ?? (_) {},
            ),
          ),
          child: const Text('Open scanner'),
        );
      }),
    ),
  ));
  await tester.tap(find.text('Open scanner'));
  await tester.pumpAndSettle();
}

Future<void> _changeLifecycle(
  WidgetTester tester,
  AppLifecycleState state,
) async {
  tester.binding.handleAppLifecycleStateChanged(state);
  await tester.pump();
}

void main() {
  late MobileScannerPlatform originalPlatform;
  late _ScannerPlatform platform;

  setUp(() {
    originalPlatform = MobileScannerPlatform.instance;
    platform = _ScannerPlatform();
    MobileScannerPlatform.instance = platform;
  });

  tearDown(() async {
    MobileScannerPlatform.instance = originalPlatform;
    await platform.captures.close();
  });

  testWidgets('resumes scanning and handles a result only once',
      (tester) async {
    final scanned = <String>[];
    await _openScanner(tester, onScan: scanned.add);
    expect(platform.starts, 1);

    await _changeLifecycle(tester, AppLifecycleState.inactive);
    expect(platform.stops, 1);
    await _changeLifecycle(tester, AppLifecycleState.resumed);
    expect(platform.starts, 2);
    expect(
        tester
            .widget<MobileScanner>(find.byType(MobileScanner))
            .controller!
            .value
            .isRunning,
        isTrue);

    final capture = BarcodeCapture(barcodes: [
      const Barcode(rawValue: 'otpauth://totp/test?secret=JBSWY3DP'),
    ]);
    platform.captures.add(capture);
    platform.captures.add(capture);
    await tester.pumpAndSettle();

    expect(scanned, ['otpauth://totp/test?secret=JBSWY3DP']);
    expect(find.byType(QrScannerDialog), findsNothing);
    expect(find.text('Open scanner'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not restart while camera permission is pending',
      (tester) async {
    platform.permissionRequest = Completer<void>();
    await _openScanner(tester);

    await _changeLifecycle(tester, AppLifecycleState.inactive);
    await _changeLifecycle(tester, AppLifecycleState.resumed);
    expect(platform.starts, 1);
    expect(platform.stops, 0);

    platform.permissionRequest!.complete();
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<MobileScanner>(find.byType(MobileScanner))
            .controller!
            .value
            .isRunning,
        isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('retries after granting camera permission in settings',
      (tester) async {
    platform.permissionDenied = true;
    await _openScanner(tester);
    final controller =
        tester.widget<MobileScanner>(find.byType(MobileScanner)).controller!;
    expect(controller.value.hasCameraPermission, isFalse);

    await _changeLifecycle(tester, AppLifecycleState.inactive);
    platform.permissionDenied = false;
    await _changeLifecycle(tester, AppLifecycleState.resumed);

    expect(platform.starts, 2);
    expect(controller.value.hasCameraPermission, isTrue);
    expect(controller.value.isRunning, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
