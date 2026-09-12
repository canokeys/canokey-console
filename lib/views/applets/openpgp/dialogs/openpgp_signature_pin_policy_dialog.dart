// ignore_for_file: deprecated_member_use

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/form_validator.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OpenPgpSignaturePinPolicyDialog extends BaseDialog {
  final OpenPgpPinState pinState;
  final Future<void> Function(String adminPin, bool verifyForEverySignature)
  onSubmit;

  const OpenPgpSignaturePinPolicyDialog({
    super.key,
    required this.pinState,
    required this.onSubmit,
  });

  static Future<void> show({
    required OpenPgpPinState pinState,
    required Future<void> Function(
      String adminPin,
      bool verifyForEverySignature,
    )
    onSubmit,
  }) {
    return AppDialog.show(
      OpenPgpSignaturePinPolicyDialog(pinState: pinState, onSubmit: onSubmit),
    );
  }

  @override
  State<OpenPgpSignaturePinPolicyDialog> createState() =>
      _OpenPgpSignaturePinPolicyDialogState();
}

class _OpenPgpSignaturePinPolicyDialogState
    extends BaseDialogState<OpenPgpSignaturePinPolicyDialog> {
  final FormValidator _validator = FormValidator();
  final RxBool _showAdminPin = false.obs;
  late final RxBool _verifyForEverySignature;

  @override
  void initState() {
    super.initState();
    _verifyForEverySignature = widget.pinState.signaturePinForced.obs;
    _validator.addField(
      'admin',
      required: true,
      controller: TextEditingController(),
      validators: [LengthValidator(min: 8, max: 64)],
    );
  }

  @override
  Widget buildDialogContent() => Obx(
    () => buildFormContent(
      title: S.of(context).openpgpChangeSignaturePinPolicy,
      description: Column(
        children: [
          RadioListTile<bool>(
            dense: true,
            value: true,
            groupValue: _verifyForEverySignature.value,
            onChanged: (value) =>
                _verifyForEverySignature.value = value ?? true,
            title: CustomizedText.bodyMedium(
              S.of(context).openpgpVerifyEverySignaturePrompt,
            ),
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<bool>(
            dense: true,
            value: false,
            groupValue: _verifyForEverySignature.value,
            onChanged: (value) =>
                _verifyForEverySignature.value = value ?? false,
            title: CustomizedText.bodyMedium(
              S.of(context).openpgpVerifyOnceAfterInsertionPrompt,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      form: Form(
        key: _validator.formKey,
        child: TextFormField(
          autofocus: true,
          onTap: SmartCard.eject,
          obscureText: !_showAdminPin.value,
          controller: _validator.getController('admin'),
          validator: _validator.getValidator('admin'),
          decoration: InputDecoration(
            labelText: S.of(context).openpgpAdminPin,
            border: _outlineInputBorder,
            suffixIcon: IconButton(
              icon: Icon(
                _showAdminPin.value ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () => _showAdminPin.toggle(),
            ),
          ),
        ),
      ),
      onSubmit: _submit,
    ),
  );

  void _submit() {
    if (!_validator.validateForm()) {
      return;
    }
    widget.onSubmit(
      _validator.getController('admin')!.text,
      _verifyForEverySignature.value,
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
