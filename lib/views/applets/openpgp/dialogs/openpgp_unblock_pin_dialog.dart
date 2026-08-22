// ignore_for_file: deprecated_member_use

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/form_validator.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OpenPgpUnblockPinDialog extends BaseDialog {
  final Future<void> Function(String adminPin, String newPin) onSubmitWithAdmin;
  final Future<void> Function(String resetCode, String newPin) onSubmitWithResetCode;

  const OpenPgpUnblockPinDialog({
    super.key,
    required this.onSubmitWithAdmin,
    required this.onSubmitWithResetCode,
  });

  static Future<void> show({
    required Future<void> Function(String adminPin, String newPin) onSubmitWithAdmin,
    required Future<void> Function(String resetCode, String newPin) onSubmitWithResetCode,
  }) {
    return AppDialog.show(
      OpenPgpUnblockPinDialog(
        onSubmitWithAdmin: onSubmitWithAdmin,
        onSubmitWithResetCode: onSubmitWithResetCode,
      ),
    );
  }

  @override
  State<OpenPgpUnblockPinDialog> createState() => _OpenPgpUnblockPinDialogState();
}

class _OpenPgpUnblockPinDialogState extends BaseDialogState<OpenPgpUnblockPinDialog> {
  final FormValidator _validator = FormValidator();
  final RxBool _useAdminPin = true.obs;
  final RxBool _showSecret = false.obs;
  final RxBool _showNewPin = false.obs;

  @override
  void initState() {
    super.initState();
    _validator.addField(
      'secret',
      required: true,
      controller: TextEditingController(),
      validators: [LengthValidator(min: 8, max: 64)],
    );
    _validator.addField(
      'new',
      required: true,
      controller: TextEditingController(),
      validators: [LengthValidator(min: 6, max: 64)],
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
            child: CustomizedText.labelLarge(S.of(context).openpgpUnblockUserPin),
          ),
          Divider(height: 0, thickness: 1),
          Padding(
            padding: Spacing.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RadioListTile<bool>(
                  dense: true,
                  value: true,
                  groupValue: _useAdminPin.value,
                  onChanged: (value) => _useAdminPin.value = value!,
                  title: CustomizedText.bodyMedium(
                    S.of(context).openpgpUseAdminPin,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<bool>(
                  dense: true,
                  value: false,
                  groupValue: _useAdminPin.value,
                  onChanged: (value) => _useAdminPin.value = value!,
                  title: CustomizedText.bodyMedium(
                    S.of(context).openpgpUseResetCode,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Divider(height: 0, thickness: 1),
          Padding(
            padding: Spacing.all(16),
            child: Form(
              key: _validator.formKey,
              child: Column(
                children: [
                  _field(
                    name: 'secret',
                    label: _useAdminPin.value ? S.of(context).openpgpAdminPin : S.of(context).openpgpResetCode,
                    showValue: _showSecret,
                  ),
                  Spacing.height(16),
                  _field(
                    name: 'new',
                    label: S.of(context).newPin,
                    showValue: _showNewPin,
                  ),
                ],
              ),
            ),
          ),
          if (errorMessage.value.isNotEmpty)
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.bodyMedium(
                errorMessage.value,
                color: errorLevel.value == 'E' ? ContentThemeColor.danger.color : ContentThemeColor.warning.color,
              ),
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
                  backgroundColor: ContentThemeColor.secondary.color,
                  child: CustomizedText.labelMedium(
                    S.of(context).cancel,
                    color: ContentThemeColor.secondary.onColor,
                  ),
                ),
                Spacing.width(16),
                CustomizedButton.rounded(
                  onPressed: _submit,
                  elevation: 0,
                  padding: Spacing.xy(20, 16),
                  backgroundColor: ContentThemeColor.primary.color,
                  child: CustomizedText.labelMedium(
                    S.of(context).confirm,
                    color: ContentThemeColor.primary.onColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String name,
    required String label,
    required RxBool showValue,
  }) {
    return TextFormField(
      autofocus: name == 'secret',
      onTap: SmartCard.eject,
      obscureText: !showValue.value,
      controller: _validator.getController(name),
      validator: _validator.getValidator(name),
      decoration: InputDecoration(
        labelText: label,
        border: _outlineInputBorder,
        suffixIcon: IconButton(
          icon: Icon(showValue.value ? Icons.visibility : Icons.visibility_off),
          onPressed: () => showValue.toggle(),
        ),
      ),
    );
  }

  void _submit() {
    if (!_validator.validateForm()) {
      return;
    }
    final secret = _validator.getController('secret')!.text;
    final newPin = _validator.getController('new')!.text;
    if (_useAdminPin.value) {
      widget.onSubmitWithAdmin(secret, newPin);
    } else {
      widget.onSubmitWithResetCode(secret, newPin);
    }
  }

  final _outlineInputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(4)),
    borderSide: BorderSide(
      width: 1,
      strokeAlign: 0,
      color: AppTheme.theme.colorScheme.onSurface.withAlpha(80),
    ),
  );
}
