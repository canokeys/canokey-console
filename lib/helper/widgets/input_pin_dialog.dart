import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/field_validator.dart';
import 'package:canokey_console/helper/widgets/form_validator.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InputPinDialog extends StatefulWidget {
  final String title;
  final String label;
  final String prompt;
  final bool required;
  final bool showSaveOption;
  final List<FieldValidatorRule> validators;
  final Completer<(String, bool)> c;

  const InputPinDialog({
    super.key,
    required this.title,
    required this.label,
    required this.prompt,
    required this.required,
    required this.showSaveOption,
    required this.validators,
    required this.c,
  });

  static Future<(String, bool)> show({
    required String title,
    required String label,
    required String prompt,
    bool required = true,
    bool showSaveOption = false,
    List<FieldValidatorRule> validators = const [],
  }) {
    Completer<(String, bool)> c = Completer<(String, bool)>();
    Get.dialog(
      InputPinDialog(
        title: title,
        label: label,
        prompt: prompt,
        required: required,
        showSaveOption: showSaveOption,
        validators: validators,
        c: c,
      ),
      barrierDismissible: false,
    );
    return c.future;
  }

  @override
  State<InputPinDialog> createState() => _InputPinDialogState();
}

class _InputPinDialogState extends State<InputPinDialog> {
  final showPin = false.obs;
  final savePin = false.obs;
  final _validator = FormValidator();

  @override
  void initState() {
    super.initState();
    _validator.addField('pin', required: widget.required, controller: TextEditingController(), validators: widget.validators);
  }

  void _onSubmit() {
    if (_validator.validateForm()) {
      Navigator.pop(Get.context!);
      widget.c.complete((_validator.getController('pin')!.text, savePin.value));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(widget.title),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.bodyMedium(widget.prompt),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Column(
                children: [
                  Form(
                    key: _validator.formKey,
                    child: Obx(() => TextFormField(
                          autofocus: true,
                          onTap: SmartCard.eject,
                          obscureText: !showPin.value,
                          controller: _validator.getController('pin'),
                          validator: _validator.getValidator('pin'),
                          onFieldSubmitted: (_) => _onSubmit(),
                          decoration: InputDecoration(
                            labelText: widget.label,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                              borderSide: BorderSide(width: 1, strokeAlign: 0, color: AppTheme.theme.colorScheme.onSurface.withAlpha(80)),
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            suffixIcon: IconButton(
                              icon: Icon(showPin.value ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => showPin.toggle(),
                            ),
                          ),
                        )),
                  ),
                  if (widget.showSaveOption) ...[
                    Obx(() => CheckboxListTile(
                          value: savePin.value,
                          onChanged: (value) => savePin.value = value!,
                          title: CustomizedText.bodyMedium(S.of(context).savePinOnDevice),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        )),
                  ],
                ],
              ),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Row(
                children: [
                  CustomizedButton.rounded(
                    onPressed: () {
                      Navigator.pop(Get.context!);
                      widget.c.completeError(UserCanceledError());
                    },
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: ContentThemeColor.secondary.color,
                    child: CustomizedText.labelMedium(S.of(Get.context!).cancel, color: ContentThemeColor.secondary.onColor),
                  ),
                  Spacing.width(16),
                  CustomizedButton.rounded(
                    onPressed: _onSubmit,
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: ContentThemeColor.primary.color,
                    child: CustomizedText.labelMedium(S.of(Get.context!).confirm, color: ContentThemeColor.primary.onColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
