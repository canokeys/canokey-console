import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerDialog extends StatefulWidget {
  final Function(String) onQrCodeScanned;

  const QrScannerDialog({super.key, required this.onQrCodeScanned});

  static void show({required Function(String) onQrCodeScanned}) {
    AppDialog.show(QrScannerDialog(onQrCodeScanned: onQrCodeScanned));
  }

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog>
    with UIMixin, WidgetsBindingObserver {
  final MobileScannerController scannerController = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
  );
  bool _handledBarcode = false;

  void _handleBarcode(BarcodeCapture event) {
    final value = event.barcodes.firstOrNull?.rawValue;
    if (mounted && !_handledBarcode && value != null && value.isNotEmpty) {
      _handledBarcode = true;
      Navigator.pop(context);
      widget.onQrCodeScanned(value);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(scannerController.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the controller is not ready, do not try to start or stop it.
    // Permission dialogs can trigger lifecycle changes before the controller is ready.
    if (!scannerController.value.isInitialized ||
        scannerController.value.isStarting ||
        _handledBarcode) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        unawaited(scannerController.start());
      case AppLifecycleState.inactive:
        unawaited(scannerController.stop());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogSurface(
      child: SizedBox(
        width: AppDialogWidth.compact,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppDialogHeader(title: S.of(context).oathAddAccount),
            Divider(height: 0, thickness: 1),
            Flexible(
              child: SizedBox(
                height: 400,
                child: MobileScanner(
                  controller: scannerController,
                  onDetect: _handleBarcode,
                ),
              ),
            ),
            Divider(height: 0, thickness: 1),
            AppDialogActions(
              children: [
                AppDialogAction(
                  label: S.of(context).cancel,
                  onPressed: () => Navigator.pop(context),
                  secondary: true,
                  destructive: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
