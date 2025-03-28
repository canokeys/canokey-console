import 'package:canokey_console/controller/applets/oath/oath_controller.dart';
import 'package:canokey_console/controller/applets/oath/qr_scan_result.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/no_credential_screen.dart';
import 'package:canokey_console/helper/widgets/poll_canokey_screen.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/search_box.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/src/rust/api/decode.dart';
import 'package:canokey_console/views/applets/oath/dialogs/add_account_dialog.dart';
import 'package:canokey_console/views/applets/oath/dialogs/qr_scanner_dialog.dart';
import 'package:canokey_console/views/applets/oath/widgets/oath_item_card.dart';
import 'package:canokey_console/views/applets/oath/widgets/top_actions.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';

final log = Logging.logger('OATH:View');

class OathPage extends StatefulWidget {
  const OathPage({super.key});

  @override
  State<OathPage> createState() => _OathPageState();
}

class _OathPageState extends State<OathPage> with UIMixin {
  final OathController controller = Get.put(OathController());
  final RxString searchText = ''.obs;
  final GlobalKey<FormState> _searchFormKey = GlobalKey<FormState>();

  late final Worker _qrScanWorker;

  @override
  void initState() {
    super.initState();
    Get.put(searchText, tag: 'oath_search');
    _qrScanWorker = ever(
      controller.qrScanResult,
      (QrScanResult? result) {
        if (result != null) {
          AddAccountDialog.show(
            controller.addAccount,
            initialIssuer: result.issuer,
            initialAccount: result.account,
            initialSecret: result.secret,
            initialCounter: result.initValue,
            initialType: result.type,
            initialAlgorithm: result.algo,
            initialDigits: result.digits,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _qrScanWorker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      title: 'TOTP / HOTP',
      topActions: GetBuilder(
        init: controller,
        builder: (_) => TopActions(
          controller: controller,
          onQrScan: () => QrScannerDialog.show(onQrCodeScanned: (value) => controller.parseUri(value)),
          onScreenCapture: _showScreenCapture,
          onManualAdd: () => AddAccountDialog.show(controller.addAccount),
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
                    if (ScreenMedia.getTypeFromWidth(MediaQuery.of(context).size.width).isMobile) ...{
                      Spacing.height(16),
                      SearchBox(formKey: _searchFormKey),
                    },
                    Spacing.height(16),
                    Obx(() {
                      final filteredMap = searchText.value.isEmpty
                          ? controller.oathMap
                          : Map.fromEntries(controller.oathMap.entries.where((entry) => entry.key.toLowerCase().contains(searchText.value.toLowerCase())));
                      if (filteredMap.isEmpty) return Center(child: CustomizedText.bodyMedium(S.of(context).noMatchingCredential, fontSize: 24));
                      return GridView.builder(
                        physics: ScrollPhysics(),
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        itemCount: filteredMap.length,
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 500,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 150,
                        ),
                        itemBuilder: (context, index) {
                          String name = filteredMap.keys.toList()[index];
                          return OathItemCard(
                            name: name,
                            item: filteredMap[name]!,
                            controller: controller,
                          );
                        },
                      );
                    }),
                    Spacing.height(16),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showScreenCapture() async {
    final stream = await webrtc.navigator.mediaDevices.getDisplayMedia({
      'audio': false,
      'video': true,
    });
    final track = stream.getVideoTracks().first;
    final buffer = await track.captureFrame();
    stream.getTracks().forEach((track) => track.stop());
    try {
      log.i('Rust decodePngQrcode start');
      final start = DateTime.now();
      final result = decodePngQrcode(pngFile: buffer.asUint8List());
      log.i('Rust decodePngQrcode took: ${DateTime.now().difference(start).inMilliseconds}ms');
      controller.parseUri(result);
    } catch (e) {
      log.w('Rust decodePngQrcode error: $e');
      if (mounted) {
        Prompts.showPrompt(S.of(context).oathNoQr, ContentThemeColor.danger);
      }
    }
  }
}
