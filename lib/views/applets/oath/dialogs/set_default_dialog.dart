import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_container.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SetDefaultDialog extends StatelessWidget with UIMixin {
  static const double _dialogWidth = 400;
  static const double _contentPadding = 16;
  static const double _slotLabelWidth = 80;
  static const double _iconSize = 22;

  final String name;
  final Function(int slot, bool withEnter) onSetDefault;

  const SetDefaultDialog({super.key, required this.name, required this.onSetDefault});

  static Future<void> show({required String name, required Function(int slot, bool withEnter) onSetDefault}) {
    return Get.dialog(SetDefaultDialog(name: name, onSetDefault: onSetDefault));
  }

  @override
  Widget build(BuildContext context) {
    final slot = 1.obs;
    final withEnter = false.obs;

    return Dialog(
      child: SizedBox(
        width: _dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogHeader(context),
            const Divider(height: 0, thickness: 1),
            _buildDialogContent(context, slot, withEnter),
            const Divider(height: 0, thickness: 1),
            _buildDialogActions(context, slot, withEnter),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context) {
    return Padding(
      padding: Spacing.all(_contentPadding),
      child: CustomizedText.labelLarge(S.of(context).oathSetDefault),
    );
  }

  Widget _buildDialogContent(BuildContext context, RxInt slot, RxBool withEnter) {
    return Padding(
      padding: Spacing.all(_contentPadding),
      child: Obx(
        () => Column(
          children: [
            CustomizedText.labelLarge(S.of(context).oathSetDefaultPrompt(name)),
            Spacing.height(_contentPadding),
            _buildSlotSelector(context, slot),
            Spacing.height(_contentPadding),
            _buildEnterCheckbox(context, withEnter),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotSelector(BuildContext context, RxInt slot) {
    return Row(
      children: [
        SizedBox(
          width: _slotLabelWidth,
          child: CustomizedText.labelLarge(S.of(context).oathSlot),
        ),
        _buildSlotPopupMenu(context, slot),
      ],
    );
  }

  Widget _buildSlotPopupMenu(BuildContext context, RxInt slot) {
    return PopupMenuButton(
      itemBuilder: (context) => [
        _buildPopupMenuItem(context, S.of(context).passSlotShort, () => slot.value = 1),
        _buildPopupMenuItem(context, S.of(context).passSlotLong, () => slot.value = 2),
      ],
      child: CustomizedContainer.bordered(
        padding: Spacing.xy(12, 8),
        child: Row(
          children: <Widget>[
            CustomizedText.labelMedium(
              slot.value == 1 ? S.of(context).passSlotShort : S.of(context).passSlotLong,
              color: contentTheme.onBackground,
            ),
            Container(
              margin: const EdgeInsets.only(left: 4),
              child: Icon(
                Icons.expand_more_outlined,
                size: _iconSize,
                color: contentTheme.onBackground,
              ),
            )
          ],
        ),
      ),
    );
  }

  PopupMenuItem _buildPopupMenuItem(BuildContext context, String text, VoidCallback onTap) {
    return PopupMenuItem(
      padding: Spacing.xy(_contentPadding, 8),
      height: 10,
      onTap: onTap,
      child: CustomizedText.bodySmall(text),
    );
  }

  Widget _buildEnterCheckbox(BuildContext context, RxBool withEnter) {
    return Row(
      children: [
        Checkbox(
          onChanged: (value) => withEnter.value = value!,
          value: withEnter.value,
          activeColor: contentTheme.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: getCompactDensity,
        ),
        Spacing.width(_contentPadding),
        CustomizedText.bodyMedium(S.of(context).passSlotWithEnter),
      ],
    );
  }

  Widget _buildDialogActions(BuildContext context, RxInt slot, RxBool withEnter) {
    return Padding(
      padding: Spacing.all(_contentPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildCancelButton(context),
          Spacing.width(_contentPadding),
          _buildSaveButton(context, slot, withEnter),
        ],
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return CustomizedButton.rounded(
      onPressed: () => Navigator.pop(context),
      elevation: 0,
      padding: Spacing.xy(20, _contentPadding),
      backgroundColor: contentTheme.secondary,
      child: CustomizedText.labelMedium(
        S.of(context).cancel,
        color: contentTheme.onSecondary,
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, RxInt slot, RxBool withEnter) {
    return CustomizedButton.rounded(
      onPressed: () => onSetDefault(slot.value, withEnter.value),
      elevation: 0,
      padding: Spacing.xy(20, _contentPadding),
      backgroundColor: contentTheme.primary,
      child: CustomizedText.labelMedium(
        S.of(context).save,
        color: contentTheme.onPrimary,
      ),
    );
  }
}
