import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/form_validator.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SlotConfigDialog extends BaseDialog with UIMixin {
  @override
  double get contentWidth => AppDialogWidth.medium;

  final int index;
  final PassSlot slot;
  final bool hmacSha1Supported;
  final Function(
    int index,
    PassSlotType slotType,
    String password,
    bool withEnter,
  )
  onSetSlot;

  const SlotConfigDialog({
    super.key,
    required this.index,
    required this.slot,
    required this.hmacSha1Supported,
    required this.onSetSlot,
  });

  static Future<void> show({
    required int index,
    required PassSlot slot,
    required bool hmacSha1Supported,
    required Function(
      int index,
      PassSlotType slotType,
      String password,
      bool withEnter,
    )
    onSetSlot,
  }) {
    return AppDialog.show(
      SlotConfigDialog(
        index: index,
        slot: slot,
        hmacSha1Supported: hmacSha1Supported,
        onSetSlot: onSetSlot,
      ),
    );
  }

  @override
  State<SlotConfigDialog> createState() => _SlotConfigDialogState();
}

class _SlotConfigDialogState extends BaseDialogState<SlotConfigDialog>
    with UIMixin {
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
    validator.addField(
      'password',
      required: true,
      controller: TextEditingController(),
      validators: [LengthValidator(min: 1, max: 32)],
    );
    validator.addField(
      'hmacKey',
      required: true,
      controller: TextEditingController(),
      validators: [LengthValidator(exact: 40), HexStringValidator()],
    );
  }

  void _onSubmit() {
    if (slotType.value == PassSlotType.static && !validator.validateForm()) {
      return;
    }
    if (slotType.value == PassSlotType.hmacSha1) {
      final hmacKey = validator.getController('hmacKey')!.text.trim();
      if (!RegExp(r'^[0-9a-fA-F]{40}$').hasMatch(hmacKey)) {
        validator.formKey.currentState?.validate();
        return;
      }
      widget.onSetSlot(
        widget.index,
        slotType.value,
        hmacKey.toLowerCase(),
        false,
      );
      return;
    }
    widget.onSetSlot(
      widget.index,
      slotType.value,
      validator.getController('password')!.text,
      withEnter.value,
    );
  }

  String _slotTypeName(PassSlotType type) {
    switch (type) {
      case PassSlotType.none:
        return S.of(context).passSlotOff;
      case PassSlotType.oath:
        return S.of(context).passSlotHotp;
      case PassSlotType.static:
        return S.of(context).passSlotStatic;
      case PassSlotType.hmacSha1:
        return S.of(context).passSlotHmacSha1;
    }
  }

  @override
  void dispose() {
    validator.getController('password')?.dispose();
    validator.getController('hmacKey')?.dispose();
    super.dispose();
  }

  static const _accent = Color(0xff009b83);

  Widget _buildRadioOption(PassSlotType type) => RadioListTile<PassSlotType>(
    value: type,
    activeColor: _accent,
    contentPadding: EdgeInsets.zero,
    title: CustomizedText.bodyMedium(
      _slotTypeName(type),
      fontSize: 15,
      color: Theme.of(context).colorScheme.onSurface,
    ),
    dense: true,
  );

  @override
  Widget buildDialogContent() {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final border = dark ? const Color(0xff35414c) : const Color(0xffe5edf2);
    return Material(
      color: dark ? const Color(0xff202b34) : Colors.white,
      child: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppDialogHeader(title: S.of(context).passSlotConfigTitle),
            Divider(height: 1, thickness: 1, color: border),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Form(
                key: validator.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            LucideIcons.info,
                            color: _accent,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomizedText.bodyMedium(
                              S.of(context).passSlotConfigPrompt,
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final options = RadioGroup<PassSlotType>(
                          groupValue: slotType.value,
                          onChanged: (value) {
                            if (value != null) slotType.value = value;
                          },
                          child: Column(
                            children: [
                              _buildRadioOption(PassSlotType.none),
                              _buildRadioOption(PassSlotType.static),
                              if (widget.hmacSha1Supported)
                                _buildRadioOption(PassSlotType.hmacSha1),
                            ],
                          ),
                        );
                        final label = CustomizedText.bodyLarge(
                          S.of(context).oathType,
                          color: colors.onSurface,
                        );
                        if (constraints.maxWidth < 330 ||
                            MediaQuery.textScalerOf(context).scale(14) > 20) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label,
                              const SizedBox(height: 8),
                              options,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 90,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: label,
                              ),
                            ),
                            Expanded(child: options),
                          ],
                        );
                      },
                    ),
                    if (slotType.value == PassSlotType.static) ...[
                      const SizedBox(height: 18),
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
                            onPressed: () =>
                                showPassword.value = !showPassword.value,
                            icon: Icon(
                              showPassword.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (slotType.value == PassSlotType.hmacSha1) ...[
                      const SizedBox(height: 18),
                      TextFormField(
                        onTap: SmartCard.eject,
                        controller: validator.getController('hmacKey'),
                        validator: validator.getValidator('hmacKey'),
                        decoration: InputDecoration(
                          labelText: S.of(context).passSlotHmacSha1Key,
                          border: outlineInputBorder,
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                      ),
                    ],
                    if (slotType.value != PassSlotType.none &&
                        slotType.value != PassSlotType.hmacSha1) ...[
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: withEnter.value,
                        onChanged: (value) {
                          if (value != null) withEnter.value = value;
                        },
                        activeColor: _accent,
                        title: CustomizedText.bodyMedium(
                          S.of(context).passSlotWithEnter,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (errorMessage.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                child: CustomizedText.bodyMedium(
                  errorMessage.value,
                  color: errorLevel.value == 'E'
                      ? ContentThemeColor.danger.color
                      : ContentThemeColor.warning.color,
                ),
              ),
            Divider(height: 1, thickness: 1, color: border),
            AppDialogActions(
              children: [
                AppDialogAction(
                  label: S.of(context).cancel,
                  secondary: true,
                  onPressed: () => Navigator.pop(context),
                ),
                AppDialogAction(
                  label: S.of(context).save,
                  onPressed: _onSubmit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
