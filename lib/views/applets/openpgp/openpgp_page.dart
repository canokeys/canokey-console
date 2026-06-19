import 'package:canokey_console/controller/applets/openpgp/openpgp_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
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

  String _t({required String en, required String zh}) {
    return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      title: 'OpenPGP',
      topActions: isWeb() || isIOSApp()
          ? IconButton(
              tooltip: 'Refresh',
              icon:
                  Icon(LucideIcons.refreshCw, color: topBarTheme.onBackground),
              onPressed: controller.refreshData,
            )
          : Container(),
      child: GetBuilder(
        init: controller,
        builder: (_) {
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
                  t: _t,
                ),
                Spacing.height(20),
                OpenPgpCardInfoCard(info: info, t: _t),
                Spacing.height(20),
                OpenPgpKeySlotsCard(info: info),
                Spacing.height(20),
                OpenPgpTouchPolicyCard(
                  info: info,
                  onChange: (slot) => OpenPgpTouchPolicyDialog.show(
                    slot: slot,
                    onSubmit: controller.setTouchPolicy,
                    t: _t,
                  ),
                  onChangeCacheTime: () => OpenPgpTouchCacheTimeDialog.show(
                    currentSeconds: info.touchCacheTime,
                    onSubmit: controller.setTouchCacheTime,
                  ),
                  t: _t,
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
      prompt: _t(
        en: 'User PIN length must be between 6 and 64 characters.',
        zh: 'User PIN 长度必须为 6 到 64 个字符。',
      ),
      validators: [LengthValidator(min: 6, max: 64)],
      onSubmit: controller.changeUserPin,
    );
  }

  void _showChangeAdminPin() {
    ChangePinDialog.show(
      title: S.of(context).openpgpChangeAdminPin,
      oldValueLabel: _t(en: 'Current Admin PIN', zh: '当前 Admin PIN'),
      newValueLabel: _t(en: 'New Admin PIN', zh: '新 Admin PIN'),
      prompt: _t(
        en: 'Admin PIN length must be between 8 and 64 characters.',
        zh: 'Admin PIN 长度必须为 8 到 64 个字符。',
      ),
      validators: [LengthValidator(min: 8, max: 64)],
      onSubmit: controller.changeAdminPin,
    );
  }
}
