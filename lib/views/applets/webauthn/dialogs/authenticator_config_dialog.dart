import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/form_validator.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Device-global authenticatorConfig settings. The RP allowlist of
/// minPinLength (minPinLengthRPIDs) is deliberately not exposed.
class AuthenticatorConfigDialog extends BaseDialog with UIMixin {
  final bool? alwaysUv;
  final int? minPinLength;
  final Future<bool> Function() onToggleAlwaysUv;
  final Future<bool> Function(int newMinPinLength, bool forcePinChange)
  onSetMinPinLength;
  final Future<bool> Function() onEnableLongTouch;

  const AuthenticatorConfigDialog({
    super.key,
    required this.alwaysUv,
    required this.minPinLength,
    required this.onToggleAlwaysUv,
    required this.onSetMinPinLength,
    required this.onEnableLongTouch,
  });

  static Future<void> show({
    required bool? alwaysUv,
    required int? minPinLength,
    required Future<bool> Function() onToggleAlwaysUv,
    required Future<bool> Function(int newMinPinLength, bool forcePinChange)
    onSetMinPinLength,
    required Future<bool> Function() onEnableLongTouch,
  }) {
    return AppDialog.show(
      AuthenticatorConfigDialog(
        alwaysUv: alwaysUv,
        minPinLength: minPinLength,
        onToggleAlwaysUv: onToggleAlwaysUv,
        onSetMinPinLength: onSetMinPinLength,
        onEnableLongTouch: onEnableLongTouch,
      ),
    );
  }

  @override
  State<AuthenticatorConfigDialog> createState() =>
      _AuthenticatorConfigDialogState();
}

class _AuthenticatorConfigDialogState
    extends BaseDialogState<AuthenticatorConfigDialog>
    with UIMixin {
  final FormValidator validator = FormValidator();

  late final RxBool alwaysUv;
  late final RxInt minPinLength;
  final RxBool forcePinChange = false.obs;
  final RxBool longTouchEnabled = false.obs;

  @override
  void initState() {
    super.initState();
    alwaysUv = (widget.alwaysUv ?? false).obs;
    minPinLength = (widget.minPinLength ?? 4).obs;
    validator.addField(
      'minPinLength',
      required: true,
      controller: TextEditingController(text: '${minPinLength.value}'),
      validators: [_MinPinLengthValidator(minPinLength)],
    );
  }

  Future<void> _toggleAlwaysUv() async {
    if (!await _confirm(S.of(context).webauthnAlwaysUvTogglePrompt)) {
      return;
    }
    if (await widget.onToggleAlwaysUv()) {
      alwaysUv.value = !alwaysUv.value;
    }
  }

  Future<void> _submitMinPinLength() async {
    if (!validator.formKey.currentState!.validate()) {
      return;
    }
    final newMinPinLength = int.parse(
      validator.getController('minPinLength')!.text,
    );
    if (await widget.onSetMinPinLength(
      newMinPinLength,
      forcePinChange.value,
    )) {
      minPinLength.value = newMinPinLength;
      forcePinChange.value = false;
    }
  }

  Future<void> _enableLongTouch() async {
    if (!await _confirm(
      S.of(context).webauthnLongTouchEnablePrompt,
      destructive: true,
    )) {
      return;
    }
    if (await widget.onEnableLongTouch()) {
      longTouchEnabled.value = true;
    }
  }

  Future<bool> _confirm(String message, {bool destructive = false}) async {
    return await AppDialog.show<bool>(
          AlertDialog(
            title: CustomizedText.bodyLarge(S.of(context).warning),
            content: CustomizedText.bodyMedium(
              message,
              color: destructive ? ContentThemeColor.danger.color : null,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(Get.context!, false),
                child: Text(S.of(context).cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(Get.context!, true),
                child: Text(
                  S.of(context).confirm,
                  style: destructive
                      ? TextStyle(color: ContentThemeColor.danger.color)
                      : null,
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget buildDialogContent() {
    return Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDialogHeader(title: S.of(context).webauthnAuthenticatorSettings),
          Divider(height: 0, thickness: 1),
          Padding(
            padding: Spacing.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.alwaysUv != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomizedText.bodyLarge(
                              S.of(context).webauthnAlwaysUv,
                            ),
                            CustomizedText.bodyMedium(
                              alwaysUv.value
                                  ? S.of(context).on
                                  : S.of(context).off,
                              muted: true,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: alwaysUv.value,
                        onChanged: (_) => _toggleAlwaysUv(),
                      ),
                    ],
                  ),
                  Spacing.height(8),
                  CustomizedText.bodyMedium(
                    S.of(context).webauthnAlwaysUvDescription,
                    muted: true,
                  ),
                  Spacing.height(24),
                ],
                if (widget.minPinLength != null) ...[
                  CustomizedText.bodyLarge(S.of(context).webauthnMinPinLength),
                  Spacing.height(8),
                  CustomizedText.bodyMedium(
                    S.of(context).webauthnMinPinLengthHint(minPinLength.value),
                    muted: true,
                  ),
                  Spacing.height(16),
                  Form(
                    key: validator.formKey,
                    child: TextFormField(
                      onTap: SmartCard.eject,
                      controller: validator.getController('minPinLength'),
                      validator: validator.getValidator('minPinLength'),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: S.of(context).webauthnMinPinLength,
                        border: outlineInputBorder,
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        onChanged: (value) => forcePinChange.value = value!,
                        value: forcePinChange.value,
                        activeColor: contentTheme.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: getCompactDensity,
                      ),
                      Spacing.width(16),
                      Expanded(
                        child: CustomizedText.bodyMedium(
                          S.of(context).webauthnForcePinChange,
                        ),
                      ),
                    ],
                  ),
                  Spacing.height(8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppDialogAction(
                      label: S.of(context).save,
                      onPressed: _submitMinPinLength,
                    ),
                  ),
                  Spacing.height(24),
                ],
                Container(
                  width: double.infinity,
                  padding: Spacing.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: ContentThemeColor.danger.color),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomizedText.bodyLarge(
                        S.of(context).webauthnDangerZone,
                        color: ContentThemeColor.danger.color,
                      ),
                      Spacing.height(8),
                      CustomizedText.bodyMedium(
                        S.of(context).webauthnLongTouchWarning,
                        color: ContentThemeColor.danger.color,
                      ),
                      Spacing.height(16),
                      if (longTouchEnabled.value)
                        CustomizedText.bodyMedium(
                          S.of(context).enabled,
                          muted: true,
                        )
                      else
                        AppDialogAction(
                          label: S.of(context).enable,
                          onPressed: _enableLongTouch,
                          destructive: true,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (errorMessage.value.isNotEmpty)
            Padding(
              padding: Spacing.all(16),
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
                label: S.of(context).close,
                onPressed: () => Navigator.pop(context),
                secondary: true,
                destructive: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The minimum PIN length can only be raised, so the lower bound follows the
/// current value (at least 4).
class _MinPinLengthValidator extends IntValidator {
  final RxInt currentMin;

  _MinPinLengthValidator(this.currentMin) : super(min: 4, max: 63);

  @override
  String? validate(String? value, bool required, Map<String, dynamic> data) {
    final error = super.validate(value, required, data);
    if (error != null) return error;
    final parsed = int.tryParse(value ?? '');
    if (parsed != null && parsed < currentMin.value) {
      return S.current.webauthnMinPinLengthHint(currentMin.value);
    }
    return null;
  }
}
