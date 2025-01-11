import 'dart:async';

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
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';

class InputPinDialog extends StatefulWidget {
  final String title;
  final String label;
  final String prompt;
  final bool required;
  final bool showSaveOption;
  final List<FieldValidatorRule> validators;
  final Future<void> Function(String, bool) onSubmit;
  final Future<void> Function() onCancel;

  const InputPinDialog({
    super.key,
    required this.title,
    required this.label,
    required this.prompt,
    required this.required,
    required this.showSaveOption,
    required this.validators,
    required this.onSubmit,
    required this.onCancel,
  });

  static showWithCallback({
    required String title,
    required String label,
    required String prompt,
    bool required = true,
    bool showSaveOption = false,
    List<FieldValidatorRule> validators = const [],
    Future<void> Function(String, bool) onSubmit = _defaultOnSubmit,
    Future<void> Function() onCancel = _defaultOnCancel,
  }) {
    Get.dialog(
      InputPinDialog(
        title: title,
        label: label,
        prompt: prompt,
        required: required,
        showSaveOption: showSaveOption,
        validators: validators,
        onSubmit: onSubmit,
        onCancel: onCancel,
      ),
      barrierDismissible: false,
    );
  }

  @override
  State<InputPinDialog> createState() => _InputPinDialogState();

  static Future<void> _defaultOnSubmit(String pin, bool savePin) async {}

  static Future<void> _defaultOnCancel() async {}
}

class _InputPinDialogState extends State<InputPinDialog> {
  final FormValidator _validator = FormValidator();
  final RxBool _showPin = false.obs;
  final RxBool _savePin = false.obs;
  final RxBool _showPolling = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxString _errorLevel = 'E'.obs;

  @override
  void initState() {
    super.initState();
    Get.put(_showPolling, tag: 'dialog_polling');
    Get.put(_errorMessage, tag: 'dialog_error');
    Get.put(_errorLevel, tag: 'dialog_error_level');
    _validator.addField('pin', required: widget.required, controller: TextEditingController(), validators: widget.validators);
  }

  @override
  void dispose() {
    Get.delete(tag: 'dialog_polling');
    Get.delete(tag: 'dialog_error');
    Get.delete(tag: 'dialog_error_color');
    super.dispose();
  }

  void _onSubmit() async {
    if (_validator.validateForm()) {
      await widget.onSubmit(_validator.getController('pin')!.text, _savePin.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 400,
        child: Stack(
          children: [
            Column(
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
                              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                              onTap: SmartCard.eject,
                              obscureText: !_showPin.value,
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
                                  icon: Icon(_showPin.value ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () => _showPin.toggle(),
                                ),
                              ),
                            )),
                      ),
                      if (widget.showSaveOption) ...[
                        Obx(() => CheckboxListTile(
                              value: _savePin.value,
                              onChanged: (value) => _savePin.value = value!,
                              title: CustomizedText.bodyMedium(S.of(context).savePinOnDevice),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            )),
                      ],
                      Obx(() => CustomizedText.bodyMedium(_errorMessage.value,
                          color: _errorLevel.value == 'E' ? ContentThemeColor.danger.color : ContentThemeColor.warning.color)),
                    ],
                  ),
                ),
                Divider(height: 0, thickness: 1),
                Padding(
                  padding: Spacing.all(16),
                  child: Row(
                    children: [
                      CustomizedButton.rounded(
                        onPressed: () async {
                          Navigator.pop(Get.context!);
                          await widget.onCancel();
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
            Positioned.fill(
              child: Obx(
                () => !_showPolling.value
                    ? Container()
                    : GestureDetector(
                        onTap: () {},
                        child: Container(
                          color: Colors.black.withOpacity(0.9),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SpinKitRipple(color: Colors.tealAccent, size: 64.0),
                                Spacing.height(16),
                                CustomizedText.bodyLarge(S.of(Get.context!).readingAlertMessage, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
