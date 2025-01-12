import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_container.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SetDefaultDialog extends BaseDialog with UIMixin {
  final String name;
  final Function(int slot, bool withEnter) onSetDefault;

  const SetDefaultDialog({super.key, required this.name, required this.onSetDefault});

  static Future<void> show({required String name, required Function(int slot, bool withEnter) onSetDefault}) {
    return Get.dialog(SetDefaultDialog(name: name, onSetDefault: onSetDefault), barrierDismissible: false);
  }

  @override
  State<SetDefaultDialog> createState() => _SetDefaultDialogState();
}

class _SetDefaultDialogState extends BaseDialogState<SetDefaultDialog> with UIMixin {
  static const double _contentPadding = 16;
  static const double _slotLabelWidth = 80;
  static const double _iconSize = 22;

  final slot = 1.obs;
  final withEnter = false.obs;

  Widget _buildSlotSelector() {
    return Row(
      children: [
        SizedBox(
          width: _slotLabelWidth,
          child: CustomizedText.labelLarge(S.of(context).oathSlot),
        ),
        _buildSlotPopupMenu(),
      ],
    );
  }

  Widget _buildSlotPopupMenu() {
    return PopupMenuButton(
      itemBuilder: (context) => [
        _buildPopupMenuItem(S.of(context).passSlotShort, () => slot.value = 1),
        _buildPopupMenuItem(S.of(context).passSlotLong, () => slot.value = 2),
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

  PopupMenuItem _buildPopupMenuItem(String text, VoidCallback onTap) {
    return PopupMenuItem(
      padding: Spacing.xy(_contentPadding, 8),
      height: 10,
      onTap: onTap,
      child: CustomizedText.bodySmall(text),
    );
  }

  Widget _buildEnterCheckbox() {
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

  @override
  Widget buildDialogContent() {
    return SingleChildScrollView(
      child: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(_contentPadding),
              child: CustomizedText.labelLarge(S.of(context).oathSetDefault),
            ),
            const Divider(height: 0, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(_contentPadding),
              child: Column(
                children: [
                  CustomizedText.labelLarge(S.of(context).oathSetDefaultPrompt(widget.name)),
                  Spacing.height(_contentPadding),
                  _buildSlotSelector(),
                  Spacing.height(_contentPadding),
                  _buildEnterCheckbox(),
                ],
              ),
            ),
            if (errorMessage.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(_contentPadding),
                child: CustomizedText.bodyMedium(errorMessage.value,
                    color: errorLevel.value == 'E' ? ContentThemeColor.danger.color : ContentThemeColor.warning.color),
              ),
            const Divider(height: 0, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(_contentPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomizedButton.rounded(
                    onPressed: () => Navigator.pop(context),
                    elevation: 0,
                    padding: Spacing.xy(20, _contentPadding),
                    backgroundColor: contentTheme.secondary,
                    child: CustomizedText.labelMedium(
                      S.of(context).cancel,
                      color: contentTheme.onSecondary,
                    ),
                  ),
                  Spacing.width(_contentPadding),
                  CustomizedButton.rounded(
                    onPressed: () => widget.onSetDefault(slot.value, withEnter.value),
                    elevation: 0,
                    padding: Spacing.xy(20, _contentPadding),
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium(
                      S.of(context).save,
                      color: contentTheme.onPrimary,
                    ),
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
