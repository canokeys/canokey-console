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
import 'package:canokey_console/models/openpgp.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OpenPgpPinRetriesDialog extends BaseDialog {
  final OpenPgpPinState pinState;
  final Future<void> Function(String adminPin, int userRetries, int resetRetries, int adminRetries) onSubmit;

  const OpenPgpPinRetriesDialog({
    super.key,
    required this.pinState,
    required this.onSubmit,
  });

  static Future<void> show({
    required OpenPgpPinState pinState,
    required Future<void> Function(String adminPin, int userRetries, int resetRetries, int adminRetries) onSubmit,
  }) {
    return AppDialog.show(
      OpenPgpPinRetriesDialog(pinState: pinState, onSubmit: onSubmit),
    );
  }

  @override
  State<OpenPgpPinRetriesDialog> createState() => _OpenPgpPinRetriesDialogState();
}

class _OpenPgpPinRetriesDialogState extends BaseDialogState<OpenPgpPinRetriesDialog> {
  final FormValidator _validator = FormValidator();
  final RxBool _showAdminPin = false.obs;

  @override
  void initState() {
    super.initState();
    _validator.addField(
      'admin',
      required: true,
      controller: TextEditingController(),
      validators: [LengthValidator(min: 8, max: 64)],
    );
    _validator.addField(
      'user',
      required: true,
      controller: TextEditingController(text: '${widget.pinState.userRetries ?? 3}'),
      validators: [IntValidator(min: 1, max: 15)],
    );
    _validator.addField(
      'reset',
      required: true,
      controller: TextEditingController(text: '${widget.pinState.resetRetries ?? 3}'),
      validators: [IntValidator(min: 1, max: 15)],
    );
    _validator.addField(
      'adminRetries',
      required: true,
      controller: TextEditingController(text: '${widget.pinState.adminRetries ?? 3}'),
      validators: [IntValidator(min: 1, max: 15)],
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
            child: CustomizedText.labelLarge(
              S.of(context).openpgpSetPinRetriesTitle,
            ),
          ),
          Divider(height: 0, thickness: 1),
          Padding(
            padding: Spacing.all(16),
            child: CustomizedText.bodySmall(
              S.of(context).openpgpSetPinRetriesPrompt,
              color: ContentThemeColor.danger.color,
            ),
          ),
          Divider(height: 0, thickness: 1),
          Padding(
            padding: Spacing.all(16),
            child: Form(
              key: _validator.formKey,
              child: Column(
                children: [
                  _adminPinField(),
                  Spacing.height(16),
                  _numberField('user', S.of(context).openpgpUserPin),
                  Spacing.height(16),
                  _numberField('reset', S.of(context).openpgpResetCode),
                  Spacing.height(16),
                  _numberField('adminRetries', S.of(context).openpgpAdminPin),
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

  Widget _adminPinField() {
    return TextFormField(
      autofocus: true,
      onTap: SmartCard.eject,
      obscureText: !_showAdminPin.value,
      controller: _validator.getController('admin'),
      validator: _validator.getValidator('admin'),
      decoration: InputDecoration(
        labelText: S.of(context).openpgpAdminPin,
        border: _outlineInputBorder,
        suffixIcon: IconButton(
          icon: Icon(_showAdminPin.value ? Icons.visibility : Icons.visibility_off),
          onPressed: () => _showAdminPin.toggle(),
        ),
      ),
    );
  }

  Widget _numberField(String name, String label) {
    return TextFormField(
      keyboardType: TextInputType.number,
      controller: _validator.getController(name),
      validator: _validator.getValidator(name),
      decoration: InputDecoration(
        labelText: label,
        border: _outlineInputBorder,
      ),
    );
  }

  void _submit() {
    if (!_validator.validateForm()) {
      return;
    }
    widget.onSubmit(
      _validator.getController('admin')!.text,
      int.parse(_validator.getController('user')!.text),
      int.parse(_validator.getController('reset')!.text),
      int.parse(_validator.getController('adminRetries')!.text),
    );
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
