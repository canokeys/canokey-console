import 'dart:typed_data';

import 'package:canokey_console/controller/applets/oath/oath_controller.dart';
import 'package:canokey_console/controller/applets/oath/qr_scan_result.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/poll_canokey_screen.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/search_box.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/src/rust/api/decode.dart';
import 'package:canokey_console/views/applets/oath/dialogs/add_account_dialog.dart';
import 'package:canokey_console/views/applets/oath/dialogs/qr_scanner_dialog.dart';
import 'package:canokey_console/views/applets/oath/widgets/oath_account_grid.dart';
import 'package:canokey_console/views/applets/oath/widgets/top_actions.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';

final log = Logging.logger('OATH:View');

class OathPage extends StatefulWidget {
  const OathPage({super.key});

  @override
  State<OathPage> createState() => _OathPageState();
}

class _OathPageState extends State<OathPage> with UIMixin {
  final OathController controller = Get.put(OathController());
  final RxString searchText = ''.obs;
  final RxBool sortAlphabetically = false.obs;
  final GlobalKey<FormState> _searchFormKey = GlobalKey<FormState>();

  late final Worker _qrScanWorker;
  late final Worker _sortWorker;

  @override
  void initState() {
    super.initState();
    Get.put(searchText, tag: 'oath_search');
    Get.put(sortAlphabetically, tag: 'oath_sort');

    // Load saved preference
    sortAlphabetically.value = LocalStorage.getOathSortAlphabetically();

    // Save preference when it changes
    _sortWorker = ever(sortAlphabetically, (bool value) {
      LocalStorage.setOathSortAlphabetically(value);
    });

    _qrScanWorker = ever(controller.qrScanResult, (QrScanResult? result) {
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
    });
  }

  @override
  void dispose() {
    _qrScanWorker.dispose();
    _sortWorker.dispose();
    Get.delete<RxString>(tag: 'oath_search');
    Get.delete<RxBool>(tag: 'oath_sort');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = ScreenMedia.getTypeFromWidth(
      MediaQuery.sizeOf(context).width,
    ).isMobile;
    return Layout(
      title: 'TOTP / HOTP',
      onRefresh: controller.refreshData,
      topActions: GetBuilder(
        init: controller,
        builder: (_) => TopActions(
          controller: controller,
          showAdd: mobile,
          leading: Obx(
            () => IconButton(
              onPressed: () =>
                  sortAlphabetically.value = !sortAlphabetically.value,
              icon: Icon(
                sortAlphabetically.value
                    ? LucideIcons.arrowDownAZ
                    : LucideIcons.clock,
                color: topBarTheme.onBackground,
              ),
            ),
          ),
          onQrScan: () => QrScannerDialog.show(
            onQrCodeScanned: (value) => controller.parseUri(value),
          ),
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  flexSpacing,
                  ScreenMedia.getTypeFromWidth(
                        MediaQuery.sizeOf(context).width,
                      ).isMobile
                      ? 16
                      : 0,
                  flexSpacing,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!mobile) ...[
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final heading = Row(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xff009b83,
                                  ).withValues(alpha: .14),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  LucideIcons.timer,
                                  size: 38,
                                  color: Color(0xff009b83),
                                ),
                              ),
                              const SizedBox(width: 22),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomizedText.headlineMedium(
                                      'TOTP / HOTP',
                                      fontWeight: 700,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                    const SizedBox(height: 6),
                                    CustomizedText.bodyMedium(
                                      S.of(context).oathDescription,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                          final addButton = OathAddAccountButton(
                            prominent: true,
                            onQrScan: () => QrScannerDialog.show(
                              onQrCodeScanned: controller.parseUri,
                            ),
                            onScreenCapture: _showScreenCapture,
                            onManualAdd: () =>
                                AddAccountDialog.show(controller.addAccount),
                          );
                          if (constraints.maxWidth < 760 ||
                              MediaQuery.textScalerOf(context).scale(14) > 20) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                heading,
                                const SizedBox(height: 20),
                                addButton,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: heading),
                              const SizedBox(width: 24),
                              addButton,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 26),
                    ],
                    if (ScreenMedia.getTypeFromWidth(
                      MediaQuery.of(context).size.width,
                    ).isMobile) ...{
                      SearchBox(
                        formKey: _searchFormKey,
                        hintText: S.of(context).oathSearch,
                      ),
                      Spacing.height(20),
                    },
                    Obx(() {
                      final filteredMap = searchText.value.isEmpty
                          ? controller.oathMap
                          : Map.fromEntries(
                              controller.oathMap.entries.where(
                                (entry) => entry.key.toLowerCase().contains(
                                  searchText.value.toLowerCase(),
                                ),
                              ),
                            );
                      if (filteredMap.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: CustomizedText.bodyMedium(
                              controller.oathMap.isEmpty
                                  ? S.of(context).noCredential
                                  : S.of(context).noMatchingCredential,
                              fontSize: 18,
                            ),
                          ),
                        );
                      }
                      final names = filteredMap.keys.toList();
                      if (sortAlphabetically.value) {
                        names.sort(
                          (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
                        );
                      }
                      return OathAccountGrid(
                        accounts: {
                          for (final name in names) name: filteredMap[name]!,
                        },
                        controller: controller,
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
    log.t('Call _OathPageState._showScreenCapture');
    var sources = <webrtc.DesktopCapturerSource?>[null];
    if (webrtc.WebRTC.platformIsDesktop) {
      try {
        final desktopSources = await webrtc.desktopCapturer.getSources(
          types: [webrtc.SourceType.Screen],
        );
        if (desktopSources.isNotEmpty) {
          sources = desktopSources;
        }
      } catch (e) {
        log.w('Cannot enumerate screens, using the default screen', error: e);
      }
    }

    for (final source in sources) {
      try {
        log.i('Capturing screen: ${source?.name ?? 'default'}');
        final buffer = await _captureScreen(source);
        final start = DateTime.now();
        final result = decodePngQrcode(pngFile: buffer.asUint8List());
        log.d('Decoded QR code: $result');
        log.i(
          'Rust decodePngQrcode took: ${DateTime.now().difference(start).inMilliseconds}ms',
        );
        controller.parseUri(result);
        return;
      } catch (e) {
        log.w(
          'Cannot decode QR code from ${source?.name ?? 'default'}',
          error: e,
        );
      }
    }

    if (mounted) {
      Prompts.showPrompt(S.of(context).oathNoQr, ContentThemeColor.danger);
    }
  }

  Future<ByteBuffer> _captureScreen(
    webrtc.DesktopCapturerSource? source,
  ) async {
    final stream = await webrtc.navigator.mediaDevices.getDisplayMedia({
      'audio': false,
      'video': source == null
          ? true
          : {
              'deviceId': {'exact': source.id},
            },
    });
    try {
      final tracks = stream.getVideoTracks();
      if (tracks.isEmpty) {
        throw StateError('Screen capture returned no video track');
      }
      return await tracks.first.captureFrame();
    } finally {
      for (final track in stream.getTracks()) {
        track.stop();
      }
    }
  }
}
