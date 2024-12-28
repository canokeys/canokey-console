import 'dart:convert';

import 'package:base32/base32.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/form_validator.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddAccountDialog extends StatelessWidget with UIMixin {
  static const _kDialogWidth = 400.0;
  static const _kPadding = 16.0;
  static const _kLabelWidth = 90.0;
  static const _kValidDigits = [6, 7, 8];

  final Function(String name, String secretHex, OathType type, OathAlgorithm algo, int digits, bool touch, int initValue) onAddAccount;
  final String? initialIssuer;
  final String? initialAccount;
  final String? initialSecret;
  final int? initialCounter;
  final OathType? initialType;
  final OathAlgorithm? initialAlgorithm;
  final int? initialDigits;

  const AddAccountDialog({
    super.key,
    required this.onAddAccount,
    this.initialIssuer,
    this.initialAccount,
    this.initialSecret,
    this.initialCounter,
    this.initialType,
    this.initialAlgorithm,
    this.initialDigits,
  });

  static Future<void> show(
    Function(String name, String secretHex, OathType type, OathAlgorithm algo, int digits, bool touch, int initValue) onAddAccount, {
    String? initialIssuer,
    String? initialAccount,
    String? initialSecret,
    int? initialCounter,
    OathType? initialType,
    OathAlgorithm? initialAlgorithm,
    int? initialDigits,
  }) {
    return Get.dialog(
      AddAccountDialog(
        onAddAccount: onAddAccount,
        initialIssuer: initialIssuer,
        initialAccount: initialAccount,
        initialSecret: initialSecret,
        initialCounter: initialCounter,
        initialType: initialType,
        initialAlgorithm: initialAlgorithm,
        initialDigits: initialDigits,
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final formData = _OathFormData.initialize(
      initialIssuer: initialIssuer,
      initialAccount: initialAccount,
      initialSecret: initialSecret,
      initialCounter: initialCounter,
      initialType: initialType,
      initialAlgorithm: initialAlgorithm,
      initialDigits: initialDigits,
    );

    return Dialog(
      child: SizedBox(
        width: _kDialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const Divider(height: 0, thickness: 1),
              _buildForm(context, formData),
              const Divider(height: 0, thickness: 1),
              _buildActions(context, formData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(_kPadding),
      child: CustomizedText.labelLarge(S.of(context).oathAddAccount),
    );
  }

  Widget _buildForm(BuildContext context, _OathFormData formData) {
    return Padding(
      padding: const EdgeInsets.all(_kPadding),
      child: Form(
        key: formData.validator.formKey,
        child: Obx(
          () => Column(
            children: [
              _buildBasicFields(context, formData),
              _buildTouchRequirement(context, formData),
              _buildAdvancedSettings(context, formData),
              if (formData.oathType.value == OathType.hotp) _buildHotpCounter(context, formData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicFields(BuildContext context, _OathFormData formData) {
    return Column(
      children: [
        _buildTextField(
          context: context,
          label: S.of(context).oathIssuer,
          fieldName: 'issuer',
          validator: formData.validator,
          autofocus: true,
        ),
        Spacing.height(_kPadding),
        _buildTextField(
          context: context,
          label: S.of(context).oathAccount,
          fieldName: 'account',
          validator: formData.validator,
        ),
        Spacing.height(_kPadding),
        _buildTextField(
          context: context,
          label: S.of(context).oathSecret,
          fieldName: 'secret',
          validator: formData.validator,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required String fieldName,
    required FormValidator validator,
    bool autofocus = false,
  }) {
    return TextFormField(
      onTap: SmartCard.eject,
      autofocus: autofocus,
      controller: validator.getController(fieldName),
      validator: validator.getValidator(fieldName),
      decoration: InputDecoration(
        labelText: label,
        border: outlineInputBorder,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );
  }

  Widget _buildTouchRequirement(BuildContext context, _OathFormData formData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _kPadding),
      child: Row(
        children: [
          Checkbox(
            onChanged: (value) => formData.requireTouch.value = value!,
            value: formData.requireTouch.value,
            activeColor: contentTheme.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: getCompactDensity,
          ),
          Spacing.width(_kPadding),
          CustomizedText.bodyMedium(S.of(context).oathRequireTouch),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings(BuildContext context, _OathFormData formData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomizedText.bodyMedium(S.of(context).oathAdvancedSettings),
        Spacing.height(12),
        _buildTypeSelector(context, formData),
        Spacing.height(12),
        _buildAlgorithmSelector(context, formData),
        Spacing.height(12),
        _buildDigitsSelector(context, formData),
      ],
    );
  }

  Widget _buildTypeSelector(BuildContext context, _OathFormData formData) {
    return _buildOptionRow(
      context,
      label: S.of(context).oathType,
      child: Wrap(
        spacing: _kPadding,
        children: OathType.values
            .map((type) => _buildRadioOption(
                  value: type,
                  groupValue: formData.oathType.value,
                  onChanged: (type) => formData.oathType.value = type!,
                  label: type.name.toUpperCase(),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildAlgorithmSelector(BuildContext context, _OathFormData formData) {
    return _buildOptionRow(
      context,
      label: S.of(context).oathAlgorithm,
      child: Wrap(
        spacing: _kPadding,
        children: OathAlgorithm.values
            .map((algo) => _buildRadioOption(
                  value: algo,
                  groupValue: formData.oathAlgorithm.value,
                  onChanged: (algo) => formData.oathAlgorithm.value = algo!,
                  label: algo.name.toUpperCase(),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDigitsSelector(BuildContext context, _OathFormData formData) {
    return _buildOptionRow(
      context,
      label: S.of(context).oathDigits,
      child: Wrap(
        spacing: _kPadding,
        children: _kValidDigits
            .map((digits) => _buildRadioOption(
                  value: digits,
                  groupValue: formData.oathDigits.value,
                  onChanged: (digits) => formData.oathDigits.value = digits!,
                  label: digits.toString(),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildOptionRow(BuildContext context, {required String label, required Widget child}) {
    return Row(
      children: [
        SizedBox(
          width: _kLabelWidth,
          child: CustomizedText.labelLarge(label),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildRadioOption<T>({
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
    required String label,
  }) {
    return InkWell(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<T>(
            value: value,
            activeColor: contentTheme.primary,
            groupValue: groupValue,
            onChanged: onChanged,
            visualDensity: getCompactDensity,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Spacing.width(8),
          CustomizedText.labelMedium(label),
        ],
      ),
    );
  }

  Widget _buildHotpCounter(BuildContext context, _OathFormData formData) {
    return Padding(
      padding: const EdgeInsets.only(top: _kPadding),
      child: _buildTextField(
        context: context,
        label: S.of(context).oathCounter,
        fieldName: 'counter',
        validator: formData.validator,
      ),
    );
  }

  Widget _buildActions(BuildContext context, _OathFormData formData) {
    return Padding(
      padding: const EdgeInsets.all(_kPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CustomizedButton.rounded(
            onPressed: () => Navigator.pop(context),
            elevation: 0,
            padding: Spacing.xy(20, _kPadding),
            backgroundColor: contentTheme.secondary,
            child: CustomizedText.labelMedium(
              S.of(context).close,
              color: contentTheme.onSecondary,
            ),
          ),
          Spacing.width(_kPadding),
          CustomizedButton.rounded(
            onPressed: () => _handleSave(context, formData),
            elevation: 0,
            padding: Spacing.xy(20, _kPadding),
            backgroundColor: contentTheme.primary,
            child: CustomizedText.labelMedium(
              S.of(context).save,
              color: contentTheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _handleSave(BuildContext context, _OathFormData formData) {
    if (!formData.validator.validateForm(clear: true)) {
      return;
    }

    final data = formData.validator.getData();
    final issuer = data['issuer'];
    final account = data['account'];
    final secret = data['secret'];
    final initValue = int.parse(data['counter']);
    final name = '$issuer:$account';

    if (utf8.encode(name).length > 63) {
      formData.validator.addError('account', S.of(context).oathTooLong);
      formData.validator.formKey.currentState!.validate();
      return;
    }

    String secretHex;
    try {
      secretHex = base32.decodeAsHexString(secret.toUpperCase());
    } catch (e) {
      formData.validator.addError('secret', S.of(Get.context!).oathInvalidKey);
      formData.validator.formKey.currentState!.validate();
      return;
    }

    onAddAccount(name, secretHex, formData.oathType.value, formData.oathAlgorithm.value, formData.oathDigits.value, formData.requireTouch.value, initValue);
  }
}

class _OathFormData {
  final FormValidator validator;
  final RxBool requireTouch;
  final Rx<OathType> oathType;
  final Rx<OathAlgorithm> oathAlgorithm;
  final RxInt oathDigits;

  _OathFormData({
    required this.validator,
    required this.requireTouch,
    required this.oathType,
    required this.oathAlgorithm,
    required this.oathDigits,
  });

  static _OathFormData initialize({
    String? initialIssuer,
    String? initialAccount,
    String? initialSecret,
    int? initialCounter,
    OathType? initialType,
    OathAlgorithm? initialAlgorithm,
    int? initialDigits,
  }) {
    final validator = FormValidator();
    validator.addField('issuer', required: true, controller: TextEditingController(text: initialIssuer));
    validator.addField('account', required: true, controller: TextEditingController(text: initialAccount));
    validator.addField('secret', required: true, controller: TextEditingController(text: initialSecret), validators: [LengthValidator(min: 8, max: 103)]);
    validator.addField(
      'counter',
      required: true,
      controller: TextEditingController(text: initialCounter?.toString() ?? '0'),
      validators: [IntValidator(min: 0, max: 4294967295)],
    );

    return _OathFormData(
      validator: validator,
      requireTouch: false.obs,
      oathType: (initialType ?? OathType.totp).obs,
      oathAlgorithm: (initialAlgorithm ?? OathAlgorithm.sha1).obs,
      oathDigits: (initialDigits ?? 6).obs,
    );
  }
}
