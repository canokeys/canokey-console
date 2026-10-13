import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';

class ForcePinChangeDialog extends BaseDialog {
  final int minPinLength;
  final Future<bool> Function(String currentPin, String newPin, bool savePin)
  onSubmit;
  final VoidCallback onCancel;
  final Future<void> Function() onFocus;

  const ForcePinChangeDialog({
    super.key,
    required this.minPinLength,
    required this.onSubmit,
    required this.onCancel,
    this.onFocus = SmartCard.eject,
  });

  static Future<void> show({
    required int minPinLength,
    required Future<bool> Function(
      String currentPin,
      String newPin,
      bool savePin,
    )
    onSubmit,
    required VoidCallback onCancel,
  }) {
    final zone = Zone.current;
    return AppDialog.show(
      ForcePinChangeDialog(
        minPinLength: minPinLength,
        onSubmit: (currentPin, newPin, savePin) =>
            zone.run(() => onSubmit(currentPin, newPin, savePin)),
        onCancel: zone.bindCallback(onCancel),
        onFocus: zone.bindCallback(SmartCard.eject),
      ),
    );
  }

  @override
  bool get managesOwnScrolling => true;

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
      setState(
        () => errorMessage.value = S.of(context).pinConfirmationMismatch,
      );
      return;
    }
    setState(() {
      _submitting = true;
      errorMessage.value = '';
    });
    try {
      final changed = await widget.onSubmit(
        _currentPin.text,
        _newPin.text,
        _savePin,
      );
      if (mounted && changed) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_submitting,
    onPopInvokedWithResult: (didPop, result) {
      if (didPop && !_submitting) widget.onCancel();
    },
    child: super.build(context),
  );

  @override
  Widget buildDialogContent() {
    return AppDialogColumn(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppDialogHeader(
          title: S.of(context).changePin,
          closeEnabled: !_submitting,
        ),
        Divider(height: 0, thickness: 1),
        Padding(
          padding: Spacing.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _pinField(
                  controller: _currentPin,
                  label: S.of(context).oldPin,
                  minLength: 4,
                  obscureText: !_showCurrentPin,
                  onToggleVisibility: () =>
                      setState(() => _showCurrentPin = !_showCurrentPin),
                ),
                Spacing.height(12),
                _pinField(
                  controller: _newPin,
                  label: S.of(context).newPin,
                  minLength: widget.minPinLength,
                  obscureText: !_showNewPin,
                  onToggleVisibility: () =>
                      setState(() => _showNewPin = !_showNewPin),
                ),
                Spacing.height(12),
                _pinField(
                  controller: _confirmPin,
                  label: S.of(context).confirmNewPin,
                  minLength: widget.minPinLength,
                  obscureText: !_showNewPin,
                  onFieldSubmitted: (_) =>
                      AppDialogSurface.run(context, _submit),
                  onToggleVisibility: () =>
                      setState(() => _showNewPin = !_showNewPin),
                ),
                AppDialogCheckbox(
                  value: _savePin,
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _savePin = value ?? false),
                  title: CustomizedText.bodyMedium(
                    S.of(context).savePinOnDevice,
                  ),
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
        AppDialogActions(
          children: [
            AppDialogAction(
              label: S.of(context).cancel,
              onPressed: _submitting ? null : () => Navigator.pop(context),
              secondary: true,
              destructive: false,
            ),
            AppDialogAction(
              label: S.of(context).save,
              onPressed: _submitting ? null : _submit,
              secondary: false,
              destructive: false,
            ),
          ],
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
      onTap: widget.onFocus,
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
