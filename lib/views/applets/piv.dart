import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:canokey_console/src/rust/api/crypto.dart';

import 'package:basic_utils/basic_utils.dart';
import 'package:canokey_console/controller/applets/piv/piv_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_style.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/shadow.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_card.dart';
import 'package:canokey_console/helper/widgets/customized_container.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/field_validator.dart';
import 'package:canokey_console/helper/widgets/form_validator.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:canokey_console/views/applets/settings/widgets/info_item.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:convert/convert.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';

class PivPage extends StatefulWidget {
  const PivPage({super.key});

  @override
  State<PivPage> createState() => _PivPageState();
}

class _PivPageState extends State<PivPage>
    with SingleTickerProviderStateMixin, UIMixin {
  late PivController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(PivController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshSlots();
    });
  }

  Future<void> _refreshSlots() async {
    Get.context!.loaderOverlay.show();
    try {
      await controller.refreshData();
    } finally {
      Get.context!.loaderOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      title: 'PIV',
      topActions: InkWell(
        onTap: _refreshSlots,
        child: Icon(LucideIcons.refreshCw,
            size: 20, color: topBarTheme.onBackground),
      ),
      child: GetBuilder(
        init: controller,
        builder: (_) {
          if (!controller.polled) {
            return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Spacing.height(MediaQuery.of(context).size.height / 2 - 120),
                  Center(
                      child: Padding(
                    padding: Spacing.horizontal(36),
                    child: CustomizedText.bodyMedium(S.of(context).pollCanoKey,
                        fontSize: 24),
                  ))
                ]);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.x(flexSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Spacing.height(20),
                    CustomizedCard(
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      shadow: Shadow(
                          elevation: 0.5, position: ShadowPosition.bottom),
                      paddingAll: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            color: contentTheme.primary.withValues(alpha: 0.2),
                            padding: Spacing.xy(16, 12),
                            child: Row(
                              children: [
                                Icon(LucideIcons.keyboard,
                                    color: contentTheme.primary, size: 16),
                                Spacing.width(12),
                                CustomizedText.titleMedium(
                                    S.of(context).pivPinManagement,
                                    fontWeight: 600,
                                    color: contentTheme.primary)
                              ],
                            ),
                          ),
                          Padding(
                            padding: Spacing.xy(flexSpacing, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InfoItem(
                                  iconData: LucideIcons.lock,
                                  title: 'PIN',
                                  value:
                                      _credentialRetryValue(controller.pinInfo),
                                ),
                                Spacing.height(16),
                                InfoItem(
                                  iconData: LucideIcons.keyRound,
                                  title: 'PUK',
                                  value:
                                      _credentialRetryValue(controller.pukInfo),
                                ),
                                Spacing.height(16),
                                InfoItem(
                                  iconData: LucideIcons.shieldCheck,
                                  title: 'PIN-only mode',
                                  value: controller.pinOnlyMode
                                      ? S.of(context).on
                                      : S.of(context).off,
                                  onTap: controller.pinOnlyMode
                                      ? _showDisablePinOnlyDialog
                                      : _showEnablePinOnlyDialog,
                                ),
                                Spacing.height(16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    CustomizedButton(
                                      onPressed: () {
                                        _showChangePinDialog(
                                          title: S.of(context).changePin,
                                          oldValueLabel: S.of(context).oldPin,
                                          newValueLabel: S.of(context).newPin,
                                          prompt: S
                                              .of(context)
                                              .changePinPrompt(6, 8),
                                          validators: [
                                            LengthValidator(min: 6, max: 8)
                                          ],
                                          handler: controller.changePin,
                                        );
                                      },
                                      elevation: 0,
                                      padding: Spacing.xy(20, 16),
                                      backgroundColor: contentTheme.primary,
                                      borderRadiusAll:
                                          AppStyle.buttonRadius.medium,
                                      child: CustomizedText.bodySmall(
                                          S.of(context).changePin,
                                          color: contentTheme.onPrimary),
                                    ),
                                    CustomizedButton(
                                      onPressed: () {
                                        _showChangePinDialog(
                                          title: S.of(context).pivChangePUK,
                                          oldValueLabel:
                                              S.of(context).pivOldPUK,
                                          newValueLabel:
                                              S.of(context).pivNewPUK,
                                          prompt: S
                                              .of(context)
                                              .pivChangePUKPrompt(6, 8),
                                          validators: [
                                            LengthValidator(min: 6, max: 8)
                                          ],
                                          handler: controller.changePUK,
                                        );
                                      },
                                      elevation: 0,
                                      padding: Spacing.xy(20, 16),
                                      backgroundColor: contentTheme.primary,
                                      borderRadiusAll:
                                          AppStyle.buttonRadius.medium,
                                      child: CustomizedText.bodySmall(
                                          S.of(context).pivChangePUK,
                                          color: contentTheme.onPrimary),
                                    ),
                                    CustomizedButton(
                                      onPressed: _showChangeManagementKeyDialog,
                                      elevation: 0,
                                      padding: Spacing.xy(20, 16),
                                      backgroundColor: contentTheme.primary,
                                      borderRadiusAll:
                                          AppStyle.buttonRadius.medium,
                                      child: CustomizedText.bodySmall(
                                          S.of(context).pivChangeManagementKey,
                                          color: contentTheme.onPrimary),
                                    ),
                                    CustomizedButton(
                                      onPressed: _showSetPinRetriesDialog,
                                      elevation: 0,
                                      padding: Spacing.xy(20, 16),
                                      backgroundColor: contentTheme.primary,
                                      borderRadiusAll:
                                          AppStyle.buttonRadius.medium,
                                      child: CustomizedText.bodySmall(
                                          'Set PIN/PUK Retries',
                                          color: contentTheme.onPrimary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacing.height(20),
                    CustomizedCard(
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      shadow: Shadow(
                          elevation: 0.5, position: ShadowPosition.bottom),
                      paddingAll: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            color: contentTheme.primary.withValues(alpha: 0.2),
                            padding: Spacing.xy(16, 12),
                            child: Row(
                              children: [
                                Icon(LucideIcons.keyboard,
                                    color: contentTheme.primary, size: 16),
                                Spacing.width(12),
                                CustomizedText.titleMedium(
                                    S.of(context).pivSlots,
                                    fontWeight: 600,
                                    color: contentTheme.primary)
                              ],
                            ),
                          ),
                          Padding(
                              padding: Spacing.xy(flexSpacing, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ..._buildSlotList(),
                                ],
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePinDialog({
    required String title,
    required String oldValueLabel,
    required String newValueLabel,
    required String prompt,
    List<FieldValidatorRule> validators = const [],
    required Function(String, String) handler,
  }) {
    RxBool showOldPin = false.obs;
    RxBool showNewPin = false.obs;
    FormValidator validator = FormValidator();
    validator.addField('old',
        required: true,
        controller: TextEditingController(),
        validators: validators);
    validator.addField('new',
        required: true,
        controller: TextEditingController(),
        validators: validators);

    Get.dialog(Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(title),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
                padding: Spacing.all(16),
                child: Form(
                    key: validator.formKey,
                    child: Column(
                      children: [
                        CustomizedText.bodyMedium(prompt),
                        Spacing.height(16),
                        Obx(() => TextFormField(
                              autofocus: true,
                              onTap: SmartCard.eject,
                              obscureText: !showOldPin.value,
                              controller: validator.getController('old'),
                              validator: validator.getValidator('old'),
                              decoration: InputDecoration(
                                labelText: oldValueLabel,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(4)),
                                  borderSide: BorderSide(
                                      width: 1,
                                      strokeAlign: 0,
                                      color: AppTheme
                                          .theme.colorScheme.onSurface
                                          .withAlpha(80)),
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      showOldPin.value = !showOldPin.value,
                                  icon: Icon(showOldPin.value
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined),
                                ),
                              ),
                            )),
                        Spacing.height(16),
                        Obx(() => TextFormField(
                              onTap: SmartCard.eject,
                              obscureText: !showNewPin.value,
                              controller: validator.getController('new'),
                              validator: validator.getValidator('new'),
                              decoration: InputDecoration(
                                labelText: newValueLabel,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(4)),
                                  borderSide: BorderSide(
                                      width: 1,
                                      strokeAlign: 0,
                                      color: AppTheme
                                          .theme.colorScheme.onSurface
                                          .withAlpha(80)),
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      showNewPin.value = !showNewPin.value,
                                  icon: Icon(showNewPin.value
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined),
                                ),
                              ),
                            )),
                      ],
                    ))),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomizedButton.rounded(
                    onPressed: () => Navigator.pop(Get.context!),
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: ContentThemeColor.secondary.color,
                    child: CustomizedText.labelMedium(S.of(Get.context!).cancel,
                        color: ContentThemeColor.secondary.onColor),
                  ),
                  Spacing.width(16),
                  CustomizedButton.rounded(
                    onPressed: () {
                      if (validator.validateForm()) {
                        handler(validator.getController('old')!.text,
                            validator.getController('new')!.text);
                      }
                    },
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: ContentThemeColor.primary.color,
                    child: CustomizedText.labelMedium(
                        S.of(Get.context!).confirm,
                        color: ContentThemeColor.primary.onColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  String _credentialRetryValue(SlotInfo? info) {
    if (info == null) {
      return 'Retries: unknown';
    }
    return 'Retries: ${info.remainingCount}/${info.retriesCount}';
  }

  Widget _buildManagementKeyField(
    FormValidator validator,
    String field, {
    bool enabled = true,
    String? label,
  }) {
    return Row(children: [
      Expanded(
        child: TextFormField(
          onTap: SmartCard.eject,
          enabled: enabled,
          controller: validator.getController(field),
          validator: validator.getValidator(field),
          decoration: InputDecoration(
              labelText: label ?? S.of(context).pivManagementKey,
              border: outlineInputBorder),
        ),
      ),
      Spacing.width(8),
      CustomizedButton(
        onPressed: enabled
            ? () {
                validator.getController(field)!.text =
                    '010203040506070801020304050607080102030405060708';
              }
            : null,
        elevation: 0,
        backgroundColor: ContentThemeColor.primary.color,
        minSize: WidgetStatePropertyAll(Size(104, 48)),
        child: CustomizedText.labelMedium(
            S.of(context).pivUseDefaultManagementKey,
            color: ContentThemeColor.primary.onColor),
      ),
    ]);
  }

  bool _validateManagementKeyInput(
      FormValidator validator, String field, bool usePinOnly) {
    if (usePinOnly) {
      return true;
    }
    final value = validator.getController(field)!.text;
    if (value.length != 48 || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(value)) {
      Prompts.showPrompt(
          '${S.of(context).pivManagementKey}: ${S.of(context).validationHexString}',
          ContentThemeColor.danger);
      return false;
    }
    return true;
  }

  void _showSetPinRetriesDialog() {
    bool usePinOnly = controller.pinOnlyMode;
    FormValidator validator = FormValidator();
    validator.addField('pin',
        required: true,
        controller: TextEditingController(),
        validators: [LengthValidator(min: 6, max: 8)]);
    validator.addField('managementKey',
        required: !usePinOnly,
        controller: TextEditingController(),
        validators: [
          LengthValidator(exact: 48, required: !usePinOnly),
          HexStringValidator(required: !usePinOnly)
        ]);
    validator.addField('pinRetries',
        required: true,
        controller: TextEditingController(
            text: (controller.pinInfo?.retriesCount ?? 3).toString()),
        validators: [IntValidator(min: 1, max: 15)]);
    validator.addField('pukRetries',
        required: true,
        controller: TextEditingController(
            text: (controller.pukInfo?.retriesCount ?? 3).toString()),
        validators: [IntValidator(min: 1, max: 15)]);

    Get.dialog(Dialog(
      child: StatefulBuilder(
        builder: (context, setDialogState) => SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.all(16),
                child: CustomizedText.labelLarge('Set PIN/PUK Retries'),
              ),
              Divider(height: 0, thickness: 1),
              Padding(
                padding: Spacing.all(16),
                child: Form(
                  key: validator.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomizedText.bodySmall(
                        'This resets PIN to 123456 and PUK to 12345678.',
                        color: contentTheme.danger,
                      ),
                      Spacing.height(16),
                      TextFormField(
                        autofocus: true,
                        onTap: SmartCard.eject,
                        obscureText: true,
                        controller: validator.getController('pin'),
                        validator: validator.getValidator('pin'),
                        decoration: InputDecoration(
                            labelText: 'Current PIN',
                            border: outlineInputBorder),
                      ),
                      if (controller.pinOnlyMode) ...[
                        Spacing.height(12),
                        CheckboxListTile(
                          value: usePinOnly,
                          onChanged: (value) =>
                              setDialogState(() => usePinOnly = value ?? true),
                          contentPadding: EdgeInsets.zero,
                          title: Text('Use PIN-only management key'),
                        ),
                      ],
                      Spacing.height(16),
                      _buildManagementKeyField(
                        validator,
                        'managementKey',
                        enabled: !usePinOnly,
                      ),
                      Spacing.height(16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: validator.getController('pinRetries'),
                              validator: validator.getValidator('pinRetries'),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: 'PIN retries',
                                  border: outlineInputBorder),
                            ),
                          ),
                          Spacing.width(16),
                          Expanded(
                            child: TextFormField(
                              controller: validator.getController('pukRetries'),
                              validator: validator.getValidator('pukRetries'),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: 'PUK retries',
                                  border: outlineInputBorder),
                            ),
                          ),
                        ],
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
                      onPressed: () => Get.back(),
                      elevation: 0,
                      backgroundColor: contentTheme.secondary,
                      child: CustomizedText.labelMedium(S.of(context).cancel,
                          color: contentTheme.onSecondary),
                    ),
                    Spacing.width(12),
                    CustomizedButton.rounded(
                      onPressed: () async {
                        if (!validator.validateForm()) return;
                        if (!_validateManagementKeyInput(
                            validator, 'managementKey', usePinOnly)) {
                          return;
                        }
                        Get.context!.loaderOverlay.show();
                        try {
                          final ok = await controller.setPinRetries(
                            validator.getController('pin')!.text,
                            validator.getController('managementKey')!.text,
                            int.parse(
                                validator.getController('pinRetries')!.text),
                            int.parse(
                                validator.getController('pukRetries')!.text),
                            usePinOnly,
                          );
                          if (!ok) {
                            Prompts.showPrompt(
                                'Set retries failed', ContentThemeColor.danger);
                            return;
                          }
                          await controller.refreshData();
                          Prompts.showPrompt(
                              'PIN/PUK retries set. PIN and PUK were reset.',
                              ContentThemeColor.success);
                          Get.back();
                        } finally {
                          Get.context!.loaderOverlay.hide();
                        }
                      },
                      elevation: 0,
                      backgroundColor: contentTheme.primary,
                      child: CustomizedText.labelMedium('Confirm',
                          color: contentTheme.onPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  void _showEnablePinOnlyDialog() {
    FormValidator validator = FormValidator();
    validator.addField('pin',
        required: true,
        controller: TextEditingController(),
        validators: [LengthValidator(min: 6, max: 8)]);
    validator.addField('managementKey',
        required: true,
        controller: TextEditingController(),
        validators: [LengthValidator(exact: 48), HexStringValidator()]);

    Get.dialog(Dialog(
      child: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge('Enable PIN-only Mode'),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Form(
                key: validator.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomizedText.bodySmall(
                      'A random management key will be set and stored on the card, protected by PIN.',
                    ),
                    Spacing.height(16),
                    TextFormField(
                      autofocus: true,
                      onTap: SmartCard.eject,
                      obscureText: true,
                      controller: validator.getController('pin'),
                      validator: validator.getValidator('pin'),
                      decoration: InputDecoration(
                          labelText: 'PIN', border: outlineInputBorder),
                    ),
                    Spacing.height(16),
                    _buildManagementKeyField(
                      validator,
                      'managementKey',
                      label: 'Current Management Key',
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
                    onPressed: () => Get.back(),
                    elevation: 0,
                    backgroundColor: contentTheme.secondary,
                    child: CustomizedText.labelMedium(S.of(context).cancel,
                        color: contentTheme.onSecondary),
                  ),
                  Spacing.width(12),
                  CustomizedButton.rounded(
                    onPressed: () async {
                      if (!validator.validateForm()) return;
                      Get.context!.loaderOverlay.show();
                      try {
                        final ok = await controller.enablePinOnlyMode(
                          validator.getController('pin')!.text,
                          validator.getController('managementKey')!.text,
                        );
                        if (!ok) {
                          Prompts.showPrompt('Enable PIN-only failed',
                              ContentThemeColor.danger);
                          return;
                        }
                        await controller.refreshData();
                        Prompts.showPrompt(
                            'PIN-only mode enabled', ContentThemeColor.success);
                        Get.back();
                      } finally {
                        Get.context!.loaderOverlay.hide();
                      }
                    },
                    elevation: 0,
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium('Enable',
                        color: contentTheme.onPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  void _showDisablePinOnlyDialog() {
    bool usePinOnly = controller.pinOnlyMode;
    FormValidator validator = FormValidator();
    validator.addField('pin',
        required: true,
        controller: TextEditingController(),
        validators: [LengthValidator(min: 6, max: 8)]);
    validator.addField('currentManagementKey',
        required: !usePinOnly,
        controller: TextEditingController(),
        validators: [
          LengthValidator(exact: 48, required: !usePinOnly),
          HexStringValidator(required: !usePinOnly)
        ]);
    validator.addField('newManagementKey',
        required: true,
        controller: TextEditingController(),
        validators: [LengthValidator(exact: 48), HexStringValidator()]);

    Get.dialog(Dialog(
      child: StatefulBuilder(
        builder: (context, setDialogState) => SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.all(16),
                child: CustomizedText.labelLarge('Disable PIN-only Mode'),
              ),
              Divider(height: 0, thickness: 1),
              Padding(
                padding: Spacing.all(16),
                child: Form(
                  key: validator.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomizedText.bodySmall(
                        'A new management key will be set before the PIN-protected copy is cleared.',
                      ),
                      Spacing.height(16),
                      TextFormField(
                        autofocus: true,
                        onTap: SmartCard.eject,
                        obscureText: true,
                        controller: validator.getController('pin'),
                        validator: validator.getValidator('pin'),
                        decoration: InputDecoration(
                            labelText: 'PIN', border: outlineInputBorder),
                      ),
                      Spacing.height(12),
                      CheckboxListTile(
                        value: usePinOnly,
                        onChanged: (value) =>
                            setDialogState(() => usePinOnly = value ?? true),
                        contentPadding: EdgeInsets.zero,
                        title: Text('Use PIN-only management key'),
                      ),
                      Spacing.height(16),
                      _buildManagementKeyField(
                        validator,
                        'currentManagementKey',
                        enabled: !usePinOnly,
                        label: 'Current Management Key',
                      ),
                      Spacing.height(16),
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            onTap: SmartCard.eject,
                            controller:
                                validator.getController('newManagementKey'),
                            validator:
                                validator.getValidator('newManagementKey'),
                            decoration: InputDecoration(
                                labelText: 'New Management Key',
                                border: outlineInputBorder),
                          ),
                        ),
                        Spacing.width(8),
                        CustomizedButton(
                          onPressed: () {
                            final random = Random.secure();
                            validator.getController('newManagementKey')!.text =
                                hex.encode(List<int>.generate(
                                    24, (_) => random.nextInt(256)));
                          },
                          elevation: 0,
                          backgroundColor: ContentThemeColor.primary.color,
                          minSize: WidgetStatePropertyAll(Size(92, 48)),
                          child: CustomizedText.labelMedium(
                              S.of(context).pivRandomManagementKey,
                              color: ContentThemeColor.primary.onColor),
                        ),
                      ]),
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
                      onPressed: () => Get.back(),
                      elevation: 0,
                      backgroundColor: contentTheme.secondary,
                      child: CustomizedText.labelMedium(S.of(context).cancel,
                          color: contentTheme.onSecondary),
                    ),
                    Spacing.width(12),
                    CustomizedButton.rounded(
                      onPressed: () async {
                        if (!validator.validateForm()) return;
                        if (!_validateManagementKeyInput(
                            validator, 'currentManagementKey', usePinOnly)) {
                          return;
                        }
                        Get.context!.loaderOverlay.show();
                        try {
                          final ok = await controller.disablePinOnlyMode(
                            validator.getController('pin')!.text,
                            validator
                                .getController('currentManagementKey')!
                                .text,
                            validator.getController('newManagementKey')!.text,
                            usePinOnly,
                          );
                          if (!ok) {
                            Prompts.showPrompt('Disable PIN-only failed',
                                ContentThemeColor.danger);
                            return;
                          }
                          await controller.refreshData();
                          Prompts.showPrompt('PIN-only mode disabled',
                              ContentThemeColor.success);
                          Get.back();
                        } finally {
                          Get.context!.loaderOverlay.hide();
                        }
                      },
                      elevation: 0,
                      backgroundColor: contentTheme.primary,
                      child: CustomizedText.labelMedium('Disable',
                          color: contentTheme.onPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Future<String> showVerifyManagementKeyDialog() {
    Completer<String> c = new Completer<String>();

    FormValidator validator = FormValidator();
    validator.addField('key',
        required: true,
        controller: TextEditingController(),
        validators: [LengthValidator(exact: 48), HexStringValidator()]);

    Get.dialog(Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: Spacing.all(16),
                child: CustomizedText.labelLarge(
                    S.of(context).pivVerifyManagementKey)),
            Divider(height: 0, thickness: 1),
            Padding(
                padding: Spacing.all(16),
                child: Form(
                    key: validator.formKey,
                    child: Column(children: [
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            autofocus: true,
                            onTap: SmartCard.eject,
                            controller: validator.getController('key'),
                            validator: validator.getValidator('key'),
                            decoration: InputDecoration(
                              labelText: S.of(context).pivManagementKey,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4)),
                                borderSide: BorderSide(
                                    width: 1,
                                    strokeAlign: 0,
                                    color: AppTheme.theme.colorScheme.onSurface
                                        .withAlpha(80)),
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                            ),
                          ),
                        ),
                        Spacing.width(8),
                        CustomizedButton(
                          onPressed: () {
                            validator.getController('key')!.text =
                                '010203040506070801020304050607080102030405060708';
                          },
                          elevation: 0,
                          padding: Spacing.xy(8, 16),
                          backgroundColor: ContentThemeColor.primary.color,
                          child: CustomizedText.labelMedium(
                              S.of(context).pivUseDefaultManagementKey,
                              color: ContentThemeColor.primary.onColor),
                        ),
                      ]),
                    ]))),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomizedButton.rounded(
                    onPressed: () {
                      c.completeError(UserCanceledError());
                      Navigator.pop(Get.context!);
                    },
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: ContentThemeColor.secondary.color,
                    child: CustomizedText.labelMedium(S.of(Get.context!).cancel,
                        color: ContentThemeColor.secondary.onColor),
                  ),
                  Spacing.width(16),
                  CustomizedButton.rounded(
                    onPressed: () async {
                      if (validator.validateForm()) {
                        final key = validator.getController('key')!.text;
                        c.complete(key);
                        Navigator.pop(Get.context!);
                      }
                    },
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: ContentThemeColor.primary.color,
                    child: CustomizedText.labelMedium(
                        S.of(Get.context!).confirm,
                        color: ContentThemeColor.primary.onColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));

    return c.future;
  }

  void _showChangeManagementKeyDialog() {
    bool usePinOnly = controller.pinOnlyMode;
    bool storeOnDevice = controller.pinOnlyMode;
    FormValidator validator = FormValidator();
    validator.addField('pin',
        required: controller.pinOnlyMode,
        controller: TextEditingController(),
        validators: [LengthValidator(min: 6, max: 8)]);
    validator.addField('old',
        required: !usePinOnly,
        controller: TextEditingController(),
        validators: [
          LengthValidator(exact: 48, required: !usePinOnly),
          HexStringValidator(required: !usePinOnly)
        ]);
    validator.addField('new',
        required: true,
        controller: TextEditingController(),
        validators: [LengthValidator(exact: 48), HexStringValidator()]);

    Get.dialog(Dialog(
      child: StatefulBuilder(
        builder: (context, setDialogState) => SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.all(16),
                child: CustomizedText.labelLarge(
                    S.of(context).pivChangeManagementKey),
              ),
              Divider(height: 0, thickness: 1),
              Padding(
                  padding: Spacing.all(16),
                  child: Form(
                      key: validator.formKey,
                      child: Column(children: [
                        CustomizedText.bodyMedium(
                            S.of(context).pivChangeManagementKeyPrompt),
                        if (controller.pinOnlyMode) ...[
                          Spacing.height(16),
                          TextFormField(
                            autofocus: true,
                            onTap: SmartCard.eject,
                            obscureText: true,
                            controller: validator.getController('pin'),
                            validator: validator.getValidator('pin'),
                            decoration: InputDecoration(
                                labelText: 'PIN', border: outlineInputBorder),
                          ),
                          Spacing.height(12),
                          CheckboxListTile(
                            value: usePinOnly,
                            onChanged: (value) => setDialogState(
                                () => usePinOnly = value ?? true),
                            contentPadding: EdgeInsets.zero,
                            title: Text('Use PIN-only management key'),
                          ),
                        ],
                        Spacing.height(16),
                        _buildManagementKeyField(
                          validator,
                          'old',
                          enabled: !usePinOnly,
                          label: S.of(context).pivOldManagementKey,
                        ),
                        Spacing.height(16),
                        Row(children: [
                          Expanded(
                            child: TextFormField(
                              onTap: SmartCard.eject,
                              controller: validator.getController('new'),
                              validator: validator.getValidator('new'),
                              decoration: InputDecoration(
                                  labelText: S.of(context).pivNewManagementKey,
                                  border: outlineInputBorder),
                            ),
                          ),
                          Spacing.width(8),
                          CustomizedButton(
                            onPressed: () {
                              final random = Random.secure();
                              final values = List<int>.generate(
                                  24, (i) => random.nextInt(256));
                              validator.getController('new')!.text =
                                  hex.encode(values);
                            },
                            elevation: 0,
                            backgroundColor: ContentThemeColor.primary.color,
                            minSize: WidgetStatePropertyAll(Size(92, 48)),
                            child: CustomizedText.labelMedium(
                                S.of(context).pivRandomManagementKey,
                                color: ContentThemeColor.primary.onColor),
                          ),
                        ]),
                        if (controller.pinOnlyMode) ...[
                          Spacing.height(12),
                          CheckboxListTile(
                            value: storeOnDevice,
                            onChanged: (value) => setDialogState(
                                () => storeOnDevice = value ?? true),
                            contentPadding: EdgeInsets.zero,
                            title: Text('Keep PIN-only mode enabled'),
                          ),
                        ],
                      ]))),
              Divider(height: 0, thickness: 1),
              Padding(
                padding: Spacing.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomizedButton.rounded(
                      onPressed: () {
                        Navigator.pop(Get.context!);
                      },
                      elevation: 0,
                      padding: Spacing.xy(20, 16),
                      backgroundColor: ContentThemeColor.secondary.color,
                      child: CustomizedText.labelMedium(
                          S.of(Get.context!).cancel,
                          color: ContentThemeColor.secondary.onColor),
                    ),
                    Spacing.width(16),
                    CustomizedButton.rounded(
                      onPressed: () async {
                        if (!validator.validateForm()) return;
                        if (!_validateManagementKeyInput(
                            validator, 'old', usePinOnly)) {
                          return;
                        }
                        Get.context!.loaderOverlay.show();
                        try {
                          final ok = await controller.changeManagementKey(
                            validator.getController('old')!.text,
                            validator.getController('new')!.text,
                            pin: validator.getController('pin')?.text ?? '',
                            usePinOnly: usePinOnly,
                            storeOnDevice: storeOnDevice,
                          );
                          if (!ok) {
                            Prompts.showPrompt(
                                S
                                    .of(Get.context!)
                                    .pivManagementKeyVerificationFailed,
                                ContentThemeColor.danger);
                            return;
                          }
                          await controller.refreshData();
                          Navigator.pop(Get.context!);
                          Prompts.showPrompt(
                              S.of(Get.context!).successfullyChanged,
                              ContentThemeColor.success);
                        } finally {
                          Get.context!.loaderOverlay.hide();
                        }
                      },
                      elevation: 0,
                      padding: Spacing.xy(20, 16),
                      backgroundColor: ContentThemeColor.primary.color,
                      child: CustomizedText.labelMedium(
                          S.of(Get.context!).confirm,
                          color: ContentThemeColor.primary.onColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildInfo(String title, String slotNumber, SlotInfo? slot) {
    return InkWell(
      onTap: () {
        _showSlotDetailDialog(title, slotNumber, slot);
      },
      child: Row(
        children: [
          CustomizedContainer(
            paddingAll: 4,
            height: 32,
            width: 32,
            child: Icon(LucideIcons.fileLock, size: 20),
          ),
          Spacing.width(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomizedText.bodyMedium('$title - $slotNumber', fontSize: 16),
                if (slot != null) ...[
                  InkWell(
                      child: CustomizedText.bodySmall(
                          '${S.of(context).pivAlgorithm}: ${slot.algorithm.name.toUpperCase()}')),
                  InkWell(
                      child: CustomizedText.bodySmall(
                          '${S.of(context).pivCertificate}: ${slot.cert?.subject.isNotEmpty == true ? slot.cert!.subject : S.of(context).pivEmpty}')),
                ] else ...[
                  CustomizedText.bodySmall(S.of(context).pivEmpty),
                ],
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios)
        ],
      ),
    );
  }

  List<Widget> _buildSlotList() {
    final slots = [
      (title: S.of(context).pivAuthentication, number: '9A'),
      (title: S.of(context).pivSignature, number: '9C'),
      (title: S.of(context).pivKeyManagement, number: '9D'),
      (title: S.of(context).pivCardAuthentication, number: '9E'),
      for (final slot in _retiredSlots())
        (
          title: _retiredSlotTitle(slot - 0x81),
          number: slot.toRadixString(16).toUpperCase()
        ),
    ];

    return [
      for (var index = 0; index < slots.length; index++) ...[
        _buildInfo(
          slots[index].title,
          slots[index].number,
          controller.slots[int.parse(slots[index].number, radix: 16)],
        ),
        if (index != slots.length - 1) Spacing.height(16),
      ]
    ];
  }

  List<int> _retiredSlots() {
    if (!controller.extendedRetiredSlots) {
      return [0x82, 0x83];
    }
    return [for (var slot = 0x82; slot <= 0x95; slot++) slot];
  }

  String _retiredSlotTitle(int index) {
    if (Localizations.localeOf(context).languageCode == 'zh') {
      return '过期证书 $index';
    }
    return 'Retired $index';
  }

  void _showSlotDetailDialog(String title, String slotNumber, SlotInfo? slot) {
    Get.dialog(Dialog(
      child: SizedBox(
        width: slot == null
            ? 400
            : max(430, MediaQuery.of(context).size.width * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge('$title - $slotNumber'),
            ),
            Divider(height: 0, thickness: 1),
            if (slot != null && slot.cert != null) ...[
              Padding(
                  padding: Spacing.all(16),
                  child: Form(
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: slot.cert!.subject,
                          readOnly: true,
                          decoration: InputDecoration(
                              labelText: 'Subject',
                              border: outlineInputBorder,
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.auto),
                        ),
                        Spacing.height(16),
                        TextFormField(
                          initialValue: slot.cert!.issuer,
                          readOnly: true,
                          decoration: InputDecoration(
                              labelText: 'Issuer',
                              border: outlineInputBorder,
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.auto),
                        ),
                        Spacing.height(16),
                        TextFormField(
                          initialValue: slot.cert!.serialNumber,
                          readOnly: true,
                          decoration: InputDecoration(
                              labelText: 'Serial',
                              border: outlineInputBorder,
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.auto),
                        ),
                        Spacing.height(16),
                        TextFormField(
                          initialValue: slot.cert!.signatureAlgorithm,
                          readOnly: true,
                          decoration: InputDecoration(
                              labelText: 'Fingerprint Algorithm',
                              border: outlineInputBorder,
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.auto),
                        ),
                        Spacing.height(16),
                        TextFormField(
                          initialValue: hex.encode(slot.cert!.signatureValue),
                          readOnly: true,
                          decoration: InputDecoration(
                              labelText: 'Fingerprint',
                              border: outlineInputBorder,
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.auto),
                        ),
                        Spacing.height(16),
                        TextFormField(
                          initialValue: slot.cert!.notBefore,
                          readOnly: true,
                          decoration: InputDecoration(
                              labelText: 'Valid from',
                              border: outlineInputBorder,
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.auto),
                        ),
                        Spacing.height(16),
                        TextFormField(
                          initialValue: slot.cert!.notAfter,
                          readOnly: true,
                          decoration: InputDecoration(
                              labelText: 'Valid to',
                              border: outlineInputBorder,
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.auto),
                        ),
                        Spacing.height(16),
                      ],
                    ),
                  )),
              Divider(height: 0, thickness: 1)
            ],
            Padding(
              padding: Spacing.all(16),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (slot?.algorithm != AlgorithmType.x25519) ...[
                    CustomizedButton.rounded(
                      onPressed: () {
                        Navigator.pop(Get.context!);
                        _showGenerateDialog(slotNumber, selfSigned: false);
                      },
                      elevation: 0,
                      padding: Spacing.xy(20, 16),
                      backgroundColor: contentTheme.primary,
                      child: CustomizedText.labelMedium('Generate CSR',
                          color: contentTheme.onSecondary),
                    ),
                    CustomizedButton.rounded(
                      onPressed: () {
                        Navigator.pop(Get.context!);
                        _showGenerateDialog(slotNumber, selfSigned: true);
                      },
                      elevation: 0,
                      padding: Spacing.xy(20, 16),
                      backgroundColor: contentTheme.primary,
                      child: CustomizedText.labelMedium('Self-sign',
                          color: contentTheme.onSecondary),
                    ),
                  ],
                  CustomizedButton.rounded(
                    onPressed: () {
                      Navigator.pop(Get.context!);
                      _showGenerateKeyDialog(slotNumber);
                    },
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium('Generate Key',
                        color: contentTheme.onPrimary),
                  ),
                  if (slot?.algorithm == AlgorithmType.x25519)
                    CustomizedButton.rounded(
                      onPressed: () {
                        Navigator.pop(Get.context!);
                        _showDeriveSecretDialog(slotNumber);
                      },
                      elevation: 0,
                      padding: Spacing.xy(20, 16),
                      backgroundColor: contentTheme.primary,
                      child: CustomizedText.labelMedium('Derive Secret',
                          color: contentTheme.onPrimary),
                    ),
                  CustomizedButton.rounded(
                    onPressed: () async {
                      // if (cachedManagementKey == null) {
                      //   if (!await _showVerifyManagementKeyDialog()) {
                      //     return;
                      //   }
                      // }
                      Navigator.pop(Get.context!);
                      _showImportDialog(slotNumber);
                    },
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium(S.of(context).pivImport,
                        color: contentTheme.onPrimary),
                  ),
                  if (slot != null) ...[
                    CustomizedButton.rounded(
                      onPressed: () {
                        Navigator.pop(Get.context!);
                        _showExportDialog(slot);
                      },
                      elevation: 0,
                      padding: Spacing.xy(20, 16),
                      backgroundColor: contentTheme.primary,
                      child: CustomizedText.labelMedium(S.of(context).pivExport,
                          color: contentTheme.onPrimary),
                    ),
                    CustomizedButton.rounded(
                      onPressed: () {
                        Navigator.pop(Get.context!);
                        _showDeleteDialog(slotNumber);
                      },
                      elevation: 0,
                      padding: Spacing.xy(20, 16),
                      backgroundColor: contentTheme.danger,
                      child: CustomizedText.labelMedium(S.of(context).pivDelete,
                          color: contentTheme.onDanger),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  void _showExportDialog(SlotInfo slot) {
    Get.dialog(Dialog(
        child: SizedBox(
            width: 300,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                      padding: Spacing.all(16),
                      child: CustomizedText.labelLarge(
                          S.of(context).pivExportCertificate)),
                  Divider(height: 0, thickness: 1),
                  Padding(
                      padding: Spacing.all(16),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomizedButton.rounded(
                              onPressed: () async {
                                // Export DER
                                await FileSaver.instance.saveFile(
                                    name: 'certificate.der',
                                    bytes: slot.certBytes! as Uint8List);
                                Get.back();
                              },
                              elevation: 0,
                              padding: Spacing.xy(20, 16),
                              backgroundColor: contentTheme.primary,
                              child: CustomizedText.labelMedium('DER',
                                  color: contentTheme.onPrimary),
                            ),
                            Spacing.width(12),
                            CustomizedButton.rounded(
                              onPressed: () async {
                                final encodedDer = StringUtils.chunk(
                                        base64.encode(slot.certBytes!), 64)
                                    .join("\n");
                                String pem =
                                    '${X509Utils.BEGIN_CERT}\n$encodedDer\n${X509Utils.END_CERT}';
                                await FileSaver.instance.saveFile(
                                    name: 'certificate.pem',
                                    bytes: utf8.encode(pem));
                                Get.back();
                              },
                              elevation: 0,
                              padding: Spacing.xy(20, 16),
                              backgroundColor: contentTheme.primary,
                              child: CustomizedText.labelMedium('PEM',
                                  color: contentTheme.onPrimary),
                            )
                          ]))
                ]))));
  }

  void _showImportDialog(String slotNumber) {
    Rx<int> step = 0.obs;
    Rx<bool> hasCert = false.obs;
    Rx<bool> hasKey = false.obs;
    Rx<bool> selected = false.obs;
    PinPolicy pinPolicy =
        slotNumber == '9C' ? PinPolicy.always : PinPolicy.once;
    TouchPolicy touchPolicy = TouchPolicy.never;
    ECPrivateKey? ecPrivateKey;
    RSAPrivateKey? rsaPrivateKey;
    Uint8List? edPrivateKey;
    X509CertData? cert;
    Uint8List? certBytes;

    void nextStep() async {
      if (step.value < 2) {
        setState(() => step.value++);
      } else {
        // We first import the private key
        if (ecPrivateKey != null) {
          bool importSuccess = await controller.importEccKey(
              slotNumber, ecPrivateKey!, pinPolicy, touchPolicy);
          if (!importSuccess) {
            Prompts.showPrompt('Import Key Failed', ContentThemeColor.danger);
            return;
          }
        } else if (rsaPrivateKey != null) {
          bool importSuccess = await controller.importRsaKey(
              slotNumber, rsaPrivateKey!, pinPolicy, touchPolicy);
          if (!importSuccess) {
            Prompts.showPrompt('Import Key Failed', ContentThemeColor.danger);
            return;
          }
        } else if (edPrivateKey != null) {
          bool importSuccess = await controller.importEd25519Key(
              slotNumber, edPrivateKey!, pinPolicy, touchPolicy);
          if (!importSuccess) {
            Prompts.showPrompt('Import Key Failed', ContentThemeColor.danger);
            return;
          }
        }

        // We then import the certificate
        if (cert != null) {
          bool importSuccess =
              await controller.importCert(slotNumber, certBytes!);
          if (!importSuccess) {
            Prompts.showPrompt('Import Cert Failed', ContentThemeColor.danger);
            return;
          }
        }

        Prompts.showPrompt('Import Succeeded', ContentThemeColor.success);
        Navigator.pop(Get.context!);
      }
    }

    void prevStep() {
      if (step.value == 0) {
        Get.back();
      } else if (step.value > 0) {
        setState(() => step.value--);
      }
    }

    void parsePem(Uint8List bytes) {
      final pem = utf8.decode(bytes);
      pem.split('-----BEGIN ').forEach((element) {
        if (element.isNotEmpty) {
          final item = '-----BEGIN $element';
          if (item.startsWith(CryptoUtils.BEGIN_EC_PRIVATE_KEY)) {
            // ECDSA
            ecPrivateKey = CryptoUtils.ecPrivateKeyFromPem(item);
            hasKey.value = true;
          } else if (item.startsWith(CryptoUtils.BEGIN_RSA_PRIVATE_KEY)) {
            // RSA
            rsaPrivateKey = CryptoUtils.rsaPrivateKeyFromPemPkcs1(item);
            hasKey.value = true;
          } else if (item.startsWith(CryptoUtils.BEGIN_PRIVATE_KEY)) {
            // Ed25519
            edPrivateKey = CryptoUtils.ed25519PrivateKeyFromPem(item);
            hasKey.value = true;
          } else if (item.startsWith(X509Utils.BEGIN_CERT)) {
            // Certificate
            cert = parseX509CertFromPem(pem: element);
            certBytes = cert!.bytes;
            hasCert.value = true;
          }
        }
      });
    }

    Get.dialog(Dialog(
      child: Obx(
        () => SizedBox(
          width: 400,
          child: Stepper(
            currentStep: step.value,
            onStepContinue: nextStep,
            onStepCancel: prevStep,
            controlsBuilder: (BuildContext context, ControlsDetails details) {
              return Row(
                children: <Widget>[
                  if (details.stepIndex > 0) ...{
                    CustomizedButton.rounded(
                      onPressed: details.onStepContinue,
                      elevation: 0,
                      backgroundColor: ContentThemeColor.primary.color,
                      child: CustomizedText.labelMedium(
                          step.value == 2 ? 'Import' : 'Next',
                          color: ContentThemeColor.primary.onColor),
                    ),
                    Spacing.width(12),
                  },
                  CustomizedButton.rounded(
                    onPressed: details.onStepCancel,
                    elevation: 0,
                    backgroundColor: ContentThemeColor.secondary.color,
                    child: CustomizedText.labelMedium(
                        step.value == 0 ? 'Cancel' : 'Back',
                        color: ContentThemeColor.secondary.onColor),
                  ),
                ],
              );
            },
            steps: [
              Step(
                title: Text('Select Your Certificate'),
                content: InkWell(
                  onTap: () async {
                    final result = await FilePicker.pickFiles();
                    final file = result?.files.firstOrNull;
                    if (file != null) {
                      selected.value = true;
                      parsePem(await file.xFile.readAsBytes());
                      if (hasKey.value && hasCert.value) {
                        nextStep();
                      }
                    }
                  },
                  child: CustomizedContainer.bordered(
                    child: Center(
                      heightFactor: 1.2,
                      child: Padding(
                        padding: Spacing.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.uploadCloud, size: 24),
                            CustomizedContainer(
                              width: 340,
                              alignment: Alignment.center,
                              paddingAll: 0,
                              child: CustomizedText.titleMedium(
                                "Click to select a certificate",
                                fontWeight: 600,
                                muted: true,
                                fontSize: 18,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (selected.value &&
                                !hasCert.value &&
                                !hasKey.value)
                              CustomizedContainer(
                                alignment: Alignment.center,
                                child: CustomizedText.titleMedium(
                                  "(Make sure the file contains a plaintext key and a certificate)",
                                  muted: true,
                                  fontWeight: 500,
                                  fontSize: 12,
                                  textAlign: TextAlign.center,
                                  color: contentTheme.danger,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Step(
                title: Text('PIN and Touch Policy'),
                content: Column(
                  children: [
                    DropdownButtonFormField(
                      initialValue: pinPolicy,
                      items: [PinPolicy.never, PinPolicy.once, PinPolicy.always]
                          .map((e) => DropdownMenuItem(
                              value: e, child: Text(e.toString())))
                          .toList(),
                      onChanged: (value) => setState(() => pinPolicy = value!),
                      decoration: InputDecoration(labelText: 'PIN Policy'),
                      dropdownColor: contentTheme.background,
                    ),
                    DropdownButtonFormField(
                      initialValue: touchPolicy,
                      items: [
                        TouchPolicy.never,
                        TouchPolicy.cached,
                        TouchPolicy.always
                      ]
                          .map((e) => DropdownMenuItem(
                              value: e, child: Text(e.toString())))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => touchPolicy = value!),
                      decoration: InputDecoration(labelText: 'Touch Policy'),
                      dropdownColor: contentTheme.background,
                    ),
                  ],
                ),
              ),
              Step(
                  title: Text('Review'),
                  content: Column(
                    children: [
                      if (cert != null)
                        CustomizedText.bodyMedium(
                            '${S.of(context).pivCertificate}: ${cert!.subject != "" ? cert!.subject : S.of(context).pivEmpty}'),
                      CustomizedText.bodyMedium('PIN Policy: $pinPolicy'),
                      CustomizedText.bodyMedium('Touch Policy: $touchPolicy'),
                    ],
                  )),
            ],
          ),
        ),
      ),
    ));
  }

  void _showGenerateDialog(String slotNumber, {required bool selfSigned}) {
    Rx<int> step = 0.obs;
    AlgorithmType algorithm = AlgorithmType.eccp256;
    PinPolicy pinPolicy =
        slotNumber == '9C' ? PinPolicy.always : PinPolicy.once;
    TouchPolicy touchPolicy = TouchPolicy.never;
    bool usePinOnly = controller.pinOnlyMode;
    FormValidator pinValidator = FormValidator();
    FormValidator subjectValidator = FormValidator();
    pinValidator.addField('pin',
        required: true,
        controller: TextEditingController(),
        validators: [LengthValidator(min: 6, max: 8)]);
    pinValidator.addField('managementKey',
        required: !usePinOnly,
        controller: TextEditingController(),
        validators: [
          LengthValidator(exact: 48, required: !usePinOnly),
          HexStringValidator(required: !usePinOnly)
        ]);
    subjectValidator.addField('cn',
        required: true, controller: TextEditingController());
    subjectValidator.addField('o', controller: TextEditingController());
    subjectValidator.addField('ou', controller: TextEditingController());
    subjectValidator.addField('c',
        controller: TextEditingController(),
        validators: [LengthValidator(exact: 2)]);
    subjectValidator.addField('sans', controller: TextEditingController());
    subjectValidator.addField('validityDays',
        required: true, controller: TextEditingController(text: '365'));

    Future<void> nextStep() async {
      if (step.value == 0) {
        if (!pinValidator.validateForm()) {
          return;
        }
        step.value++;
        return;
      }
      if (step.value == 1) {
        step.value++;
        return;
      }
      if (!subjectValidator.validateForm()) return;
      if (!_validateManagementKeyInput(
          pinValidator, 'managementKey', usePinOnly)) {
        return;
      }

      final subject = <String, String>{};
      void addSubject(String key, String field) {
        final value = subjectValidator.getController(field)!.text.trim();
        if (value.isNotEmpty) subject[key] = value;
      }

      addSubject('CN', 'cn');
      addSubject('O', 'o');
      addSubject('OU', 'ou');
      addSubject('C', 'c');
      final sans = subjectValidator
          .getController('sans')!
          .text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      Get.context!.loaderOverlay.show();
      try {
        if (selfSigned) {
          final validityDays = int.tryParse(subjectValidator
                  .getController('validityDays')!
                  .text
                  .trim()) ??
              365;
          final cert = await controller.generateSelfSignedCertificate(
              slotNumber,
              algorithm,
              pinPolicy,
              touchPolicy,
              pinValidator.getController('pin')!.text,
              pinValidator.getController('managementKey')!.text,
              subject,
              sans,
              validityDays,
              usePinOnly);
          if (cert == null) {
            Prompts.showPrompt(
                'Create Certificate Failed', ContentThemeColor.danger);
            return;
          }
          await controller.refreshData();
          Prompts.showPrompt('Certificate Created', ContentThemeColor.success);
          Navigator.pop(Get.context!);
          _showCertificateResultDialog(slotNumber, cert);
        } else {
          final csr = await controller.generateCsr(
              slotNumber,
              algorithm,
              pinPolicy,
              touchPolicy,
              pinValidator.getController('pin')!.text,
              pinValidator.getController('managementKey')!.text,
              subject,
              sans,
              usePinOnly);
          if (csr == null) {
            Prompts.showPrompt('Generate CSR Failed', ContentThemeColor.danger);
            return;
          }

          await controller.refreshData();
          Prompts.showPrompt('CSR Generated', ContentThemeColor.success);
          Navigator.pop(Get.context!);
          _showCsrResultDialog(slotNumber, csr);
        }
      } finally {
        Get.context!.loaderOverlay.hide();
      }
    }

    void prevStep() {
      if (step.value == 0) {
        Get.back();
      } else {
        step.value--;
      }
    }

    Get.dialog(Dialog(
      child: Obx(
        () => SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: Spacing.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CustomizedText.labelLarge(
                    selfSigned ? 'Self-sign Certificate' : 'Generate CSR',
                  ),
                ),
              ),
              Divider(height: 0, thickness: 1),
              Stepper(
                currentStep: step.value,
                onStepContinue: nextStep,
                onStepCancel: prevStep,
                stepIconBuilder: (stepIndex, stepState) {
                  final active = stepIndex == step.value;
                  return Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active
                          ? ContentThemeColor.primary.color
                          : AppTheme.theme.colorScheme.onSurface.withAlpha(96),
                      shape: BoxShape.circle,
                    ),
                    child: CustomizedText.labelMedium(
                      '${stepIndex + 1}',
                      color: active
                          ? ContentThemeColor.primary.onColor
                          : AppTheme.theme.colorScheme.surface,
                      fontWeight: 600,
                    ),
                  );
                },
                controlsBuilder:
                    (BuildContext context, ControlsDetails details) {
                  return Row(
                    children: [
                      CustomizedButton.rounded(
                        onPressed: details.onStepContinue,
                        elevation: 0,
                        backgroundColor: ContentThemeColor.primary.color,
                        child: CustomizedText.labelMedium(
                            step.value == 2
                                ? (selfSigned
                                    ? 'Create Certificate'
                                    : 'Generate CSR')
                                : 'Next',
                            color: ContentThemeColor.primary.onColor),
                      ),
                      Spacing.width(12),
                      CustomizedButton.rounded(
                        onPressed: details.onStepCancel,
                        elevation: 0,
                        backgroundColor: ContentThemeColor.secondary.color,
                        child: CustomizedText.labelMedium(
                            step.value == 0 ? 'Cancel' : 'Back',
                            color: ContentThemeColor.secondary.onColor),
                      ),
                    ],
                  );
                },
                steps: [
                  Step(
                    isActive: step.value == 0,
                    state:
                        step.value == 0 ? StepState.editing : StepState.indexed,
                    title: Text('Verify PIN and Management Key'),
                    content: Padding(
                      padding: Spacing.top(10),
                      child: Form(
                        key: pinValidator.formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              autofocus: true,
                              onTap: SmartCard.eject,
                              obscureText: true,
                              controller: pinValidator.getController('pin'),
                              validator: pinValidator.getValidator('pin'),
                              decoration: InputDecoration(
                                  labelText: 'PIN', border: outlineInputBorder),
                            ),
                            if (controller.pinOnlyMode) ...[
                              Spacing.height(12),
                              CheckboxListTile(
                                value: usePinOnly,
                                onChanged: (value) =>
                                    setState(() => usePinOnly = value ?? true),
                                contentPadding: EdgeInsets.zero,
                                title: Text('Use PIN-only management key'),
                              ),
                            ],
                            Spacing.height(18),
                            _buildManagementKeyField(
                              pinValidator,
                              'managementKey',
                              enabled: !usePinOnly,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Step(
                    isActive: step.value == 1,
                    state:
                        step.value == 1 ? StepState.editing : StepState.indexed,
                    title: Text('Key Options'),
                    content: Padding(
                      padding: Spacing.top(10),
                      child: Column(
                        children: [
                          DropdownButtonFormField(
                            initialValue: algorithm,
                            items: [
                              AlgorithmType.eccp256,
                              AlgorithmType.eccp384,
                              AlgorithmType.secp256k1,
                              AlgorithmType.sm2,
                              AlgorithmType.ed25519,
                              AlgorithmType.rsa2048,
                              AlgorithmType.rsa3072,
                              AlgorithmType.rsa4096,
                            ]
                                .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e.name.toUpperCase())))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => algorithm = value!),
                            decoration: InputDecoration(labelText: 'Algorithm'),
                            dropdownColor: contentTheme.background,
                          ),
                          Spacing.height(18),
                          DropdownButtonFormField(
                            initialValue: pinPolicy,
                            items: [
                              PinPolicy.never,
                              PinPolicy.once,
                              PinPolicy.always
                            ]
                                .map((e) => DropdownMenuItem(
                                    value: e, child: Text(e.toString())))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => pinPolicy = value!),
                            decoration:
                                InputDecoration(labelText: 'PIN Policy'),
                            dropdownColor: contentTheme.background,
                          ),
                          Spacing.height(18),
                          DropdownButtonFormField(
                            initialValue: touchPolicy,
                            items: [
                              TouchPolicy.never,
                              TouchPolicy.cached,
                              TouchPolicy.always
                            ]
                                .map((e) => DropdownMenuItem(
                                    value: e, child: Text(e.toString())))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => touchPolicy = value!),
                            decoration:
                                InputDecoration(labelText: 'Touch Policy'),
                            dropdownColor: contentTheme.background,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Step(
                    isActive: step.value == 2,
                    state:
                        step.value == 2 ? StepState.editing : StepState.indexed,
                    title: Text(
                        selfSigned ? 'Certificate Subject' : 'CSR Subject'),
                    content: Padding(
                      padding: Spacing.top(10),
                      child: Form(
                        key: subjectValidator.formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: subjectValidator.getController('cn'),
                              validator: subjectValidator.getValidator('cn'),
                              decoration: InputDecoration(
                                  labelText: 'Common Name',
                                  border: outlineInputBorder),
                            ),
                            Spacing.height(18),
                            TextFormField(
                              controller: subjectValidator.getController('o'),
                              validator: subjectValidator.getValidator('o'),
                              decoration: InputDecoration(
                                  labelText: 'Organization',
                                  border: outlineInputBorder),
                            ),
                            Spacing.height(18),
                            TextFormField(
                              controller: subjectValidator.getController('ou'),
                              validator: subjectValidator.getValidator('ou'),
                              decoration: InputDecoration(
                                  labelText: 'Organizational Unit',
                                  border: outlineInputBorder),
                            ),
                            Spacing.height(18),
                            TextFormField(
                              controller: subjectValidator.getController('c'),
                              validator: subjectValidator.getValidator('c'),
                              decoration: InputDecoration(
                                  labelText: 'Country Code',
                                  border: outlineInputBorder),
                            ),
                            Spacing.height(18),
                            TextFormField(
                              controller:
                                  subjectValidator.getController('sans'),
                              validator: subjectValidator.getValidator('sans'),
                              decoration: InputDecoration(
                                  labelText: 'DNS SANs, comma separated',
                                  border: outlineInputBorder),
                            ),
                            if (selfSigned) ...[
                              Spacing.height(18),
                              TextFormField(
                                controller: subjectValidator
                                    .getController('validityDays'),
                                validator: subjectValidator
                                    .getValidator('validityDays'),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                    labelText: 'Validity Days',
                                    border: outlineInputBorder),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }

  void _showGenerateKeyDialog(String slotNumber) {
    AlgorithmType algorithm = AlgorithmType.eccp256;
    PinPolicy pinPolicy =
        slotNumber == '9C' ? PinPolicy.always : PinPolicy.once;
    TouchPolicy touchPolicy = TouchPolicy.never;
    bool usePinOnly = controller.pinOnlyMode;
    FormValidator validator = FormValidator();
    validator.addField('pin',
        required: true,
        controller: TextEditingController(),
        validators: [LengthValidator(min: 6, max: 8)]);
    validator.addField('managementKey',
        required: !usePinOnly,
        controller: TextEditingController(),
        validators: [
          LengthValidator(exact: 48, required: !usePinOnly),
          HexStringValidator(required: !usePinOnly)
        ]);

    Get.dialog(Dialog(
      child: StatefulBuilder(
        builder: (context, setDialogState) => SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.all(16),
                child: CustomizedText.labelLarge('Generate Key'),
              ),
              Divider(height: 0, thickness: 1),
              Padding(
                padding: Spacing.all(16),
                child: Form(
                  key: validator.formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        autofocus: true,
                        onTap: SmartCard.eject,
                        obscureText: true,
                        controller: validator.getController('pin'),
                        validator: validator.getValidator('pin'),
                        decoration: InputDecoration(
                            labelText: 'PIN', border: outlineInputBorder),
                      ),
                      if (controller.pinOnlyMode) ...[
                        Spacing.height(12),
                        CheckboxListTile(
                          value: usePinOnly,
                          onChanged: (value) =>
                              setDialogState(() => usePinOnly = value ?? true),
                          contentPadding: EdgeInsets.zero,
                          title: Text('Use PIN-only management key'),
                        ),
                      ],
                      Spacing.height(18),
                      _buildManagementKeyField(
                        validator,
                        'managementKey',
                        enabled: !usePinOnly,
                      ),
                      Spacing.height(18),
                      DropdownButtonFormField(
                        initialValue: algorithm,
                        items: [
                          AlgorithmType.eccp256,
                          AlgorithmType.eccp384,
                          AlgorithmType.secp256k1,
                          AlgorithmType.sm2,
                          AlgorithmType.ed25519,
                          AlgorithmType.x25519,
                          AlgorithmType.rsa2048,
                          AlgorithmType.rsa3072,
                          AlgorithmType.rsa4096,
                        ]
                            .map((e) => DropdownMenuItem(
                                value: e, child: Text(e.name.toUpperCase())))
                            .toList(),
                        onChanged: (value) =>
                            setDialogState(() => algorithm = value!),
                        decoration: InputDecoration(labelText: 'Algorithm'),
                        dropdownColor: contentTheme.background,
                      ),
                      Spacing.height(18),
                      DropdownButtonFormField(
                        initialValue: pinPolicy,
                        items: [
                          PinPolicy.never,
                          PinPolicy.once,
                          PinPolicy.always
                        ]
                            .map((e) => DropdownMenuItem(
                                value: e, child: Text(e.toString())))
                            .toList(),
                        onChanged: (value) =>
                            setDialogState(() => pinPolicy = value!),
                        decoration: InputDecoration(labelText: 'PIN Policy'),
                        dropdownColor: contentTheme.background,
                      ),
                      Spacing.height(18),
                      DropdownButtonFormField(
                        initialValue: touchPolicy,
                        items: [
                          TouchPolicy.never,
                          TouchPolicy.cached,
                          TouchPolicy.always
                        ]
                            .map((e) => DropdownMenuItem(
                                value: e, child: Text(e.toString())))
                            .toList(),
                        onChanged: (value) =>
                            setDialogState(() => touchPolicy = value!),
                        decoration: InputDecoration(labelText: 'Touch Policy'),
                        dropdownColor: contentTheme.background,
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
                      onPressed: () => Get.back(),
                      elevation: 0,
                      backgroundColor: contentTheme.secondary,
                      child: CustomizedText.labelMedium(S.of(context).cancel,
                          color: contentTheme.onSecondary),
                    ),
                    Spacing.width(12),
                    CustomizedButton.rounded(
                      onPressed: () async {
                        if (!validator.validateForm()) return;
                        if (!_validateManagementKeyInput(
                            validator, 'managementKey', usePinOnly)) {
                          return;
                        }
                        Get.context!.loaderOverlay.show();
                        try {
                          final ok = await controller.generateKey(
                              slotNumber,
                              algorithm,
                              pinPolicy,
                              touchPolicy,
                              validator.getController('pin')!.text,
                              validator.getController('managementKey')!.text,
                              usePinOnly);
                          if (!ok) {
                            Prompts.showPrompt('Generate Key Failed',
                                ContentThemeColor.danger);
                            return;
                          }
                          await controller.refreshData();
                          Prompts.showPrompt(
                              'Key Generated', ContentThemeColor.success);
                          Navigator.pop(Get.context!);
                        } finally {
                          Get.context!.loaderOverlay.hide();
                        }
                      },
                      elevation: 0,
                      backgroundColor: contentTheme.primary,
                      child: CustomizedText.labelMedium('Generate',
                          color: contentTheme.onPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  void _showDeriveSecretDialog(String slotNumber) {
    FormValidator validator = FormValidator();
    validator.addField('pin',
        required: true,
        controller: TextEditingController(),
        validators: [LengthValidator(min: 6, max: 8)]);
    validator.addField('peerPublicKey',
        required: true,
        controller: TextEditingController(),
        validators: [LengthValidator(exact: 64), HexStringValidator()]);

    Get.dialog(Dialog(
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge('Derive Secret'),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Form(
                key: validator.formKey,
                child: Column(
                  children: [
                    TextFormField(
                      autofocus: true,
                      onTap: SmartCard.eject,
                      obscureText: true,
                      controller: validator.getController('pin'),
                      validator: validator.getValidator('pin'),
                      decoration: InputDecoration(
                          labelText: 'PIN', border: outlineInputBorder),
                    ),
                    Spacing.height(18),
                    TextFormField(
                      onTap: SmartCard.eject,
                      controller: validator.getController('peerPublicKey'),
                      validator: validator.getValidator('peerPublicKey'),
                      decoration: InputDecoration(
                          labelText: 'Peer Public Key (32-byte hex)',
                          border: outlineInputBorder),
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
                    onPressed: () => Get.back(),
                    elevation: 0,
                    backgroundColor: contentTheme.secondary,
                    child: CustomizedText.labelMedium(S.of(context).cancel,
                        color: contentTheme.onSecondary),
                  ),
                  Spacing.width(12),
                  CustomizedButton.rounded(
                    onPressed: () async {
                      if (!validator.validateForm()) return;
                      Get.context!.loaderOverlay.show();
                      try {
                        final secret = await controller.deriveX25519Secret(
                            slotNumber,
                            validator.getController('pin')!.text,
                            Uint8List.fromList(hex.decode(validator
                                .getController('peerPublicKey')!
                                .text)));
                        if (secret == null) {
                          Prompts.showPrompt(
                              'Derive Secret Failed', ContentThemeColor.danger);
                          return;
                        }
                        Navigator.pop(Get.context!);
                        _showSecretResultDialog(secret);
                      } finally {
                        Get.context!.loaderOverlay.hide();
                      }
                    },
                    elevation: 0,
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium('Derive',
                        color: contentTheme.onPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  void _showSecretResultDialog(Uint8List secret) {
    final text = hex.encode(secret);
    Get.dialog(Dialog(
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge('Shared Secret'),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: TextFormField(
                initialValue: text,
                readOnly: true,
                minLines: 2,
                maxLines: 4,
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(border: outlineInputBorder),
              ),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomizedButton.rounded(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: text));
                      Prompts.showPrompt(
                          'Secret Copied', ContentThemeColor.success);
                    },
                    elevation: 0,
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium('Copy',
                        color: contentTheme.onPrimary),
                  ),
                  Spacing.width(12),
                  CustomizedButton.rounded(
                    onPressed: () => Get.back(),
                    elevation: 0,
                    backgroundColor: contentTheme.secondary,
                    child: CustomizedText.labelMedium(S.of(context).close,
                        color: contentTheme.onSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  void _showCsrResultDialog(String slotNumber, String csr) {
    Get.dialog(Dialog(
      child: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge('CSR Generated'),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: SizedBox(
                height: 260,
                child: TextFormField(
                  initialValue: csr,
                  readOnly: true,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: InputDecoration(border: outlineInputBorder),
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
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: csr));
                      Prompts.showPrompt(
                          'CSR Copied', ContentThemeColor.success);
                    },
                    elevation: 0,
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium('Copy',
                        color: contentTheme.onPrimary),
                  ),
                  Spacing.width(12),
                  CustomizedButton.rounded(
                    onPressed: () async {
                      await FileSaver.instance.saveFile(
                          name: 'piv-$slotNumber.csr', bytes: utf8.encode(csr));
                    },
                    elevation: 0,
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium('Save',
                        color: contentTheme.onPrimary),
                  ),
                  Spacing.width(12),
                  CustomizedButton.rounded(
                    onPressed: () => Get.back(),
                    elevation: 0,
                    backgroundColor: contentTheme.secondary,
                    child: CustomizedText.labelMedium(S.of(context).close,
                        color: contentTheme.onSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  void _showCertificateResultDialog(String slotNumber, Uint8List cert) {
    final encodedDer = StringUtils.chunk(base64.encode(cert), 64).join("\n");
    final pem = '${X509Utils.BEGIN_CERT}\n$encodedDer\n${X509Utils.END_CERT}';
    Get.dialog(Dialog(
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge('Certificate Created'),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.bodyMedium(
                  'A self-signed certificate was written to slot $slotNumber.'),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomizedButton.rounded(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: pem));
                      Prompts.showPrompt(
                          'Certificate Copied', ContentThemeColor.success);
                    },
                    elevation: 0,
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium('Copy PEM',
                        color: contentTheme.onPrimary),
                  ),
                  Spacing.width(12),
                  CustomizedButton.rounded(
                    onPressed: () async {
                      await FileSaver.instance.saveFile(
                          name: 'piv-$slotNumber.pem', bytes: utf8.encode(pem));
                    },
                    elevation: 0,
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium('Save PEM',
                        color: contentTheme.onPrimary),
                  ),
                  Spacing.width(12),
                  CustomizedButton.rounded(
                    onPressed: () => Get.back(),
                    elevation: 0,
                    backgroundColor: contentTheme.secondary,
                    child: CustomizedText.labelMedium(S.of(context).close,
                        color: contentTheme.onSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  void _showDeleteDialog(String slotNumber) {
    Get.dialog(Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.of(context).delete),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(
                  S.of(context).pivDeleteSlot(slotNumber)),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Row(
                children: [
                  CustomizedButton.rounded(
                    onPressed: () => Get.back(),
                    elevation: 0,
                    backgroundColor: contentTheme.secondary,
                    child: CustomizedText.labelMedium(S.of(context).cancel,
                        color: contentTheme.onSecondary),
                  ),
                  Spacing.width(12),
                  CustomizedButton.rounded(
                    onPressed: () async {
                      await controller.delete(slotNumber);
                      Get.back();
                    },
                    elevation: 0,
                    backgroundColor: contentTheme.danger,
                    child: CustomizedText.labelMedium(S.of(context).delete,
                        color: contentTheme.onDanger),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  // String _origin(Origin origin) {
  //   if (origin == Origin.generated) {
  //     return S.of(context).pivOriginGenerated;
  //   }
  //   return S.of(context).pivOriginImported;
  // }

  // String? _displayDN(Map<String, String?>? data) {
  //   if (data == null) {
  //     return null;
  //   }
  //   final dnMap = Map.fromEntries(X509Utils.DN.entries.map((e) => MapEntry(e.value, e.key)));
  //   return data.keys.map((e) => '${dnMap[e]}=${data[e]}').join(', ');
  // }
}
