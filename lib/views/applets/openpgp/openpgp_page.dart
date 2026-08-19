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
    return Layout(
      title: 'OpenPGP',
      topActions: isWeb() || isIOSApp()
          ? IconButton(
              tooltip: S.of(context).refresh,
              icon:
                  Icon(LucideIcons.refreshCw, color: topBarTheme.onBackground),
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
            padding: Spacing.x(flexSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Spacing.height(20),
                OpenPgpPinManagementCard(
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
                ),
                Spacing.height(20),
                OpenPgpCardInfoCard(info: info),
                Spacing.height(20),
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
