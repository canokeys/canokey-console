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
import 'package:canokey_console/models/openpgp.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OpenPgpSignaturePinPolicyDialog extends BaseDialog {
  final OpenPgpPinState pinState;
  final Future<void> Function(String adminPin, bool verifyForEverySignature) onSubmit;

  const OpenPgpSignaturePinPolicyDialog({
    super.key,
    required this.pinState,
    required this.onSubmit,
  });

  static Future<void> show({
    required OpenPgpPinState pinState,
    required Future<void> Function(String adminPin, bool verifyForEverySignature) onSubmit,
  }) {
    return AppDialog.show(
      OpenPgpSignaturePinPolicyDialog(
        pinState: pinState,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<OpenPgpSignaturePinPolicyDialog> createState() => _OpenPgpSignaturePinPolicyDialogState();
}

class _OpenPgpSignaturePinPolicyDialogState extends BaseDialogState<OpenPgpSignaturePinPolicyDialog> {
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
  Widget buildDialogContent() {
    return Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: Spacing.all(16),
            child: CustomizedText.labelLarge(
              S.of(context).openpgpChangeSignaturePinPolicy,
            ),
          ),
          Divider(height: 0, thickness: 1),
          Padding(
            padding: Spacing.all(16),
            child: Column(
              children: [
                RadioListTile<bool>(
                  dense: true,
                  value: true,
                  groupValue: _verifyForEverySignature.value,
                  onChanged: (value) => _verifyForEverySignature.value = value ?? true,
                  title: CustomizedText.bodyMedium(
                    S.of(context).openpgpVerifyEverySignaturePrompt,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<bool>(
                  dense: true,
                  value: false,
                  groupValue: _verifyForEverySignature.value,
                  onChanged: (value) => _verifyForEverySignature.value = value ?? false,
                  title: CustomizedText.bodyMedium(
                    S.of(context).openpgpVerifyOnceAfterInsertionPrompt,
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
                    icon: Icon(_showAdminPin.value ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => _showAdminPin.toggle(),
                  ),
                ),
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
