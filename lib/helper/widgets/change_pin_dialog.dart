import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/field_validator.dart';
import 'package:canokey_console/helper/widgets/form_validator.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangePinDialog extends StatefulWidget {
  final String title;
  final String oldValueLabel;
  final String newValueLabel;
  final String prompt;
  final List<FieldValidatorRule> validators;
  final Future<void> Function(String oldValue, String newValue) onSubmit;

  const ChangePinDialog({
    super.key,
    required this.title,
    required this.oldValueLabel,
    required this.newValueLabel,
    required this.prompt,
    required this.validators,
    required this.onSubmit,
  });

  static Future<void> show({
    required String title,
    required String oldValueLabel,
    required String newValueLabel,
    required String prompt,
    List<FieldValidatorRule> validators = const [],
    required Future<void> Function(String oldValue, String newValue) onSubmit,
  }) {
    return Get.dialog(
      ChangePinDialog(title: title, oldValueLabel: oldValueLabel, newValueLabel: newValueLabel, prompt: prompt, validators: validators, onSubmit: onSubmit),
      barrierDismissible: false,
    );
  }

  @override
  State<ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<ChangePinDialog> {
  final showOldPin = false.obs;
  final showNewPin = false.obs;
  final _validator = FormValidator();

  @override
  void initState() {
    super.initState();
    _validator.addField('old', required: true, controller: TextEditingController(), validators: widget.validators);
    _validator.addField('new', required: true, controller: TextEditingController(), validators: widget.validators);
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
              child: Form(
                key: _validator.formKey,
                child: Obx(() => Column(
                      children: [
                        TextFormField(
                          autofocus: true,
                          onTap: SmartCard.eject,
                          obscureText: !showOldPin.value,
                          controller: _validator.getController('old'),
                          validator: _validator.getValidator('old'),
                          decoration: InputDecoration(
                            labelText: widget.oldValueLabel,
                            border: _outlineInputBorder,
                            suffixIcon: IconButton(
                              icon: Icon(showOldPin.value ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => showOldPin.toggle(),
                            ),
                          ),
                        ),
                        Spacing.height(16),
                        TextFormField(
                          autofocus: true,
                          onTap: SmartCard.eject,
                          obscureText: !showNewPin.value,
                          controller: _validator.getController('new'),
                          validator: _validator.getValidator('new'),
                          decoration: InputDecoration(
                            labelText: widget.newValueLabel,
                            border: _outlineInputBorder,
                            suffixIcon: IconButton(
                              icon: Icon(showNewPin.value ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => showNewPin.toggle(),
                            ),
                          ),
                        ),
                      ],
                    )),
              ),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomizedButton.rounded(
                    onPressed: () => Navigator.pop(Get.context!),
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: ContentThemeColor.secondary.color,
                    child: CustomizedText.labelMedium(S.of(Get.context!).cancel, color: ContentThemeColor.secondary.onColor),
                  ),
                  Spacing.width(16),
                  CustomizedButton.rounded(
                    onPressed: () {
                      if (_validator.validateForm()) {
                        final o = _validator.getController('old')!.text;
                        final n = _validator.getController('new')!.text;
                        widget.onSubmit(o, n);
                      }
                    },
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

  final _outlineInputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(4)),
    borderSide: BorderSide(width: 1, strokeAlign: 0, color: AppTheme.theme.colorScheme.onSurface.withAlpha(80)),
  );
}
