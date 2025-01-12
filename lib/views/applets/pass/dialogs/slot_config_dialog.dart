import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/form_validator.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SlotConfigDialog extends BaseDialog with UIMixin {
  final int index;
  final PassSlot slot;
  final Function(int index, PassSlotType slotType, String password, bool withEnter) onSetSlot;

  const SlotConfigDialog({super.key, required this.index, required this.slot, required this.onSetSlot});

  static Future<void> show({
    required int index,
    required PassSlot slot,
    required Function(int index, PassSlotType slotType, String password, bool withEnter) onSetSlot,
  }) {
    return Get.dialog(
      SlotConfigDialog(index: index, slot: slot, onSetSlot: onSetSlot),
      barrierDismissible: false,
    );
  }

  @override
  State<SlotConfigDialog> createState() => _SlotConfigDialogState();
}

class _SlotConfigDialogState extends BaseDialogState<SlotConfigDialog> with UIMixin {
  final FormValidator validator = FormValidator();

  late final RxBool showPassword;
  late final RxBool withEnter;
  late final Rx<PassSlotType> slotType;

  @override
  void initState() {
    super.initState();
    showPassword = false.obs;
    withEnter = widget.slot.withEnter.obs;
    slotType = Rx<PassSlotType>(widget.slot.type);
    validator.addField('password', required: true, controller: TextEditingController(), validators: [LengthValidator(min: 1, max: 32)]);
  }

  void _onSubmit() {
    if (slotType.value == PassSlotType.static && !validator.validateForm()) {
      return;
    }
    widget.onSetSlot(widget.index, slotType.value, validator.getController('password')!.text, withEnter.value);
  }

  String _slotTypeName(PassSlotType type) {
    switch (type) {
      case PassSlotType.none:
        return S.of(context).passSlotOff;
      case PassSlotType.oath:
        return S.of(context).passSlotHotp;
      case PassSlotType.static:
        return S.of(context).passSlotStatic;
    }
  }

  Widget _buildRadioOption(PassSlotType type) {
    return InkWell(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<PassSlotType>(
            value: type,
            activeColor: contentTheme.primary,
            groupValue: slotType.value,
            onChanged: (newType) => slotType.value = newType!,
            visualDensity: getCompactDensity,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Spacing.width(8),
          CustomizedText.labelMedium(_slotTypeName(type))
        ],
      ),
    );
  }

  @override
  Widget buildDialogContent() {
    return Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: Spacing.all(16),
            child: CustomizedText.labelLarge(S.of(context).passSlotConfigTitle),
          ),
          Divider(height: 0, thickness: 1),
          Padding(
            padding: Spacing.all(16),
            child: Form(
              key: validator.formKey,
              child: Column(
                children: [
                  CustomizedText.labelLarge(S.of(context).passSlotConfigPrompt),
                  Spacing.height(16),
                  Row(
                    children: [
                      SizedBox(width: 90, child: CustomizedText.labelLarge(S.of(context).oathType)),
                      Expanded(
                        child: Wrap(
                          spacing: 16,
                          children: [
                            _buildRadioOption(PassSlotType.none),
                            _buildRadioOption(PassSlotType.static),
                          ],
                        ),
                      )
                    ],
                  ),
                  if (slotType.value == PassSlotType.static) ...[
                    Spacing.height(16),
                    TextFormField(
                      onTap: SmartCard.eject,
                      obscureText: !showPassword.value,
                      controller: validator.getController('password'),
                      validator: validator.getValidator('password'),
                      decoration: InputDecoration(
                        labelText: S.of(context).passSlotStatic,
                        border: outlineInputBorder,
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        suffixIcon: IconButton(
                          onPressed: () => showPassword.value = !showPassword.value,
                          icon: Icon(showPassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        ),
                      ),
                    ),
                  ],
                  if (slotType.value != PassSlotType.none) ...[
                    Spacing.height(16),
                    Row(
                      children: [
                        Obx(() => Checkbox(
                              onChanged: (value) => withEnter.value = value!,
                              value: withEnter.value,
                              activeColor: contentTheme.primary,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: getCompactDensity,
                            )),
                        Spacing.width(16),
                        CustomizedText.bodyMedium(S.of(context).passSlotWithEnter),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ),
          if (errorMessage.value.isNotEmpty)
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.bodyMedium(errorMessage.value,
                  color: errorLevel.value == 'E' ? ContentThemeColor.danger.color : ContentThemeColor.warning.color),
            ),
          Divider(height: 0, thickness: 1),
          Padding(
            padding: Spacing.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomizedButton.rounded(
                  onPressed: () => Navigator.pop(context),
                  elevation: 0,
                  padding: Spacing.xy(20, 16),
                  backgroundColor: contentTheme.secondary,
                  child: CustomizedText.labelMedium(S.of(context).close, color: contentTheme.onSecondary),
                ),
                Spacing.width(16),
                CustomizedButton.rounded(
                  onPressed: _onSubmit,
                  elevation: 0,
                  padding: Spacing.xy(20, 16),
                  backgroundColor: contentTheme.primary,
                  child: CustomizedText.labelMedium(S.of(context).save, color: contentTheme.onPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
