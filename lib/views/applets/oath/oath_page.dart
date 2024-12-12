import 'package:canokey_console/controller/applets/oath/oath_controller.dart';
import 'package:canokey_console/controller/applets/oath/qr_scan_result.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:canokey_console/views/applets/oath/widgets/add_account_dialog.dart';
import 'package:canokey_console/views/applets/oath/widgets/delete_dialog.dart';
import 'package:canokey_console/views/applets/oath/widgets/no_credential_screen.dart';
import 'package:canokey_console/views/applets/oath/widgets/oath_item_card.dart';
import 'package:canokey_console/views/applets/oath/widgets/oath_top_actions.dart';
import 'package:canokey_console/views/applets/oath/widgets/qr_scanner_dialog.dart';
import 'package:canokey_console/views/applets/oath/widgets/set_default_dialog.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:canokey_console/widgets/poll_cano_key_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:logging/logging.dart';
import 'package:zxing2/qrcode.dart' as zxing;

final log = Logger('Console:OATH:View');

class OathPage extends StatefulWidget {
  const OathPage({super.key});

  @override
  State<OathPage> createState() => _OathPageState();
}

class _OathPageState extends State<OathPage> with UIMixin {
  final OathController controller = OathController();
  late final Worker _qrScanWorker;

  @override
  void initState() {
    super.initState();
    _qrScanWorker = ever(
      controller.qrScanResult,
      (QrScanResult? result) {
        if (result != null) {
          _showQrConfirmDialog(result.issuer, result.account, result.secret, result.type, result.algo, result.digits, result.initValue);
        }
      },
    );
  }

  @override
  void dispose() {
    _qrScanWorker.dispose();
    super.dispose();
  }

  void _showQrScanner() {
    Get.dialog(QrScannerDialog(
      onQrCodeScanned: (value) => controller.addUri(value),
    ));
  }

  void _showScreenCapture() async {
    final stream = await webrtc.navigator.mediaDevices.getDisplayMedia({
      'audio': false,
      'video': true,
    });
    final track = stream.getVideoTracks().first;
    final buffer = await track.captureFrame();
    stream.getTracks().forEach((track) => track.stop());
    final image = img.decodePng(buffer.asUint8List())!;
    final source = zxing.RGBLuminanceSource(
      image.width,
      image.height,
      image.convert(numChannels: 4).getBytes(order: img.ChannelOrder.abgr).buffer.asInt32List(),
    );
    final bitmap = zxing.BinaryBitmap(zxing.GlobalHistogramBinarizer(source));
    final reader = zxing.QRCodeReader();
    try {
      final result = reader.decode(bitmap);
      controller.addUri(result.text);
    } catch (e) {
      if (mounted) {
        Prompts.showPrompt(S.of(context).oathNoQr, ContentThemeColor.danger);
      }
    }
  }

  void _showAddAccountDialog() {
    Get.dialog(
      AddAccountDialog(controller: controller),
      barrierDismissible: false,
    );
  }

  void _showDeleteDialog(String name) {
    Get.dialog(DeleteDialog(
      name: name,
      onDelete: () => controller.delete(name),
    ));
  }

  void _showSetDefaultDialog(String name) {
    Get.dialog(SetDefaultDialog(
      name: name,
      onSetDefault: (slot, withEnter) => controller.setDefault(name, slot, withEnter),
    ));
  }

  void _showQrConfirmDialog(String issuer, String account, String secret, OathType type, OathAlgorithm algo, int digits, int initValue) {
    Get.dialog(
      AddAccountDialog(
        controller: controller,
        initialIssuer: issuer,
        initialAccount: account,
        initialSecret: secret,
        initialCounter: initValue,
        initialType: type,
        initialAlgorithm: algo,
        initialDigits: digits,
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      title: 'TOTP / HOTP',
      topActions: GetBuilder(
        init: controller,
        builder: (_) => OathTopActions(
          controller: controller,
          onQrScan: _showQrScanner,
          onScreenCapture: _showScreenCapture,
          onManualAdd: _showAddAccountDialog,
        ),
      ),
      child: GetBuilder(
        init: controller,
        builder: (_) {
          if (!controller.polled) {
            return PollCanoKeyScreen();
          }
          if (controller.oathMap.isEmpty) {
            return NoCredentialScreen();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.x(flexSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Spacing.height(20),
                    GridView.builder(
                      physics: ScrollPhysics(),
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      itemCount: controller.oathMap.length,
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 500,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 150,
                      ),
                      itemBuilder: (context, index) {
                        String name = controller.oathMap.keys.toList()[index];
                        return OathItemCard(
                          name: name,
                          item: controller.oathMap[name]!,
                          controller: controller,
                          onDelete: _showDeleteDialog,
                          onSetDefault: _showSetDefaultDialog,
                        );
                      },
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
