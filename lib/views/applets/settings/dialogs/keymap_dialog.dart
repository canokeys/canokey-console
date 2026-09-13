import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
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
      KeymapDialog(currentState: currentState, onConfirm: onConfirm),
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
      widget.currentState?.isDefault == true
          ? _defaultSelection
          : widget.currentState?.preset?.id,
    );
  }

  @override
  Widget buildDialogContent() {
    return Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDialogHeader(
            title: S.of(context).settingsKeyboardLayout,
            icon: Icons.keyboard_outlined,
          ),
          Divider(height: 0, thickness: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: Spacing.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomizedText.bodySmall(
                    S
                        .of(context)
                        .settingsKeyboardLayoutCurrent(
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
                  if (widget.currentState != null &&
                      !widget.currentState!.isDefault &&
                      !widget.currentState!.isKnownPreset) ...[
                    Spacing.height(8),
                    Container(
                      width: double.infinity,
                      padding: Spacing.all(12),
                      decoration: BoxDecoration(
                        color: ContentThemeColor.warning.color.withValues(
                          alpha: 0.12,
                        ),
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
                      color: errorLevel.value == 'E'
                          ? ContentThemeColor.danger.color
                          : ContentThemeColor.warning.color,
                    ),
                  ],
                ],
              ),
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
                onPressed: selectedId.value == null ? null : _confirm,
                secondary: false,
                destructive: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetTile(KeyboardKeymapPreset preset) {
    final selectionValue = preset.id ?? _defaultSelection;
    return AppDialogChoice(
      title: preset.name,
      selected: selectedId.value == selectionValue,
      onTap: () => selectedId.value = selectionValue,
      subtitle: preset.description,
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
