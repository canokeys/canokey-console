import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/controller/applets/webauthn/webauthn_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/applet_disabled_screen.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/poll_canokey_screen.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/search_box.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/webauthn.dart';
import 'package:canokey_console/views/applets/webauthn/widgets/top_actions.dart';
import 'package:canokey_console/views/applets/webauthn/widgets/webauthn_credential_grid.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';

class WebAuthnPage extends StatefulWidget {
  const WebAuthnPage({super.key});

  @override
  State<WebAuthnPage> createState() => _WebAuthnPageState();
}

class _WebAuthnPageState extends State<WebAuthnPage> with UIMixin {
  final WebAuthnController controller = Get.put(WebAuthnController());
  final RxString searchText = ''.obs;
  final RxBool sortAlphabetically = false.obs;
  final GlobalKey<FormState> _searchFormKey = GlobalKey<FormState>();

  late final Worker _sortWorker;

  @override
  void initState() {
    super.initState();
    Get.put(searchText, tag: 'webauthn_search');
    Get.put(sortAlphabetically, tag: 'webauthn_sort');

    // Load saved preference
    sortAlphabetically.value = LocalStorage.getWebAuthnSortAlphabetically();

    // Save preference when it changes
    _sortWorker = ever(sortAlphabetically, (bool value) {
      LocalStorage.setWebAuthnSortAlphabetically(value);
    });
  }

  @override
  void dispose() {
    _sortWorker.dispose();
    Get.delete<RxString>(tag: 'webauthn_search');
    Get.delete<RxBool>(tag: 'webauthn_sort');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = ScreenMedia.getTypeFromWidth(
      MediaQuery.sizeOf(context).width,
    ).isMobile;
    return Layout(
      title: 'WebAuthn',
      onRefresh: controller.refreshData,
      topActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(
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
          TopActions(controller: controller),
        ],
      ),
      child: GetBuilder(
        init: controller,
        builder: (_) {
          if (controller.disabledMessage != null) {
            return AppletDisabledScreen(message: controller.disabledMessage!);
          }
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
                      Row(
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
                              LucideIcons.keyRound,
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
                                  S.of(context).webAuthnCredentials,
                                  fontWeight: 700,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                const SizedBox(height: 6),
                                CustomizedText.bodyMedium(
                                  S.of(context).webAuthnDescription,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                    ],
                    if (ScreenMedia.getTypeFromWidth(
                      MediaQuery.of(context).size.width,
                    ).isMobile) ...{
                      SearchBox(
                        formKey: _searchFormKey,
                        hintText: S.of(context).webAuthnSearch,
                      ),
                      Spacing.height(20),
                    },
                    Obx(() {
                      final filteredItems = searchText.value.isEmpty
                          ? controller.webAuthnItems
                          : controller.webAuthnItems
                                .where(
                                  (item) =>
                                      item.rpId.toLowerCase().contains(
                                        searchText.value.toLowerCase(),
                                      ) ||
                                      item.userName.toLowerCase().contains(
                                        searchText.value.toLowerCase(),
                                      ) ||
                                      item.userDisplayName
                                          .toLowerCase()
                                          .contains(
                                            searchText.value.toLowerCase(),
                                          ),
                                )
                                .toList();
                      if (filteredItems.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: CustomizedText.bodyMedium(
                              controller.webAuthnItems.isEmpty
                                  ? S.of(context).noCredential
                                  : S.of(context).noMatchingCredential,
                              fontSize: 18,
                            ),
                          ),
                        );
                      }
                      final items = List<WebAuthnItem>.from(filteredItems);
                      if (sortAlphabetically.value) {
                        items.sort((a, b) {
                          final aRpId = a.rpId.split('.').reversed.toList();
                          final bRpId = b.rpId.split('.').reversed.toList();
                          if (aRpId.length >= 2) {
                            final temp = aRpId[0];
                            aRpId[0] = aRpId[1];
                            aRpId[1] = temp;
                          }
                          if (bRpId.length >= 2) {
                            final temp = bRpId[0];
                            bRpId[0] = bRpId[1];
                            bRpId[1] = temp;
                          }
                          for (
                            int i = 0;
                            i < aRpId.length && i < bRpId.length;
                            i++
                          ) {
                            final aRpIdChip = aRpId[i];
                            final bRpIdChip = bRpId[i];
                            if (aRpIdChip != bRpIdChip) {
                              return aRpIdChip.toLowerCase().compareTo(
                                bRpIdChip.toLowerCase(),
                              );
                            }
                          }
                          if (aRpId.length != bRpId.length) {
                            return aRpId.length.compareTo(bRpId.length);
                          }
                          return a.userName.toLowerCase().compareTo(
                            b.userName.toLowerCase(),
                          );
                        });
                      }
                      return WebAuthnCredentialGrid(
                        items: items,
                        controller: controller,
                      );
                    }),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => Prompts.showPrompt(
                          S.of(context).webAuthnMissingCredentialsExplanation,
                          ContentThemeColor.info,
                          forceSnackBar: true,
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: const Color(0xff009b83),
                        ),
                        child: CustomizedText.bodyMedium(
                          S.of(context).webAuthnMissingCredentials,
                          textAlign: TextAlign.center,
                          color: const Color(0xff009b83),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
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
