import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppletSwitchesDialog extends BaseDialog {
  @override
  double get contentWidth => AppDialogWidth.medium;
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
    return AppDialog.show(
      AppletSwitchesDialog(
        canokey: canokey,
        functionSet: functionSet,
        onConfirm: onConfirm,
      ),
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
          AppDialogHeader(
            title: S.of(context).settingsAppletSwitches,
            icon: Icons.settings_outlined,
            description: S.of(context).settingsAppletSwitchesDescription,
          ),
          Divider(height: 0, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _row('Pass', switches: {Func.passSwitch: S.of(context).enable}),
                const SizedBox.shrink(),
                _row(
                  'WebAuthn',
                  switches: {Func.webAuthnSwitch: S.of(context).enable},
                ),
                const SizedBox.shrink(),
                if (_supports(Func.ndefEnabled)) ...[
                  _row(
                    'NFC Tag',
                    switches: {Func.ndefEnabled: S.of(context).enable},
                  ),
                  const SizedBox.shrink(),
                ],
                _row(
                  'PIV',
                  switches: supportsNfc
                      ? {Func.pivCcIdSwitch: 'USB', Func.pivNfcSwitch: 'NFC'}
                      : {Func.pivCcIdSwitch: S.of(context).enable},
                ),
                const SizedBox.shrink(),
                _row(
                  'OpenPGP',
                  switches: supportsNfc
                      ? {
                          Func.openPgpCcIdSwitch: 'USB',
                          Func.openPgpNfcSwitch: 'NFC',
                        }
                      : {Func.openPgpCcIdSwitch: S.of(context).enable},
                ),
              ],
            ),
          ),
          if (errorMessage.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                label: S.of(context).confirm,
                onPressed: _submit,
                secondary: false,
                destructive: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String title, {required Map<Func, String> switches}) {
    final availableSwitches = switches.entries
        .where((entry) => _values.containsKey(entry.key))
        .toList(growable: false);

    if (availableSwitches.isEmpty) return const SizedBox.shrink();
    final icon = switch (title) {
      'Pass' => Icons.keyboard_outlined,
      'WebAuthn' => Icons.key_outlined,
      'NFC Tag' => Icons.nfc,
      'PIV' => Icons.credit_card,
      _ => Icons.lock_outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: .5),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final label = Row(
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 16),
              Expanded(child: CustomizedText.bodyMedium(title)),
            ],
          );
          final controls = Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final entry in availableSwitches)
                _switchControl(entry.key, entry.value),
            ],
          );
          if (constraints.maxWidth < 330 ||
              MediaQuery.textScalerOf(context).scale(14) > 20) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [label, const SizedBox(height: 8), controls],
            );
          }
          return Row(
            children: [
              Expanded(child: label),
              Expanded(child: controls),
            ],
          );
        },
      ),
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
