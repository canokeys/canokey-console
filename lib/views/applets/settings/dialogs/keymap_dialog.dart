import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/keyboard_keymap.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class KeymapDialog extends BaseDialog with UIMixin {
  final KeyboardKeymapState? currentState;
  final Function(KeyboardKeymapPreset) onConfirm;

  const KeymapDialog({
    super.key,
    required this.currentState,
    required this.onConfirm,
  });

  @override
  bool get managesOwnScrolling => true;

  static Future<void> show({
    required KeyboardKeymapState? currentState,
    required Function(KeyboardKeymapPreset) onConfirm,
  }) {
    return AppDialog.show(
      KeymapDialog(
        currentState: currentState,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<KeymapDialog> createState() => _KeymapDialogState();
}

class _KeymapDialogState extends BaseDialogState<KeymapDialog> with UIMixin {
  static const int _defaultSelection = -1;

  late final Rxn<int> selectedId;

  @override
  void initState() {
    super.initState();
    selectedId = Rxn<int>(
      widget.currentState?.isDefault == true ? _defaultSelection : widget.currentState?.preset?.id,
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
            child: CustomizedText.labelLarge(S.of(context).settingsKeyboardLayout),
          ),
          Divider(height: 0, thickness: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: Spacing.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomizedText.bodySmall(
                    S.of(context).settingsKeyboardLayoutCurrent(
                          widget.currentState?.displayName(
                                S.of(context).settingsKeyboardLayoutDefault,
                                S.of(context).settingsKeyboardLayoutCustom,
                              ) ??
                              S.of(context).settingsKeyboardLayoutUnknown,
                        ),
                    color: contentTheme.onBackground.withValues(alpha: 0.75),
                  ),
                  Spacing.height(16),
                  ...KeyboardKeymapPresets.presets.map(_buildPresetTile),
                  if (widget.currentState != null && !widget.currentState!.isDefault && !widget.currentState!.isKnownPreset) ...[
                    Spacing.height(8),
                    Container(
                      width: double.infinity,
                      padding: Spacing.all(12),
                      decoration: BoxDecoration(
                        color: ContentThemeColor.warning.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomizedText.bodySmall(
                        S.of(context).settingsKeyboardLayoutUnknownPrompt,
                        color: ContentThemeColor.warning.color,
                      ),
                    ),
                  ],
                  if (errorMessage.value.isNotEmpty) ...[
                    Spacing.height(12),
                    CustomizedText.bodyMedium(
                      errorMessage.value,
                      color: errorLevel.value == 'E' ? ContentThemeColor.danger.color : ContentThemeColor.warning.color,
                    ),
                  ],
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
                  onPressed: () => Navigator.pop(context),
                  elevation: 0,
                  padding: Spacing.xy(20, 16),
                  backgroundColor: contentTheme.secondary,
                  child: CustomizedText.labelMedium(S.of(context).cancel, color: contentTheme.onSecondary),
                ),
                Spacing.width(16),
                CustomizedButton.rounded(
                  onPressed: selectedId.value == null ? null : _confirm,
                  elevation: 0,
                  padding: Spacing.xy(20, 16),
                  backgroundColor: selectedId.value == null ? contentTheme.secondary : contentTheme.primary,
                  child: CustomizedText.labelMedium(S.of(context).confirm, color: selectedId.value == null ? contentTheme.onSecondary : contentTheme.onPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetTile(KeyboardKeymapPreset preset) {
    final selectionValue = preset.id ?? _defaultSelection;
    return RadioListTile<int>(
      value: selectionValue,
      groupValue: selectedId.value,
      onChanged: (value) => selectedId.value = value,
      activeColor: contentTheme.primary,
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: CustomizedText.bodyMedium(preset.name, fontWeight: 600),
      subtitle: CustomizedText.bodySmall(preset.description),
    );
  }

  void _confirm() {
    final selected = selectedId.value;
    final preset = selected == _defaultSelection
        ? KeyboardKeymapPresets.defaultPreset
        : KeyboardKeymapPresets.presets.firstWhere(
            (preset) => preset.id == selected,
            orElse: () => KeyboardKeymapPresets.defaultPreset,
          );
    widget.onConfirm(preset);
  }
}
