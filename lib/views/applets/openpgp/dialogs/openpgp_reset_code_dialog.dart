import 'package:canokey_console/generated/l10n.dart';
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

class OpenPgpResetCodeDialog extends BaseDialog {
  final Future<void> Function(String adminPin, String resetCode) onSubmit;

  const OpenPgpResetCodeDialog({super.key, required this.onSubmit});

  static Future<void> show({
    required Future<void> Function(String adminPin, String resetCode) onSubmit,
  }) {
    return Get.dialog(
      OpenPgpResetCodeDialog(onSubmit: onSubmit),
      barrierDismissible: false,
    );
  }

  @override
  State<OpenPgpResetCodeDialog> createState() => _OpenPgpResetCodeDialogState();
}

class _OpenPgpResetCodeDialogState
    extends BaseDialogState<OpenPgpResetCodeDialog> {
  final FormValidator _validator = FormValidator();
  final RxBool _showAdminPin = false.obs;
  final RxBool _showResetCode = false.obs;

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
      'reset',
      required: true,
      controller: TextEditingController(),
      validators: [LengthValidator(min: 8, max: 64)],
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
              S.of(context).openpgpSetResetCode,
            ),
          ),
          Divider(height: 0, thickness: 1),
          Padding(
            padding: Spacing.all(16),
            child: CustomizedText.bodyMedium(
              S.of(context).openpgpSetResetCodePrompt,
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
                    name: 'admin',
                    label: S.of(context).openpgpAdminPin,
                    showValue: _showAdminPin,
                  ),
                  Spacing.height(16),
                  _field(
                    name: 'reset',
                    label: S.of(context).openpgpResetCode,
                    showValue: _showResetCode,
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
                color: errorLevel.value == 'E'
                    ? ContentThemeColor.danger.color
                    : ContentThemeColor.warning.color,
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
      autofocus: name == 'admin',
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
    widget.onSubmit(
      _validator.getController('admin')!.text,
      _validator.getController('reset')!.text,
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
