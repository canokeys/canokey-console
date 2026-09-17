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
import 'package:canokey_console/models/webauthn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Sm2ConfigDialog extends BaseDialog with UIMixin {
  final WebAuthnSm2Config config;
  final bool canChangeEnabled;
  final Function(bool enabled, int curveId, int algoId) onConfirm;

  const Sm2ConfigDialog({
    super.key,
    required this.config,
    required this.canChangeEnabled,
    required this.onConfirm,
  });

  static Future<void> show({
    required WebAuthnSm2Config config,
    required bool canChangeEnabled,
    required Function(bool enabled, int curveId, int algoId) onConfirm,
  }) {
    return AppDialog.show(
      Sm2ConfigDialog(
        config: config,
        canChangeEnabled: canChangeEnabled,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  bool get managesOwnScrolling => true;

  @override
  State<Sm2ConfigDialog> createState() => _Sm2ConfigDialogState();
}

class _Sm2ConfigDialogState extends BaseDialogState<Sm2ConfigDialog>
    with UIMixin {
  final FormValidator validator = FormValidator();

  late final RxBool enabled;

  @override
  void initState() {
    super.initState();
    enabled = (widget.canChangeEnabled ? widget.config.enabled : true).obs;
    validator.addField(
      'curveId',
      required: true,
      controller: TextEditingController(),
      validators: [
        Sm2IdentifierValidator(curve: true, legacy: widget.canChangeEnabled),
      ],
    );
    validator.addField(
      'algoId',
      required: true,
      controller: TextEditingController(),
      validators: [
        Sm2IdentifierValidator(curve: false, legacy: widget.canChangeEnabled),
      ],
    );
    validator.getController('curveId')!.text = widget.config.curveId.toString();
    validator.getController('algoId')!.text = widget.config.algoId.toString();
  }

  Future<void> _onSubmit() async {
    if (validator.formKey.currentState!.validate()) {
      await widget.onConfirm(
        enabled.value,
        int.parse(validator.getController('curveId')!.text),
        int.parse(validator.getController('algoId')!.text),
      );
    }
  }

  @override
  Widget buildDialogContent() {
    return Obx(
      () => AppDialogColumn(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDialogHeader(title: S.of(context).settingsWebAuthnSm2Support),
          Divider(height: 0, thickness: 1),
          Padding(
            padding: Spacing.all(24),
            child: Form(
              key: validator.formKey,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ContentThemeColor.warning.color.withValues(
                        alpha: .1,
                      ),
                      border: Border.all(
                        color: ContentThemeColor.warning.color.withValues(
                          alpha: .25,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 22,
                          color: ContentThemeColor.warning.color,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomizedText.bodyMedium(
                            S.of(context).sm2ConfigWarning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacing.height(16),
                  if (widget.canChangeEnabled) ...[
                    AppDialogCheckbox(
                      value: enabled.value,
                      onChanged: (value) => enabled.value = value!,
                      title: CustomizedText.bodyMedium(S.of(context).enabled),
                    ),
                    Spacing.height(16),
                  ],
                  TextFormField(
                    autofocus: true,
                    onTap: SmartCard.eject,
                    controller: validator.getController('curveId'),
                    validator: validator.getValidator('curveId'),
                    decoration: InputDecoration(
                      labelText: S.of(context).sm2CurveId,
                      border: outlineInputBorder,
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                  ),
                  Spacing.height(16),
                  TextFormField(
                    onTap: SmartCard.eject,
                    controller: validator.getController('algoId'),
                    validator: validator.getValidator('algoId'),
                    decoration: InputDecoration(
                      labelText: S.of(context).sm2AlgorithmId,
                      border: outlineInputBorder,
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (errorMessage.value.isNotEmpty)
            Padding(
              padding: Spacing.all(24),
              child: CustomizedText.bodyMedium(
                errorMessage.value,
                color: errorLevel.value == 'E'
                    ? ContentThemeColor.danger.color
                    : ContentThemeColor.warning.color,
              ),
            ),
          Divider(height: 0, thickness: 1),
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
                onPressed: _onSubmit,
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

class Sm2IdentifierValidator extends IntValidator {
  final bool curve;
  final bool legacy;

  Sm2IdentifierValidator({required this.curve, required this.legacy})
    : super(min: -2147483648, max: 2147483647);

  @override
  String? validate(String? value, bool required, Map<String, dynamic> data) {
    final error = super.validate(value, required, data);
    if (error != null || legacy) return error;
    final id = int.parse(value!);
    final valid = curve
        ? WebAuthnSm2Config.isValidCurveId(id)
        : WebAuthnSm2Config.isValidAlgorithmId(id);
    return valid ? null : S.current.sm2ReservedId;
  }
}
