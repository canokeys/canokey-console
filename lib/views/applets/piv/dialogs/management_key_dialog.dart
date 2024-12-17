import 'dart:math';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/form_validator.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManagementKeyDialog extends StatelessWidget with UIMixin {
  final Future<void> Function(String oldKey, String newKey) onSubmit;

  const ManagementKeyDialog({super.key, required this.onSubmit});

  static Future<void> show(Future<void> Function(String oldKey, String newKey) onSubmit) {
    return Get.dialog(
      ManagementKeyDialog(onSubmit: onSubmit),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    FormValidator validator = FormValidator();
    validator.addField('old', required: true, controller: TextEditingController(), validators: [LengthValidator(exact: 48), HexStringValidator()]);
    validator.addField('new', required: true, controller: TextEditingController(), validators: [LengthValidator(exact: 48), HexStringValidator()]);

    return Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.of(context).pivChangeManagementKey),
            ),
            const Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Form(
                key: validator.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomizedText.bodySmall(S.of(context).pivChangeManagementKeyPrompt),
                    Spacing.height(16),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          autofocus: true,
                          onTap: () => SmartCard.eject(),
                          controller: validator.getController('old'),
                          validator: validator.getValidator('old'),
                          decoration: InputDecoration(
                            labelText: S.of(context).pivOldManagementKey,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                              borderSide: BorderSide(width: 1, strokeAlign: 0, color: AppTheme.theme.colorScheme.onSurface.withAlpha(80)),
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                        ),
                      ),
                      Spacing.width(8),
                      CustomizedButton(
                        onPressed: () => validator.getController('old')!.text = '010203040506070801020304050607080102030405060708',
                        elevation: 0,
                        backgroundColor: ContentThemeColor.primary.color,
                        minSize: WidgetStatePropertyAll(Size(92, 40)),
                        child: CustomizedText.labelMedium(S.of(context).pivUseDefaultManagementKey, color: ContentThemeColor.primary.onColor),
                      ),
                    ]),
                    Spacing.height(16),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          onTap: () => SmartCard.eject(),
                          controller: validator.getController('new'),
                          validator: validator.getValidator('new'),
                          decoration: InputDecoration(
                            labelText: S.of(context).pivNewManagementKey,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                              borderSide: BorderSide(width: 1, strokeAlign: 0, color: AppTheme.theme.colorScheme.onSurface.withAlpha(80)),
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                        ),
                      ),
                      Spacing.width(8),
                      CustomizedButton(
                        onPressed: () {
                          final random = Random.secure();
                          final values = List<int>.generate(24, (i) => random.nextInt(256));
                          validator.getController('new')!.text = hex.encode(values);
                        },
                        elevation: 0,
                        backgroundColor: ContentThemeColor.primary.color,
                        minSize: WidgetStatePropertyAll(Size(92, 40)),
                        child: CustomizedText.labelMedium(S.of(context).pivRandomManagementKey, color: ContentThemeColor.primary.onColor),
                      ),
                    ])
                  ],
                ),
              ),
            ),
            const Divider(height: 0, thickness: 1),
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
                      if (validator.validateForm()) {
                        final oldKey = validator.getController('old')!.text;
                        final newKey = validator.getController('new')!.text;
                        onSubmit(oldKey, newKey);
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
}
