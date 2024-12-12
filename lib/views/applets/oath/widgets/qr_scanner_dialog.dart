import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerDialog extends StatefulWidget {
  final Function(String) onQrCodeScanned;

  const QrScannerDialog({
    super.key,
    required this.onQrCodeScanned,
  });

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> with UIMixin, WidgetsBindingObserver {
  final MobileScannerController scannerController = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  StreamSubscription<Object?>? _subscription;

  void _handleBarcode(BarcodeCapture event) {
    var barcode = event.barcodes.firstOrNull;
    if (barcode != null) {
      Navigator.pop(context);
      widget.onQrCodeScanned(barcode.rawValue!);
    }
  }

  @override
  void initState() {
    super.initState();
    // Start listening to lifecycle changes.
    WidgetsBinding.instance.addObserver(this);
    // Start listening to the barcode events.
    _subscription = scannerController.barcodes.listen(_handleBarcode);
    // Finally, start the scanner itself.
    unawaited(scannerController.start());
  }

  @override
  void dispose() async {
    // Stop listening to lifecycle changes.
    WidgetsBinding.instance.removeObserver(this);
    // Stop listening to the barcode events.
    unawaited(_subscription?.cancel());
    _subscription = null;
    // Dispose the widget itself.
    super.dispose();
    // Finally, dispose of the controller.
    await scannerController.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the controller is not ready, do not try to start or stop it.
    // Permission dialogs can trigger lifecycle changes before the controller is ready.
    if (!scannerController.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        // Restart the scanner when the app is resumed.
        // Don't forget to resume listening to the barcode events.
        _subscription = scannerController.barcodes.listen(_handleBarcode);
        unawaited(scannerController.stop());
      case AppLifecycleState.inactive:
        // Stop the scanner when the app is paused.
        // Also stop the barcode events subscription.
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(scannerController.stop());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.of(context).oathAddAccount),
            ),
            Divider(height: 0, thickness: 1),
            SizedBox(
              height: 400,
              child: MobileScanner(
                controller: scannerController,
                onDetect: _handleBarcode,
              ),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomizedButton.rounded(
                    onPressed: () => Navigator.pop(context),
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.secondary,
                    child: CustomizedText.labelMedium(S.of(context).cancel, color: contentTheme.onSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
