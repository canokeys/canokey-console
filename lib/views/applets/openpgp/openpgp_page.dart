import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/controller/applets/openpgp/openpgp_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/applet_disabled_screen.dart';
import 'package:canokey_console/helper/widgets/change_pin_dialog.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/helper/widgets/poll_canokey_screen.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/views/applets/openpgp/dialogs/openpgp_reset_code_dialog.dart';
import 'package:canokey_console/views/applets/openpgp/dialogs/openpgp_signature_pin_policy_dialog.dart';
import 'package:canokey_console/views/applets/openpgp/dialogs/openpgp_touch_cache_time_dialog.dart';
import 'package:canokey_console/views/applets/openpgp/dialogs/openpgp_touch_policy_dialog.dart';
import 'package:canokey_console/views/applets/openpgp/dialogs/openpgp_unblock_pin_dialog.dart';
import 'package:canokey_console/views/applets/openpgp/dialogs/openpgp_pin_retries_dialog.dart';
import 'package:canokey_console/views/applets/openpgp/widgets/openpgp_card_info_card.dart';
import 'package:canokey_console/views/applets/openpgp/widgets/openpgp_key_slots_card.dart';
import 'package:canokey_console/views/applets/openpgp/widgets/openpgp_pin_management_card.dart';
import 'package:canokey_console/views/applets/openpgp/widgets/openpgp_touch_policy_card.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:platform_detector/platform_detector.dart';

class OpenPgpPage extends StatefulWidget {
  const OpenPgpPage({super.key});

  @override
  State<OpenPgpPage> createState() => _OpenPgpPageState();
}

class _OpenPgpPageState extends State<OpenPgpPage> with UIMixin {
  final OpenPgpController controller = Get.put(OpenPgpController());

  @override
  Widget build(BuildContext context) {
    final mobile = ScreenMedia.getTypeFromWidth(
      MediaQuery.sizeOf(context).width,
    ).isMobile;
    return Layout(
      title: 'OpenPGP',
      onRefresh: controller.refreshData,
      topActions: isWeb() || isIOSApp()
          ? IconButton(
              tooltip: S.of(context).refresh,
              icon: Icon(
                LucideIcons.refreshCw,
                color: topBarTheme.onBackground,
              ),
              onPressed: controller.refreshData,
            )
          : null,
      child: GetBuilder(
        init: controller,
        builder: (_) {
          if (controller.disabledMessage != null) {
            return AppletDisabledScreen(message: controller.disabledMessage!);
          }
          final info = controller.cardInfo;
          if (!controller.polled || info == null) {
            return PollCanoKeyScreen();
          }
          return Padding(
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
                          color: const Color(0xff009b83).withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          LucideIcons.lock,
                          size: 36,
                          color: Color(0xff009b83),
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomizedText.headlineMedium(
                              'OpenPGP',
                              fontWeight: 700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(height: 6),
                            CustomizedText.bodyMedium(
                              S.of(context).openpgpDescription,
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final pinCard = OpenPgpPinManagementCard(
                      pinState: info.pinState,
                      supportsPinRetryConfig: controller.supportsPinRetryConfig,
                      onChangeUserPin: _showChangeUserPin,
                      onChangeAdminPin: _showChangeAdminPin,
                      onUnblockPin: () => OpenPgpUnblockPinDialog.show(
                        onSubmitWithAdmin: controller.unblockUserPinWithAdmin,
                        onSubmitWithResetCode:
                            controller.unblockUserPinWithResetCode,
                      ),
                      onSetResetCode: () => OpenPgpResetCodeDialog.show(
                        onSubmit: controller.setResetCode,
                      ),
                      onSetPinRetries: () => OpenPgpPinRetriesDialog.show(
                        pinState: info.pinState,
                        onSubmit: controller.setPinRetries,
                      ),
                      onSetSignaturePinPolicy: () =>
                          OpenPgpSignaturePinPolicyDialog.show(
                            pinState: info.pinState,
                            onSubmit: controller.setSignaturePinPolicy,
                          ),
                    );
                    final infoCard = OpenPgpCardInfoCard(info: info);
                    if (constraints.maxWidth < 1000) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          infoCard,
                          const SizedBox(height: 20),
                          pinCard,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: infoCard),
                        const SizedBox(width: 20),
                        Expanded(flex: 6, child: pinCard),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                OpenPgpKeySlotsCard(info: info),
                Spacing.height(20),
                OpenPgpTouchPolicyCard(
                  info: info,
                  onChange: (slot) => OpenPgpTouchPolicyDialog.show(
                    slot: slot,
                    onSubmit: controller.setTouchPolicy,
                  ),
                  onChangeCacheTime: () => OpenPgpTouchCacheTimeDialog.show(
                    currentSeconds: info.touchCacheTime,
                    onSubmit: controller.setTouchCacheTime,
                  ),
                ),
                Spacing.height(20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showChangeUserPin() {
    ChangePinDialog.show(
      title: S.of(context).changePin,
      oldValueLabel: S.of(context).oldPin,
      newValueLabel: S.of(context).newPin,
      prompt: S.of(context).openpgpUserPinLength,
      validators: [LengthValidator(min: 6, max: 64)],
      onSubmit: controller.changeUserPin,
    );
  }

  void _showChangeAdminPin() {
    ChangePinDialog.show(
      title: S.of(context).openpgpChangeAdminPin,
      oldValueLabel: S.of(context).openpgpCurrentAdminPin,
      newValueLabel: S.of(context).openpgpNewAdminPin,
      prompt: S.of(context).openpgpAdminPinLength,
      validators: [LengthValidator(min: 8, max: 64)],
      onSubmit: controller.changeAdminPin,
    );
  }
}
