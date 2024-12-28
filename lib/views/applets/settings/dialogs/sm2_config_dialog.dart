import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/form_validator.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Sm2ConfigDialog extends StatelessWidget with UIMixin {
  final WebAuthnSm2Config config;
  final Function(bool enabled, int curveId, int algoId) onConfirm;

  const Sm2ConfigDialog({super.key, required this.config, required this.onConfirm});

  static Future<void> show({required WebAuthnSm2Config config, required Function(bool enabled, int curveId, int algoId) onConfirm}) {
    return Get.dialog(
      Sm2ConfigDialog(config: config, onConfirm: onConfirm),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = config.enabled.obs;

    FormValidator validator = FormValidator();
    validator.addField('curveId', controller: TextEditingController(), validators: [IntValidator(min: -65536, max: 65535)]);
    validator.addField('algoId', controller: TextEditingController(), validators: [IntValidator(min: -65536, max: 65535)]);
    validator.getController('curveId')!.text = config.curveId.toString();
    validator.getController('algoId')!.text = config.algoId.toString();

    return Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.of(context).settingsWebAuthnSm2Support),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
                padding: Spacing.all(16),
                child: Form(
                    key: validator.formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Obx(() => Checkbox(
                                  onChanged: (value) => enabled.value = value!,
                                  value: enabled.value,
                                  activeColor: contentTheme.primary,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: getCompactDensity,
                                )),
                            Spacing.width(16),
                            CustomizedText.bodyMedium(S.of(context).enabled),
                          ],
                        ),
                        Spacing.height(16),
                        TextFormField(
                          autofocus: true,
                          onTap: () => SmartCard.eject(),
                          controller: validator.getController('curveId'),
                          validator: validator.getValidator('curveId'),
                          decoration: InputDecoration(
                            labelText: 'Curve ID',
                            border: outlineInputBorder,
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                        ),
                        Spacing.height(16),
                        TextFormField(
                          onTap: () => SmartCard.eject(),
                          controller: validator.getController('algoId'),
                          validator: validator.getValidator('algoId'),
                          decoration: InputDecoration(
                            labelText: 'Algorithm ID',
                            border: outlineInputBorder,
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                        ),
                      ],
                    ))),
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
                    backgroundColor: contentTheme.secondary,
                    child: CustomizedText.labelMedium(S.of(context).close, color: contentTheme.onSecondary),
                  ),
                  Spacing.width(16),
                  CustomizedButton.rounded(
                    onPressed: () {
                      if (validator.formKey.currentState!.validate()) {
                        Navigator.pop(context);
                        onConfirm(enabled.value, int.parse(validator.getController('curveId')!.text), int.parse(validator.getController('algoId')!.text));
                      }
                    },
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium(S.of(context).save, color: contentTheme.onPrimary),
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
