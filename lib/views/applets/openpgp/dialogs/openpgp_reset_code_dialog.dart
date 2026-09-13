import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
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
    return AppDialog.show(OpenPgpResetCodeDialog(onSubmit: onSubmit));
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
  Widget buildDialogContent() => Obx(
    () => buildFormContent(
      title: S.of(context).openpgpSetResetCode,
      description: CustomizedText.bodyMedium(
        S.of(context).openpgpSetResetCodePrompt,
      ),
      form: Form(
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
      onSubmit: _submit,
    ),
  );

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
