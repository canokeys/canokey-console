import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/widgets/applet_section_card.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/form_validator.dart';
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
  double get contentWidth => AppDialogWidth.large;

  @override
  bool get managesOwnScrolling => true;

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
  final RxBool busy = false.obs;

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

  @override
  void dispose() {
    validator.getController('minPinLength')?.dispose();
    super.dispose();
  }

  Future<void> _toggleAlwaysUv() async {
    if (busy.value) return;
    busy.value = true;
    try {
      if (!await _confirm(S.of(context).webauthnAlwaysUvTogglePrompt)) return;
      if (mounted && await widget.onToggleAlwaysUv()) {
        alwaysUv.value = !alwaysUv.value;
      }
    } finally {
      if (mounted) busy.value = false;
    }
  }

  Future<void> _submitMinPinLength() async {
    if (busy.value || !validator.formKey.currentState!.validate()) return;
    busy.value = true;
    try {
      final next = int.parse(validator.getController('minPinLength')!.text);
      if (await widget.onSetMinPinLength(next, forcePinChange.value)) {
        minPinLength.value = next;
        forcePinChange.value = false;
      }
    } finally {
      if (mounted) busy.value = false;
    }
  }

  Future<void> _enableLongTouch() async {
    if (busy.value) return;
    busy.value = true;
    try {
      if (!await _confirm(
        S.of(context).webauthnLongTouchEnablePrompt,
        destructive: true,
      )) {
        return;
      }
      if (mounted && await widget.onEnableLongTouch()) {
        longTouchEnabled.value = true;
      }
    } finally {
      if (mounted) busy.value = false;
    }
  }

  Future<bool> _confirm(String message, {bool destructive = false}) async {
    return await AppDialog.show<bool>(
          AppConfirmationDialog(
            title: S.of(context).warning,
            message: message,
            confirmLabel: destructive
                ? S.of(context).enable
                : S.of(context).confirm,
            destructive: destructive,
          ),
        ) ??
        false;
  }

  Widget _section(String title, Widget child, {bool accent = false}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppletStyle.surface(context),
        border: Border.all(color: AppletStyle.border(context)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppletStyle.soft(context),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: accent ? AppletStyle.accent : null,
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  @override
  Widget buildDialogContent() {
    final strings = S.of(context);
    final danger = Theme.of(context).colorScheme.error;
    return Obx(
      () => PopScope(
        canPop: !busy.value,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppDialogHeader(
              title: strings.webauthnAuthenticatorSettings,
              icon: LucideIcons.keyRound,
              closeEnabled: !busy.value,
            ),
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.alwaysUv != null) ...[
                      _section(
                        strings.webauthnUserVerification,
                        Builder(
                          builder: (controlContext) => AppDialogSwitch(
                            value: alwaysUv.value,
                            onChanged: busy.value
                                ? null
                                : (_) => AppDialogSurface.run(
                                    controlContext,
                                    _toggleAlwaysUv,
                                  ),
                            title: CustomizedText.bodyLarge(
                              strings.webauthnAlwaysUv,
                              fontWeight: 600,
                            ),
                            subtitle: CustomizedText.bodyMedium(
                              strings.webauthnAlwaysUvDescription,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (widget.minPinLength != null) ...[
                      _section(
                        strings.webauthnPinPolicy,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomizedText.bodyLarge(
                              strings.webauthnMinPinLength,
                              fontWeight: 600,
                            ),
                            const SizedBox(height: 6),
                            CustomizedText.bodyMedium(
                              strings.webauthnMinPinLengthHint(
                                minPinLength.value,
                              ),
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 10),
                            Form(
                              key: validator.formKey,
                              child: TextFormField(
                                enabled: !busy.value,
                                onTap: SmartCard.eject,
                                controller: validator.getController(
                                  'minPinLength',
                                ),
                                validator: validator.getValidator(
                                  'minPinLength',
                                ),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: strings.webauthnMinPinLength,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  isDense: true,
                                  errorMaxLines: 3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            AppDialogCheckbox(
                              value: forcePinChange.value,
                              onChanged: busy.value
                                  ? null
                                  : (value) => forcePinChange.value = value!,
                              title: CustomizedText.bodyMedium(
                                strings.webauthnForcePinChange,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: AppDialogAction(
                                label: strings.save,
                                onPressed: busy.value
                                    ? null
                                    : _submitMinPinLength,
                              ),
                            ),
                          ],
                        ),
                        accent: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: danger.withValues(alpha: .045),
                        border: Border.all(
                          color: danger.withValues(alpha: .25),
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error, color: danger, size: 30),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomizedText.bodyLarge(
                                  strings.webauthnDangerZone,
                                  fontWeight: 600,
                                  color: danger,
                                ),
                                const SizedBox(height: 8),
                                CustomizedText.bodyMedium(
                                  strings.webauthnLongTouchWarning,
                                  color: danger,
                                ),
                                const SizedBox(height: 12),
                                if (longTouchEnabled.value)
                                  CustomizedText.bodyMedium(
                                    strings.enabled,
                                    color: danger,
                                  )
                                else
                                  AppDialogAction(
                                    label: strings.enable,
                                    onPressed: busy.value
                                        ? null
                                        : _enableLongTouch,
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
                        padding: const EdgeInsets.only(top: 16),
                        child: CustomizedText.bodyMedium(
                          errorMessage.value,
                          color: errorLevel.value == 'E'
                              ? danger
                              : ContentThemeColor.warning.color,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: AppletStyle.border(context),
            ),
            AppDialogActions(
              children: [
                AppDialogAction(
                  label: strings.close,
                  secondary: true,
                  onPressed: busy.value ? null : () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
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
