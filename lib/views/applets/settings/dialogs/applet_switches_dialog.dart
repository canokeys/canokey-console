import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppletSwitchesDialog extends BaseDialog {
  final CanoKey canokey;
  final Set<Func> functionSet;
  final Future<void> Function(Map<Func, bool> values) onConfirm;

  const AppletSwitchesDialog({
    super.key,
    required this.canokey,
    required this.functionSet,
    required this.onConfirm,
  });

  static Future<void> show({
    required CanoKey canokey,
    required Set<Func> functionSet,
    required Future<void> Function(Map<Func, bool> values) onConfirm,
  }) {
    return Get.dialog(
      AppletSwitchesDialog(
        canokey: canokey,
        functionSet: functionSet,
        onConfirm: onConfirm,
      ),
      barrierDismissible: false,
    );
  }

  @override
  State<AppletSwitchesDialog> createState() => _AppletSwitchesDialogState();
}

class _AppletSwitchesDialogState extends BaseDialogState<AppletSwitchesDialog>
    with UIMixin {
  late final Map<Func, bool> _initialValues;
  late final Map<Func, RxBool> _values;

  @override
  void initState() {
    super.initState();
    _initialValues = {
      if (_supports(Func.passSwitch))
        Func.passSwitch: widget.canokey.passEnabled,
      if (_supports(Func.webAuthnSwitch))
        Func.webAuthnSwitch: widget.canokey.webAuthnEnabled,
      if (_supports(Func.ndefEnabled))
        Func.ndefEnabled: widget.canokey.ndefEnabled,
      if (_supports(Func.pivCcIdSwitch))
        Func.pivCcIdSwitch: widget.canokey.pivCcIdEnabled,
      if (_supports(Func.pivNfcSwitch))
        Func.pivNfcSwitch: widget.canokey.pivNfcEnabled,
      if (_supports(Func.openPgpCcIdSwitch))
        Func.openPgpCcIdSwitch: widget.canokey.openPgpCcIdEnabled,
      if (_supports(Func.openPgpNfcSwitch))
        Func.openPgpNfcSwitch: widget.canokey.openPgpNfcEnabled,
    };
    _values = {
      for (final entry in _initialValues.entries) entry.key: entry.value.obs,
    };
  }

  @override
  Widget buildDialogContent() {
    final supportsNfc = widget.functionSet.contains(Func.nfcSwitch);

    return Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: Spacing.all(16),
            child: CustomizedText.labelLarge(
              S.of(context).settingsAppletSwitches,
            ),
          ),
          Divider(height: 0, thickness: 1),
          Padding(
            padding: Spacing.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _row('Pass', switches: {Func.passSwitch: 'Enable'}),
                Spacing.height(8),
                _row('WebAuthn', switches: {Func.webAuthnSwitch: 'Enable'}),
                Spacing.height(8),
                if (supportsNfc) ...[
                  _row('NDEF', switches: {Func.ndefEnabled: 'Enable'}),
                  Spacing.height(8),
                ],
                _row(
                  'PIV',
                  switches: supportsNfc
                      ? {Func.pivCcIdSwitch: 'USB', Func.pivNfcSwitch: 'NFC'}
                      : {Func.pivCcIdSwitch: 'Enable'},
                ),
                Spacing.height(8),
                _row(
                  'OpenPGP',
                  switches: supportsNfc
                      ? {
                          Func.openPgpCcIdSwitch: 'USB',
                          Func.openPgpNfcSwitch: 'NFC',
                        }
                      : {Func.openPgpCcIdSwitch: 'Enable'},
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
                  child: CustomizedText.labelMedium(
                    S.of(context).cancel,
                    color: contentTheme.onSecondary,
                  ),
                ),
                Spacing.width(16),
                CustomizedButton.rounded(
                  onPressed: _submit,
                  elevation: 0,
                  padding: Spacing.xy(20, 16),
                  backgroundColor: contentTheme.primary,
                  child: CustomizedText.labelMedium(
                    S.of(context).confirm,
                    color: contentTheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String title, {required Map<Func, String> switches}) {
    final availableSwitches = switches.entries
        .where((entry) => _values.containsKey(entry.key))
        .toList(growable: false);

    return Row(
      children: [
        SizedBox(
          width: 96,
          child: CustomizedText.bodySmall(title, fontWeight: 600),
        ),
        Spacing.width(12),
        Expanded(
          child: Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              if (availableSwitches.isEmpty)
                CustomizedText.bodySmall('-', xMuted: true)
              else
                for (final entry in availableSwitches)
                  _switchControl(entry.key, entry.value),
            ],
          ),
        ),
      ],
    );
  }

  Widget _switchControl(Func func, String label) {
    return InkWell(
      onTap: () => _values[func]!.toggle(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: _values[func]!.value,
            onChanged: (value) => _values[func]!.value = value ?? false,
            activeColor: contentTheme.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: getCompactDensity,
          ),
          Spacing.width(4),
          CustomizedText.bodySmall(label),
        ],
      ),
    );
  }

  bool _supports(Func func) {
    if (!widget.functionSet.contains(func)) {
      return false;
    }
    if (_featureSwitches.contains(func) &&
        !widget.canokey.featureSwitchesSupported) {
      return false;
    }
    return true;
  }

  void _submit() {
    final changed = <Func, bool>{};
    for (final entry in _values.entries) {
      if (_initialValues[entry.key] != entry.value.value) {
        changed[entry.key] = entry.value.value;
      }
    }
    widget.onConfirm(changed);
  }

  static const Set<Func> _featureSwitches = {
    Func.passSwitch,
    Func.webAuthnSwitch,
    Func.pivCcIdSwitch,
    Func.pivNfcSwitch,
    Func.openPgpCcIdSwitch,
    Func.openPgpNfcSwitch,
  };
}
