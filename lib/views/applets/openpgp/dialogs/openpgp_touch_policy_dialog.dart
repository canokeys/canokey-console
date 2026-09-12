// ignore_for_file: deprecated_member_use

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/form_validator.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OpenPgpTouchPolicyDialog extends BaseDialog {
  final OpenPgpKeySlotInfo slot;
  final Future<void> Function(
    OpenPgpKeyType keyType,
    OpenPgpTouchPolicy policy,
    String adminPin,
  )
  onSubmit;

  const OpenPgpTouchPolicyDialog({
    super.key,
    required this.slot,
    required this.onSubmit,
  });

  static Future<void> show({
    required OpenPgpKeySlotInfo slot,
    required Future<void> Function(
      OpenPgpKeyType keyType,
      OpenPgpTouchPolicy policy,
      String adminPin,
    )
    onSubmit,
  }) {
    return AppDialog.show(
      OpenPgpTouchPolicyDialog(slot: slot, onSubmit: onSubmit),
    );
  }

  @override
  State<OpenPgpTouchPolicyDialog> createState() =>
      _OpenPgpTouchPolicyDialogState();
}

class _OpenPgpTouchPolicyDialogState
    extends BaseDialogState<OpenPgpTouchPolicyDialog> {
  final FormValidator _validator = FormValidator();
  final Rx<OpenPgpTouchPolicy> _policy = OpenPgpTouchPolicy.off.obs;
  final RxBool _showAdminPin = false.obs;
  final RxBool _permanentConfirmed = false.obs;

  @override
  void initState() {
    super.initState();
    _policy.value = widget.slot.touchPolicy;
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
      title: S.of(context).openpgpChangeInteraction(widget.slot.type.label),
      description: Column(
        children: [
          for (final value in OpenPgpTouchPolicy.writableValues)
            RadioListTile<OpenPgpTouchPolicy>(
              dense: true,
              value: value,
              groupValue: _policy.value,
              onChanged: (newValue) {
                _policy.value = newValue!;
                if (newValue != OpenPgpTouchPolicy.permanent) {
                  _permanentConfirmed.value = false;
                }
              },
              title: CustomizedText.bodyMedium(value.label),
              contentPadding: EdgeInsets.zero,
            ),
          if (_policy.value == OpenPgpTouchPolicy.permanent)
            CheckboxListTile(
              dense: true,
              value: _permanentConfirmed.value,
              onChanged: (value) => _permanentConfirmed.value = value ?? false,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: CustomizedText.bodyMedium(
                S.of(context).openpgpPermanentTouchConfirmation,
                color: ContentThemeColor.warning.color,
              ),
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
      onSubmit: _canSubmit ? _submit : null,
    ),
  );

  bool get _canSubmit =>
      _policy.value != OpenPgpTouchPolicy.permanent ||
      _permanentConfirmed.value;

  void _submit() {
    if (!_validator.validateForm()) {
      return;
    }
    widget.onSubmit(
      widget.slot.type,
      _policy.value,
      _validator.getController('admin')!.text,
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
