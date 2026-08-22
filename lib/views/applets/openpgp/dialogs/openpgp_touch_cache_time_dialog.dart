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
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OpenPgpTouchCacheTimeDialog extends BaseDialog {
  final int? currentSeconds;
  final Future<void> Function(String adminPin, int seconds) onSubmit;

  const OpenPgpTouchCacheTimeDialog({
    super.key,
    required this.currentSeconds,
    required this.onSubmit,
  });

  static Future<void> show({
    required int? currentSeconds,
    required Future<void> Function(String adminPin, int seconds) onSubmit,
  }) {
    return AppDialog.show(
      OpenPgpTouchCacheTimeDialog(
        currentSeconds: currentSeconds,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<OpenPgpTouchCacheTimeDialog> createState() => _OpenPgpTouchCacheTimeDialogState();
}

class _OpenPgpTouchCacheTimeDialogState extends BaseDialogState<OpenPgpTouchCacheTimeDialog> {
  final FormValidator _validator = FormValidator();
  final RxBool _showAdminPin = false.obs;

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
      'seconds',
      required: true,
      controller: TextEditingController(text: '${widget.currentSeconds ?? 0}'),
      validators: [IntValidator(min: 0, max: 255)],
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
              S.of(context).openpgpSetTouchCacheTime,
            ),
          ),
          Divider(height: 0, thickness: 1),
          Padding(
            padding: Spacing.all(16),
            child: CustomizedText.bodyMedium(
              S.of(context).openpgpSetTouchCacheTimePrompt,
              maxLines: 4,
            ),
          ),
          Divider(height: 0, thickness: 1),
          Padding(
            padding: Spacing.all(16),
            child: Form(
              key: _validator.formKey,
              child: Column(
                children: [
                  TextFormField(
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
                  Spacing.height(16),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    controller: _validator.getController('seconds'),
                    validator: _validator.getValidator('seconds'),
                    decoration: InputDecoration(
                      labelText: S.of(context).openpgpCacheSeconds,
                      border: _outlineInputBorder,
                    ),
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
      int.parse(_validator.getController('seconds')!.text),
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
