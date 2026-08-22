import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';

class ForcePinChangeDialog extends BaseDialog {
  final int minPinLength;
  final Future<bool> Function(String currentPin, String newPin, bool savePin) onSubmit;
  final VoidCallback onCancel;

  const ForcePinChangeDialog({
    super.key,
    required this.minPinLength,
    required this.onSubmit,
    required this.onCancel,
  });

  static Future<void> show({
    required int minPinLength,
    required Future<bool> Function(String currentPin, String newPin, bool savePin) onSubmit,
    required VoidCallback onCancel,
  }) {
    return AppDialog.show(
      ForcePinChangeDialog(
        minPinLength: minPinLength,
        onSubmit: onSubmit,
        onCancel: onCancel,
      ),
    );
  }

  @override
  State<ForcePinChangeDialog> createState() => _ForcePinChangeDialogState();
}

class _ForcePinChangeDialogState extends BaseDialogState<ForcePinChangeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPin = TextEditingController();
  final _newPin = TextEditingController();
  final _confirmPin = TextEditingController();
  bool _showCurrentPin = false;
  bool _showNewPin = false;
  bool _savePin = false;
  bool _submitting = false;

  @override
  void dispose() {
    _currentPin.dispose();
    _newPin.dispose();
    _confirmPin.dispose();
    super.dispose();
  }

  String? _validatePin(String? value, {required int minLength}) {
    if (value == null || value.length < minLength) {
      return S.of(context).validationAtLeastCharacters(minLength);
    }
    if (value.length > 63) {
      return S.of(context).validationAtMostCharacters(63);
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) {
      return;
    }
    if (_newPin.text != _confirmPin.text) {
      setState(() => errorMessage.value = S.of(context).pinConfirmationMismatch);
      return;
    }
    setState(() {
      _submitting = true;
      errorMessage.value = '';
    });
    final changed = await widget.onSubmit(_currentPin.text, _newPin.text, _savePin);
    if (!mounted) {
      return;
    }
    if (changed) {
      Navigator.pop(context);
      return;
    }
    setState(() => _submitting = false);
  }

  @override
  Widget buildDialogContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: Spacing.all(16),
          child: CustomizedText.labelLarge(S.of(context).changePin),
        ),
        Divider(height: 0, thickness: 1),
        Padding(
          padding: Spacing.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _pinField(
                  controller: _currentPin,
                  label: S.of(context).oldPin,
                  minLength: 4,
                  obscureText: !_showCurrentPin,
                  onToggleVisibility: () => setState(() => _showCurrentPin = !_showCurrentPin),
                ),
                Spacing.height(12),
                _pinField(
                  controller: _newPin,
                  label: S.of(context).newPin,
                  minLength: widget.minPinLength,
                  obscureText: !_showNewPin,
                  onToggleVisibility: () => setState(() => _showNewPin = !_showNewPin),
                ),
                Spacing.height(12),
                _pinField(
                  controller: _confirmPin,
                  label: '${S.of(context).newPin} (${S.of(context).confirm})',
                  minLength: widget.minPinLength,
                  obscureText: !_showNewPin,
                  onFieldSubmitted: (_) => _submit(),
                  onToggleVisibility: () => setState(() => _showNewPin = !_showNewPin),
                ),
                CheckboxListTile(
                  value: _savePin,
                  onChanged: _submitting ? null : (value) => setState(() => _savePin = value ?? false),
                  title: CustomizedText.bodyMedium(S.of(context).savePinOnDevice),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                if (errorMessage.value.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CustomizedText.bodyMedium(
                      errorMessage.value,
                      color: ContentThemeColor.danger.color,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Divider(height: 0, thickness: 1),
        Padding(
          padding: Spacing.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomizedButton.rounded(
                onPressed: _submitting
                    ? null
                    : () {
                        Navigator.pop(context);
                        widget.onCancel();
                      },
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
                onPressed: _submitting ? null : _submit,
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
    );
  }

  Widget _pinField({
    required TextEditingController controller,
    required String label,
    required int minLength,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_submitting,
      autofocus: controller == _currentPin,
      obscureText: obscureText,
      validator: (value) => _validatePin(value, minLength: minLength),
      onTap: SmartCard.eject,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(
            width: 1,
            strokeAlign: 0,
            color: AppTheme.theme.colorScheme.onSurface.withAlpha(80),
          ),
        ),
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
        ),
      ),
    );
  }
}
