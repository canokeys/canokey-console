import 'dart:convert';

import 'package:base32/base32.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/form_validator.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddAccountDialog extends BaseDialog with UIMixin {
  final Function(
    String name,
    String secretHex,
    OathType type,
    OathAlgorithm algo,
    int digits,
    bool touch,
    int initValue,
  )
  onAddAccount;
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

  @override
  bool get managesOwnScrolling => true;

  static Future<void> show(
    Function(
      String name,
      String secretHex,
      OathType type,
      OathAlgorithm algo,
      int digits,
      bool touch,
      int initValue,
    )
    onAddAccount, {
    String? initialIssuer,
    String? initialAccount,
    String? initialSecret,
    int? initialCounter,
    OathType? initialType,
    OathAlgorithm? initialAlgorithm,
    int? initialDigits,
  }) {
    return AppDialog.show(
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
    );
  }

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends BaseDialogState<AddAccountDialog>
    with UIMixin {
  static const _kPadding = 24.0;
  static const _kValidDigits = [6, 7, 8];
  static const _kLabelWidth = 90.0;

  late final _OathFormData formData;

  @override
  void initState() {
    super.initState();
    formData = _OathFormData.initialize(
      initialIssuer: widget.initialIssuer,
      initialAccount: widget.initialAccount,
      initialSecret: widget.initialSecret,
      initialCounter: widget.initialCounter,
      initialType: widget.initialType,
      initialAlgorithm: widget.initialAlgorithm,
      initialDigits: widget.initialDigits,
    );
  }

  Future<void> _handleSave() async {
    if (!formData.validator.validateForm(clear: true)) {
      return;
    }

    final data = formData.validator.getData();
    final issuer = data['issuer'].trim();
    final account = data['account'].trim();
    final secret = data['secret'].trim();
    final initValue = int.parse(data['counter']);
    final name = '$issuer:$account';

    if (utf8.encode(name).length > 63) {
      formData.validator.addError('account', S.of(context).oathTooLong);
      formData.validator.formKey.currentState!.validate();
      return;
    }

    String secretHex;
    try {
      secretHex = _decodeSecret(secret, issuer);
    } catch (e) {
      formData.validator.addError('secret', S.of(Get.context!).oathInvalidKey);
      formData.validator.formKey.currentState!.validate();
      return;
    }

    await widget.onAddAccount(
      name,
      secretHex,
      formData.oathType.value,
      formData.oathAlgorithm.value,
      formData.oathDigits.value,
      formData.requireTouch.value,
      initValue,
    );
  }

  String _decodeSecret(String secret, String issuer) {
    try {
      return base32.decodeAsHexString(secret.toUpperCase());
    } catch (_) {
      if (OathCodeFormat.fromIssuer(issuer) != OathCodeFormat.steam) {
        rethrow;
      }
      return hex.encode(base64.decode(secret));
    }
  }

  Widget _buildBasicFields() {
    return Column(
      children: [
        _buildTextField(
          label: S.of(context).oathIssuer,
          fieldName: 'issuer',
          autofocus: true,
        ),
        Spacing.height(_kPadding),
        _buildTextField(label: S.of(context).oathAccount, fieldName: 'account'),
        Spacing.height(_kPadding),
        _buildTextField(label: S.of(context).oathSecret, fieldName: 'secret'),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String fieldName,
    bool autofocus = false,
  }) {
    return TextFormField(
      onTap: SmartCard.eject,
      autofocus: autofocus,
      controller: formData.validator.getController(fieldName),
      validator: formData.validator.getValidator(fieldName),
      decoration: InputDecoration(
        labelText: label,
        border: outlineInputBorder,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );
  }

  Widget _buildTouchRequirement() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _kPadding),
      child: Obx(
        () => AppDialogCheckbox(
          value: formData.requireTouch.value,
          onChanged: (value) => formData.requireTouch.value = value!,
          title: CustomizedText.bodyMedium(S.of(context).oathRequireTouch),
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomizedText.bodyMedium(S.of(context).oathAdvancedSettings),
        Spacing.height(12),
        _buildTypeSelector(),
        Spacing.height(12),
        _buildAlgorithmSelector(),
        Spacing.height(12),
        _buildDigitsSelector(),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return _buildOptionRow(
      label: S.of(context).oathType,
      child: RadioGroup<OathType>(
        groupValue: formData.oathType.value,
        onChanged: (type) {
          if (type != null) formData.oathType.value = type;
        },
        child: Wrap(
          spacing: _kPadding,
          children: OathType.values
              .map(
                (type) => _buildRadioOption(
                  value: type,
                  label: type.name.toUpperCase(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildAlgorithmSelector() {
    return _buildOptionRow(
      label: S.of(context).oathAlgorithm,
      child: RadioGroup<OathAlgorithm>(
        groupValue: formData.oathAlgorithm.value,
        onChanged: (algo) {
          if (algo != null) formData.oathAlgorithm.value = algo;
        },
        child: Wrap(
          spacing: _kPadding,
          children: OathAlgorithm.values
              .map(
                (algo) => _buildRadioOption(
                  value: algo,
                  label: algo.name.toUpperCase(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDigitsSelector() {
    return _buildOptionRow(
      label: S.of(context).oathDigits,
      child: RadioGroup<int>(
        groupValue: formData.oathDigits.value,
        onChanged: (digits) {
          if (digits != null) formData.oathDigits.value = digits;
        },
        child: Wrap(
          spacing: _kPadding,
          children: _kValidDigits
              .map(
                (digits) =>
                    _buildRadioOption(value: digits, label: digits.toString()),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildOptionRow({required String label, required Widget child}) {
    return Row(
      children: [
        SizedBox(width: _kLabelWidth, child: CustomizedText.labelLarge(label)),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildRadioOption<T>({required T value, required String label}) {
    return InkWell(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<T>(
            value: value,
            activeColor: contentTheme.primary,
            visualDensity: getCompactDensity,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Spacing.width(8),
          CustomizedText.labelMedium(label),
        ],
      ),
    );
  }

  Widget _buildHotpCounter() {
    return Padding(
      padding: const EdgeInsets.only(top: _kPadding),
      child: _buildTextField(
        label: S.of(context).oathCounter,
        fieldName: 'counter',
      ),
    );
  }

  @override
  Widget buildDialogContent() {
    return Obx(
      () => AppDialogColumn(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDialogHeader(title: S.of(context).oathAddAccount),
          const Divider(height: 0, thickness: 1),
          Padding(
            padding: const EdgeInsets.all(_kPadding),
            child: Form(
              key: formData.validator.formKey,
              child: Column(
                children: [
                  _buildBasicFields(),
                  _buildTouchRequirement(),
                  _buildAdvancedSettings(),
                  if (formData.oathType.value == OathType.hotp)
                    _buildHotpCounter(),
                ],
              ),
            ),
          ),
          if (errorMessage.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(_kPadding),
              child: CustomizedText.bodyMedium(
                errorMessage.value,
                color: errorLevel.value == 'E'
                    ? ContentThemeColor.danger.color
                    : ContentThemeColor.warning.color,
              ),
            ),
          const Divider(height: 0, thickness: 1),
          AppDialogActions(
            children: [
              AppDialogAction(
                label: S.of(context).cancel,
                onPressed: () => Navigator.pop(context),
                secondary: true,
                destructive: false,
              ),
              AppDialogAction(
                label: S.of(context).save,
                onPressed: _handleSave,
                secondary: false,
                destructive: false,
              ),
            ],
          ),
        ],
      ),
    );
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
    validator.addField(
      'issuer',
      required: true,
      controller: TextEditingController(text: initialIssuer),
    );
    validator.addField(
      'account',
      required: true,
      controller: TextEditingController(text: initialAccount),
    );
    validator.addField(
      'secret',
      required: true,
      controller: TextEditingController(text: initialSecret),
      validators: [LengthValidator(min: 8, max: 103)],
    );
    validator.addField(
      'counter',
      required: true,
      controller: TextEditingController(
        text: initialCounter?.toString() ?? '0',
      ),
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
