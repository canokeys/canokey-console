import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:canokey_console/src/rust/api/crypto.dart';

import 'package:basic_utils/basic_utils.dart';
import 'package:canokey_console/controller/applets/piv/piv_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/utils/app_loader_overlay.dart';
import 'package:canokey_console/helper/utils/piv_signature.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/shadow.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/utils/x509_algorithm_names.dart';
import 'package:canokey_console/helper/widgets/applet_disabled_screen.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_card.dart';
import 'package:canokey_console/helper/widgets/customized_container.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/field_validator.dart';
import 'package:canokey_console/helper/widgets/form_validator.dart';
import 'package:canokey_console/helper/widgets/keyboard_safe_dialog.dart';
import 'package:canokey_console/helper/widgets/poll_canokey_screen.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:canokey_console/views/applets/piv/widgets/piv_pin_management_card.dart';
import 'package:canokey_console/views/applets/piv/widgets/piv_slot_list_item.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:convert/convert.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:platform_detector/platform_detector.dart';
import 'package:pointycastle/asn1/primitives/asn1_bit_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_integer.dart';
import 'package:pointycastle/asn1/primitives/asn1_null.dart';
import 'package:pointycastle/asn1/primitives/asn1_object_identifier.dart';
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';
import 'package:share_plus/share_plus.dart';

class PivPage extends StatefulWidget {
  const PivPage({super.key});

  @override
  State<PivPage> createState() => _PivPageState();
}

class _PivPageState extends State<PivPage>
    with SingleTickerProviderStateMixin, UIMixin {
  final PivController controller = Get.put(PivController());

  Future<bool> _savePivFile({
    required String name,
    required String extension,
    required List<int> bytes,
    MimeType mimeType = MimeType.other,
  }) async {
    final l10n = S.of(context);
    try {
      final fileBytes = Uint8List.fromList(bytes);
      if (isMobile()) {
        final box = context.findRenderObject() as RenderBox?;
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [XFile.fromData(fileBytes, mimeType: mimeType.type)],
            fileNameOverrides: ['$name.$extension'],
            sharePositionOrigin:
                box == null ? null : box.localToGlobal(Offset.zero) & box.size,
          ),
        );
        return result.status == ShareResultStatus.success;
      }
      final path = await FileSaver.instance.saveAs(
        name: name,
        bytes: fileBytes,
        fileExtension: extension,
        mimeType: mimeType,
      );
      if (path == null || path.isEmpty) {
        return false;
      }
      if (path == 'Failed to save file') {
        Prompts.showPrompt(l10n.fileSaveFailed, ContentThemeColor.danger);
        return false;
      }
      Prompts.showPrompt(l10n.fileSaved, ContentThemeColor.success);
      return true;
    } catch (e) {
      Prompts.showPrompt(
          l10n.fileSaveFailedWithError(e), ContentThemeColor.danger);
      return false;
    }
  }

  String _sha256Fingerprint(List<int> bytes) {
    final digest = sha256Digest(data: bytes);
    return digest
        .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KiB';
    }
    return '$bytes B';
  }

  String _algorithmLabel(AlgorithmType algorithm) {
    return algorithm.label;
  }

  String _slotUsageHint(String slotNumber, AlgorithmType algorithm) {
    final base = switch (slotNumber) {
      '9A' => S.of(context).pivSlotAuthenticationHint,
      '9C' => S.of(context).pivSlotSignatureHint,
      '9D' => S.of(context).pivSlotKeyManagementHint,
      '9E' => S.of(context).pivSlotCardAuthenticationHint,
      _ => S.of(context).pivSlotRetiredHint,
    };
    if (algorithm == AlgorithmType.x25519) {
      return '$base ${S.of(context).pivX25519CertificateDisabled}';
    }
    if (algorithm == AlgorithmType.mlkem768) {
      return '$base ${S.of(context).pivPostQuantumCertificateGenerationDisabled}';
    }
    if (algorithm == AlgorithmType.ed25519 || algorithm == AlgorithmType.sm2) {
      return '$base ${S.of(context).pivExtendedAlgorithmCompatibilityWarning}';
    }
    return base;
  }

  AlgorithmType? _algorithmFromEcDomain(String? domainName) {
    return switch (domainName) {
      'prime256v1' => AlgorithmType.eccp256,
      'secp384r1' => AlgorithmType.eccp384,
      'secp521r1' => AlgorithmType.eccp521,
      'secp256k1' => AlgorithmType.secp256k1,
      _ => null,
    };
  }

  AlgorithmType? _algorithmFromRsaKey(RSAPrivateKey key) {
    return switch (key.modulus!.bitLength) {
      <= 1024 => AlgorithmType.rsa1024,
      <= 2048 => AlgorithmType.rsa2048,
      <= 3072 => AlgorithmType.rsa3072,
      _ => AlgorithmType.rsa4096,
    };
  }

  AlgorithmType? _selectedImportAlgorithm({
    ECPrivateKey? ecPrivateKey,
    RSAPrivateKey? rsaPrivateKey,
    Uint8List? edPrivateKey,
  }) {
    if (ecPrivateKey != null) {
      return _algorithmFromEcDomain(ecPrivateKey.parameters?.domainName);
    }
    if (rsaPrivateKey != null) {
      return _algorithmFromRsaKey(rsaPrivateKey);
    }
    if (edPrivateKey != null) {
      return AlgorithmType.ed25519;
    }
    return null;
  }

  Uint8List _subjectPublicKeyInfoFromCertificate(List<int> certBytes) {
    return PivSignatureTest.subjectPublicKeyInfoFromCertificate(certBytes);
  }

  Uint8List _rsaSubjectPublicKeyInfoFromPrivate(RSAPrivateKey key) {
    final exponent = key.publicExponent ?? BigInt.from(65537);
    final publicKey = ASN1Sequence()
      ..add(ASN1Integer(key.modulus!))
      ..add(ASN1Integer(exponent));
    final algorithm = ASN1Sequence()
      ..add(ASN1ObjectIdentifier.fromName('rsaEncryption'))
      ..add(ASN1Null());
    return (ASN1Sequence()
          ..add(algorithm)
          ..add(ASN1BitString(stringValues: publicKey.encode())))
        .encode();
  }

  Uint8List? _ecSubjectPublicKeyInfoFromPrivate(ECPrivateKey key) {
    final params = key.parameters;
    final d = key.d;
    if (params == null || d == null) {
      return null;
    }
    final point = params.G * d;
    if (point == null) {
      return null;
    }
    final publicKey = ECPublicKey(point, params);
    return Uint8List.fromList(CryptoUtils.getBytesFromPEMString(
        CryptoUtils.encodeEcPublicKeyToPem(publicKey)));
  }

  Uint8List? _privateKeySubjectPublicKeyInfo({
    ECPrivateKey? ecPrivateKey,
    RSAPrivateKey? rsaPrivateKey,
    Uint8List? edPrivateKey,
  }) {
    if (rsaPrivateKey != null) {
      return _rsaSubjectPublicKeyInfoFromPrivate(rsaPrivateKey);
    }
    if (ecPrivateKey != null) {
      return _ecSubjectPublicKeyInfoFromPrivate(ecPrivateKey);
    }
    return null;
  }

  bool _certificateMatchesPrivateKey({
    required Uint8List certBytes,
    ECPrivateKey? ecPrivateKey,
    RSAPrivateKey? rsaPrivateKey,
    Uint8List? edPrivateKey,
  }) {
    final privateSpki = _privateKeySubjectPublicKeyInfo(
      ecPrivateKey: ecPrivateKey,
      rsaPrivateKey: rsaPrivateKey,
      edPrivateKey: edPrivateKey,
    );
    if (privateSpki == null) {
      return true;
    }
    return hex.encode(privateSpki) ==
        hex.encode(_subjectPublicKeyInfoFromCertificate(certBytes));
  }

  String _certificateKeySummary(X509CertData cert) {
    final algorithm = x509PublicKeyAlgorithmName(cert.publicKeyAlgorithm);
    final size = switch (cert.publicKeyAlgorithm) {
      '1.3.101.112' || '1.3.101.110' => BigInt.from(256),
      _ => cert.publicKeySize,
    };
    if (size == BigInt.zero) {
      return algorithm;
    }
    return '$algorithm, $size bits';
  }

  bool _slotHasKey(String slotNumber) {
    return controller.slots[int.parse(slotNumber, radix: 16)] != null;
  }

  bool _slotHasCertificate(String slotNumber) {
    return controller.certificateBytes
        .containsKey(int.parse(slotNumber, radix: 16));
  }

  Future<bool> _confirmOverwriteKey({
    required String slotNumber,
    required String action,
  }) async {
    final slot = controller.slots[int.parse(slotNumber, radix: 16)];
    if (slot == null && controller.supportsMetadata) {
      return true;
    }

    final c = Completer<bool>();
    AppDialog.show(AppDialogSurface(
      child: SizedBox(
        width: AppDialogWidth.compact,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.of(context).pivOverwriteKey),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.bodyMedium(
                S.of(context).pivOverwriteKeyPrompt(action, slotNumber),
                color: contentTheme.danger,
              ),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomizedButton.rounded(
                    onPressed: () {
                      if (!c.isCompleted) c.complete(false);
                      Get.back();
                    },
                    elevation: 0,
                    backgroundColor: contentTheme.secondary,
                    child: CustomizedText.labelMedium(S.of(context).cancel,
                        color: contentTheme.onSecondary),
                  ),
                  Spacing.width(12),
                  CustomizedButton.rounded(
                    onPressed: () {
                      if (!c.isCompleted) c.complete(true);
                      Get.back();
                    },
                    elevation: 0,
                    backgroundColor: contentTheme.danger,
                    child: CustomizedText.labelMedium(
                        S.of(context).pivOverwrite,
                        color: contentTheme.onDanger),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )).whenComplete(() {
      if (!c.isCompleted) c.complete(false);
    });
    return c.future;
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      title: 'PIV',
      onRefresh: controller.refreshData,
      topActions: GetBuilder<PivController>(
        builder: (_) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.polled && controller.extendedRetiredSlots)
              IconButton(
                tooltip: S.of(context).pivAlgorithmIds,
                onPressed: _showAlgorithmExtensionConfigDialog,
                color: topBarTheme.onBackground,
                icon: Icon(LucideIcons.settings),
              ),
            if (isWeb() || isIOSApp())
              IconButton(
                tooltip: S.of(context).refresh,
                onPressed: controller.refreshData,
                color: topBarTheme.onBackground,
                icon: Icon(LucideIcons.refreshCw),
              ),
          ],
        ),
      ),
      child: GetBuilder(
        init: controller,
        builder: (_) {
          if (controller.disabledMessage != null) {
            return AppletDisabledScreen(message: controller.disabledMessage!);
          }
          if (!controller.polled) {
            return const PollCanoKeyScreen();
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
                    PivPinManagementCard(
                      pinInfo: controller.pinInfo,
                      pukInfo: controller.pukInfo,
                      managementKeyAlgorithm: controller.managementKeyAlgorithm,
                      managementKeyTouchPolicy:
                          controller.managementKeyTouchPolicy,
                      pinOnlyMode: controller.pinOnlyMode,
                      supportsPinOnlyMode: controller.supportsPinOnlyMode,
                      supportsPinRetryConfig: controller.supportsPinRetryConfig,
                      canUnblockPin: controller.pinInfo?.remainingCount == 0,
                      flexSpacing: flexSpacing,
                      contentTheme: contentTheme,
                      credentialRetryValue: _credentialRetryValue,
                      onChangePin: () => _showChangePinDialog(
                        title: S.of(context).changePin,
                        oldValueLabel: S.of(context).oldPin,
                        newValueLabel: S.of(context).newPin,
                        prompt: S.of(context).changePinPrompt(6, 8),
                        validators: [LengthValidator(min: 6, max: 8)],
                        handler: controller.changePin,
                      ),
                      onChangePuk: () => _showChangePinDialog(
                        title: S.of(context).pivChangePUK,
                        oldValueLabel: S.of(context).pivOldPUK,
                        newValueLabel: S.of(context).pivNewPUK,
                        prompt: S.of(context).pivChangePUKPrompt(6, 8),
                        validators: [LengthValidator(min: 6, max: 8)],
                        handler: controller.changePUK,
                      ),
                      onUnblockPin: () => _showChangePinDialog(
                        title: S.of(context).pivUnblockPin,
                        oldValueLabel: S.of(context).pivOldPUK,
                        newValueLabel: S.of(context).newPin,
                        prompt: S.of(context).pivUnblockPinPrompt,
                        validators: [LengthValidator(min: 6, max: 8)],
                        handler: controller.unblockPin,
                      ),
                      onChangeManagementKey: _showChangeManagementKeyDialog,
                      onSetPinRetries: _showSetPinRetriesDialog,
                      onTogglePinOnlyMode: controller.pinOnlyMode
                          ? _showDisablePinOnlyDialog
                          : _showEnablePinOnlyDialog,
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

    AppDialog.show(KeyboardSafeDialog(
      child: SizedBox(
        width: AppDialogWidth.compact,
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
      return S.of(context).pivRetriesUnknown;
    }
    return S.of(context).pivRetries(info.remainingCount, info.retriesCount);
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

  String _managementKeyAuthModeTitle(bool usePinOnly) {
    return usePinOnly
        ? S.of(context).pivPinProtectedKeyOnCard
        : S.of(context).pivManualManagementKey;
  }

  String _managementKeyAuthModeDescription(bool usePinOnly) {
    return usePinOnly
        ? S.of(context).pivPinProtectedManagementKeyDescription
        : S.of(context).pivManualManagementKeyDescription;
  }

  Widget _buildManagementKeyAuthModeControl({
    required bool usePinOnly,
    required ValueChanged<bool> onChanged,
  }) {
    if (!controller.pinOnlyMode) {
      return SizedBox.shrink();
    }

    Widget option(bool value) => RadioListTile<bool>(
          value: value,
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(_managementKeyAuthModeTitle(value)),
          subtitle: Text(_managementKeyAuthModeDescription(value)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomizedText.bodySmall(
          S.of(context).pivManagementKeyAuthentication,
          fontWeight: 600,
        ),
        RadioGroup<bool>(
          groupValue: usePinOnly,
          onChanged: (value) => onChanged(value ?? usePinOnly),
          child: Column(
            children: [
              option(true),
              option(false),
            ],
          ),
        ),
      ],
    );
  }

  void _showAlgorithmExtensionConfigDialog() {
    final config = controller.algorithmExtensionConfig;
    bool enabled = config.enabled;
    bool usePinOnly = controller.pinOnlyMode;
    final validator = FormValidator();
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

    void addIdField(String name, int value) {
      validator.addField(name,
          required: true,
          controller: TextEditingController(text: value.toString()),
          validators: [IntValidator(min: 0, max: 255)]);
    }

    addIdField('ed25519', config.ed25519);
    addIdField('rsa3072', config.rsa3072);
    addIdField('rsa4096', config.rsa4096);
    addIdField('x25519', config.x25519);
    addIdField('secp256k1', config.secp256k1);
    addIdField('secp521r1', config.secp521r1);
    addIdField('sm2', config.sm2);
    addIdField('mldsa65', config.mldsa65);
    addIdField('mlkem768', config.mlkem768);

    int idValue(String name) =>
        int.parse(validator.getController(name)!.text.trim());

    AppDialog.show(AppDialogSurface(
      child: StatefulBuilder(
        builder: (context, setDialogState) => SizedBox(
          width: AppDialogWidth.medium,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.all(16),
                child: CustomizedText.labelLarge(
                    S.of(context).pivAlgorithmIdsTitle),
              ),
              Divider(height: 0, thickness: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: Spacing.all(16),
                  child: Form(
                    key: validator.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAlgorithmIdWarning(),
                        Spacing.height(16),
                        CheckboxListTile(
                          value: enabled,
                          onChanged: (value) =>
                              setDialogState(() => enabled = value ?? enabled),
                          contentPadding: EdgeInsets.zero,
                          title: Text(S.of(context).enabled),
                          subtitle: Text(S.of(context).pivAlgorithmIdsPrompt),
                        ),
                        Spacing.height(12),
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
                          _buildManagementKeyAuthModeControl(
                            usePinOnly: usePinOnly,
                            onChanged: (value) =>
                                setDialogState(() => usePinOnly = value),
                          ),
                        ],
                        if (!usePinOnly) ...[
                          Spacing.height(18),
                          _buildManagementKeyField(validator, 'managementKey'),
                        ],
                        Spacing.height(18),
                        Wrap(
                          runSpacing: 12,
                          spacing: 12,
                          children: [
                            _buildAlgorithmIdField(
                                validator, 'ed25519', 'ED25519'),
                            _buildAlgorithmIdField(
                                validator, 'rsa3072', 'RSA3072'),
                            _buildAlgorithmIdField(
                                validator, 'rsa4096', 'RSA4096'),
                            _buildAlgorithmIdField(
                                validator, 'x25519', 'X25519'),
                            _buildAlgorithmIdField(
                                validator, 'secp256k1', 'SECP256K1'),
                            _buildAlgorithmIdField(
                                validator, 'secp521r1', 'SECP521R1'),
                            _buildAlgorithmIdField(validator, 'sm2', 'SM2'),
                            _buildAlgorithmIdField(
                                validator, 'mldsa65', 'ML-DSA-65'),
                            _buildAlgorithmIdField(
                                validator, 'mlkem768', 'ML-KEM-768'),
                          ],
                        ),
                      ],
                    ),
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
                        final successMessage =
                            S.of(context).successfullyChanged;
                        final newConfig = PivAlgorithmExtensionConfig(
                          enabled: enabled,
                          ed25519: idValue('ed25519'),
                          rsa3072: idValue('rsa3072'),
                          rsa4096: idValue('rsa4096'),
                          x25519: idValue('x25519'),
                          secp256k1: idValue('secp256k1'),
                          secp521r1: idValue('secp521r1'),
                          sm2: idValue('sm2'),
                          mldsa65: idValue('mldsa65'),
                          mlkem768: idValue('mlkem768'),
                        );
                        AppLoaderOverlay.show();
                        try {
                          final ok = await controller
                              .changeAlgorithmExtensionConfigAuthenticated(
                            config: newConfig,
                            pin: validator.getController('pin')!.text,
                            managementKey:
                                validator.getController('managementKey')!.text,
                            usePinOnly: usePinOnly,
                          );
                          if (!ok) {
                            Prompts.showPrompt(
                                S.current.pivAlgorithmIdsUpdateFailed,
                                ContentThemeColor.danger);
                            return;
                          }
                          await controller.refreshData();
                          Prompts.showPrompt(
                              successMessage, ContentThemeColor.success);
                          Get.back();
                        } finally {
                          AppLoaderOverlay.hide();
                        }
                      },
                      elevation: 0,
                      backgroundColor: contentTheme.primary,
                      child: CustomizedText.labelMedium(S.of(context).save,
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

  Widget _buildAlgorithmIdField(
      FormValidator validator, String field, String label) {
    return SizedBox(
      width: 150,
      child: TextFormField(
        onTap: SmartCard.eject,
        controller: validator.getController(field),
        validator: validator.getValidator(field),
        decoration:
            InputDecoration(labelText: label, border: outlineInputBorder),
      ),
    );
  }

  Widget _buildAlgorithmIdWarning() {
    final warningColor = contentTheme.warning;
    return Container(
      width: double.infinity,
      padding: Spacing.all(12),
      decoration: BoxDecoration(
        color: warningColor.withValues(alpha: 0.14),
        border: Border.all(color: warningColor.withValues(alpha: 0.75)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.shieldAlert, color: warningColor, size: 22),
          Spacing.width(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomizedText.bodyMedium(
                  S.of(context).pivModifyWithCaution,
                  fontWeight: 700,
                  color: warningColor,
                ),
                Spacing.height(4),
                CustomizedText.bodySmall(
                  S.of(context).pivAlgorithmIdsWarning,
                  color: contentTheme.onBackground,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

    AppDialog.show(KeyboardSafeDialog(
      child: StatefulBuilder(
        builder: (context, setDialogState) => SizedBox(
          width: AppDialogWidth.medium,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.all(16),
                child: CustomizedText.labelLarge(
                    S.of(context).pivSetPinPukRetries),
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
                        S.of(context).pivSetPinPukRetriesPrompt,
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
                            labelText: S.of(context).oldPin,
                            border: outlineInputBorder),
                      ),
                      if (controller.pinOnlyMode) ...[
                        Spacing.height(12),
                        _buildManagementKeyAuthModeControl(
                          usePinOnly: usePinOnly,
                          onChanged: (value) =>
                              setDialogState(() => usePinOnly = value),
                        ),
                      ],
                      if (!usePinOnly) ...[
                        Spacing.height(16),
                        _buildManagementKeyField(
                          validator,
                          'managementKey',
                        ),
                      ],
                      Spacing.height(16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: validator.getController('pinRetries'),
                              validator: validator.getValidator('pinRetries'),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: S.of(context).pivPinRetries,
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
                                  labelText: S.of(context).pivPukRetries,
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
                        AppLoaderOverlay.show();
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
                            Prompts.showPrompt(S.current.pivSetRetriesFailed,
                                ContentThemeColor.danger);
                            return;
                          }
                          await controller.refreshData();
                          Prompts.showPrompt(S.current.pivSetRetriesSuccess,
                              ContentThemeColor.success);
                          Get.back();
                        } finally {
                          AppLoaderOverlay.hide();
                        }
                      },
                      elevation: 0,
                      backgroundColor: contentTheme.primary,
                      child: CustomizedText.labelMedium(S.of(context).confirm,
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

    AppDialog.show(KeyboardSafeDialog(
      child: SizedBox(
        width: AppDialogWidth.medium,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(
                  S.of(context).pivEnablePinProtectedManagementKey),
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
                      S.of(context).pivEnablePinProtectedManagementKeyPrompt,
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
                      label: S.of(context).pivOldManagementKey,
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
                      AppLoaderOverlay.show();
                      try {
                        final ok = await controller.enablePinOnlyMode(
                          validator.getController('pin')!.text,
                          validator.getController('managementKey')!.text,
                        );
                        if (!ok) {
                          Prompts.showPrompt(
                              S.current
                                  .pivEnablePinProtectedManagementKeyFailed,
                              ContentThemeColor.danger);
                          return;
                        }
                        await controller.refreshData();
                        Prompts.showPrompt(
                            S.current.pivEnablePinProtectedManagementKeySuccess,
                            ContentThemeColor.success);
                        Get.back();
                      } finally {
                        AppLoaderOverlay.hide();
                      }
                    },
                    elevation: 0,
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium(S.of(context).enable,
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

    AppDialog.show(KeyboardSafeDialog(
      child: StatefulBuilder(
        builder: (context, setDialogState) => SizedBox(
          width: AppDialogWidth.medium,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.all(16),
                child: CustomizedText.labelLarge(
                    S.of(context).pivDisablePinProtectedManagementKey),
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
                        S.of(context).pivDisablePinProtectedManagementKeyPrompt,
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
                      _buildManagementKeyAuthModeControl(
                        usePinOnly: usePinOnly,
                        onChanged: (value) =>
                            setDialogState(() => usePinOnly = value),
                      ),
                      if (!usePinOnly) ...[
                        Spacing.height(16),
                        _buildManagementKeyField(
                          validator,
                          'currentManagementKey',
                          label: S.of(context).pivOldManagementKey,
                        ),
                      ],
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
                                labelText: S.of(context).pivNewManagementKey,
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
                        AppLoaderOverlay.show();
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
                            Prompts.showPrompt(
                                S.current
                                    .pivDisablePinProtectedManagementKeyFailed,
                                ContentThemeColor.danger);
                            return;
                          }
                          await controller.refreshData();
                          Prompts.showPrompt(
                              S.current
                                  .pivDisablePinProtectedManagementKeySuccess,
                              ContentThemeColor.success);
                          Get.back();
                        } finally {
                          AppLoaderOverlay.hide();
                        }
                      },
                      elevation: 0,
                      backgroundColor: contentTheme.primary,
                      child: CustomizedText.labelMedium(S.of(context).disable,
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

    AppDialog.show(KeyboardSafeDialog(
      child: SizedBox(
        width: AppDialogWidth.compact,
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
    TouchPolicy managementKeyTouchPolicy = controller.managementKeyTouchPolicy;
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

    AppDialog.show(KeyboardSafeDialog(
      child: StatefulBuilder(
        builder: (context, setDialogState) => SizedBox(
          width: AppDialogWidth.medium,
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
                          _buildManagementKeyAuthModeControl(
                            usePinOnly: usePinOnly,
                            onChanged: (value) =>
                                setDialogState(() => usePinOnly = value),
                          ),
                        ],
                        if (!usePinOnly) ...[
                          Spacing.height(16),
                          _buildManagementKeyField(
                            validator,
                            'old',
                            label: S.of(context).pivOldManagementKey,
                          ),
                        ],
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
                        if (controller.supportsManagementKeyTouchPolicy) ...[
                          Spacing.height(16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: CustomizedText.bodySmall(
                              S.of(context).pivTouchPolicy,
                              fontWeight: 600,
                            ),
                          ),
                          Spacing.height(8),
                          SegmentedButton<TouchPolicy>(
                            segments: [
                              ButtonSegment(
                                value: TouchPolicy.never,
                                label: Text(S.of(context).pivTouchPolicyNever),
                              ),
                              ButtonSegment(
                                value: TouchPolicy.always,
                                label: Text(S.of(context).pivTouchPolicyAlways),
                              ),
                            ],
                            selected: {managementKeyTouchPolicy},
                            onSelectionChanged: (value) => setDialogState(
                              () => managementKeyTouchPolicy = value.first,
                            ),
                          ),
                        ],
                        if (controller.pinOnlyMode) ...[
                          Spacing.height(12),
                          CheckboxListTile(
                            value: storeOnDevice,
                            onChanged: (value) => setDialogState(
                                () => storeOnDevice = value ?? true),
                            contentPadding: EdgeInsets.zero,
                            title:
                                Text(S.of(context).pivStoreManagementKeyOnCard),
                            subtitle: Text(S
                                .of(context)
                                .pivStoreManagementKeyOnCardPrompt),
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
                        AppLoaderOverlay.show();
                        try {
                          final ok = await controller.changeManagementKey(
                            validator.getController('old')!.text,
                            validator.getController('new')!.text,
                            pin: validator.getController('pin')?.text ?? '',
                            usePinOnly: usePinOnly,
                            storeOnDevice: storeOnDevice,
                            touchPolicy: managementKeyTouchPolicy,
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
                          AppLoaderOverlay.hide();
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
    final slotId = int.parse(slotNumber, radix: 16);
    return PivSlotListItem(
      title: title,
      slotNumber: slotNumber,
      slot: slot,
      hasCertificate: controller.hasCertificate(slotId),
      onTap: () => _showSlotDetailDialog(title, slotNumber, slot),
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
    return S.of(context).pivRetiredSlot(index);
  }

  Widget _slotActionSection(String title, List<Widget> actions) {
    if (actions.isEmpty) {
      return SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomizedText.bodySmall(
          title,
          fontWeight: 600,
          color: contentTheme.onBackground.withAlpha(190),
        ),
        Spacing.height(8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions,
        ),
      ],
    );
  }

  Widget _slotActionButton({
    required String text,
    required VoidCallback onPressed,
    bool danger = false,
  }) {
    return CustomizedButton.rounded(
      onPressed: onPressed,
      elevation: 0,
      padding: Spacing.xy(20, 16),
      backgroundColor: danger ? contentTheme.danger : contentTheme.primary,
      child: CustomizedText.labelMedium(
        text,
        color: danger ? contentTheme.onDanger : contentTheme.onPrimary,
      ),
    );
  }

  Future<void> _showSlotDetailDialog(
      String title, String slotNumber, SlotInfo? slot) async {
    final slotId = int.parse(slotNumber, radix: 16);
    if (controller.supportsMetadataDirectory) {
      slot = await controller.loadSlotDetails(slotId) ?? slot;
      if (!mounted) {
        return;
      }
    }
    final certBytes = controller.certificateBytes[slotId];
    final certificate = controller.certificates[slotId];
    final hasSlotData = slot != null || controller.hasCertificate(slotId);
    final isX25519Slot = slot?.algorithm == AlgorithmType.x25519;
    final isPostQuantumSlot = slot?.algorithm == AlgorithmType.mldsa65 ||
        slot?.algorithm == AlgorithmType.mlkem768;
    final canGenerateX25519Key =
        controller.supportsAlgorithm(AlgorithmType.x25519) &&
            slotNumber == '9D' &&
            (slot == null || isX25519Slot);
    final canGenerateStandaloneKey =
        controller.supportsAlgorithm(AlgorithmType.mlkem768) ||
            canGenerateX25519Key;
    final canGenerateCsr = !isX25519Slot && !isPostQuantumSlot;
    final canSelfSign =
        !isX25519Slot && slot?.algorithm != AlgorithmType.mlkem768;
    final provisioningActions = <Widget>[
      if (canGenerateCsr)
        _slotActionButton(
          text: S.of(context).pivGenerateCsr,
          danger: hasSlotData,
          onPressed: () {
            Navigator.pop(Get.context!);
            _showGenerateDialog(slotNumber, selfSigned: false);
          },
        ),
      if (canSelfSign)
        _slotActionButton(
          text: S.of(context).pivSelfSign,
          danger: hasSlotData,
          onPressed: () {
            Navigator.pop(Get.context!);
            _showGenerateDialog(slotNumber, selfSigned: true);
          },
        ),
      if (canGenerateStandaloneKey)
        _slotActionButton(
          text: S.of(context).pivGenerateKey,
          danger: hasSlotData,
          onPressed: () {
            Navigator.pop(Get.context!);
            _showGenerateKeyDialog(slotNumber);
          },
        ),
      _slotActionButton(
        text: S.of(context).pivImport,
        danger: hasSlotData,
        onPressed: () {
          Navigator.pop(Get.context!);
          _showImportDialog(slotNumber);
        },
      ),
    ];
    final exportActions = <Widget>[
      if (slot != null)
        _slotActionButton(
          text: S.of(context).pivExportPublicKey,
          onPressed: () {
            Navigator.pop(Get.context!);
            _showExportPublicKeyDialog(slot!);
          },
        ),
      if (certBytes != null)
        _slotActionButton(
          text: S.of(context).pivExportCertificate,
          onPressed: () {
            Navigator.pop(Get.context!);
            _showExportDialog(certBytes);
          },
        ),
      if (slot != null &&
          slot.origin == Origin.generated &&
          controller.extendedRetiredSlots &&
          slot.algorithm != AlgorithmType.mlkem768)
        _slotActionButton(
          text: S.of(context).pivDownloadAttestation,
          onPressed: () {
            Navigator.pop(Get.context!);
            _downloadAttestation(slotNumber);
          },
        ),
    ];
    final diagnosticActions = <Widget>[
      if (slot != null &&
          slot.algorithm != AlgorithmType.x25519 &&
          slot.algorithm != AlgorithmType.mlkem768) ...[
        Builder(
          builder: (dialogContext) => _slotActionButton(
            text: S.of(context).pivSignMessage,
            onPressed: () =>
                _showMessageSignDialog(dialogContext, slotNumber, slot!),
          ),
        ),
        _slotActionButton(
          text: S.of(context).pivSignFile,
          onPressed: () {
            Navigator.pop(Get.context!);
            _showFileSignDialog(slotNumber, slot!);
          },
        ),
        if (slot.algorithm != AlgorithmType.mldsa65)
          _slotActionButton(
            text: S.of(context).pivVerifyFile,
            onPressed: () {
              Navigator.pop(Get.context!);
              _showFileVerifyDialog(slot!);
            },
          ),
      ],
    ];
    final dangerActions = <Widget>[
      if (controller.supportsCurrentDevelopmentFeatures &&
          (slot != null || certBytes != null))
        _slotActionButton(
          text: S.of(context).pivClearSlot,
          danger: true,
          onPressed: () {
            Navigator.pop(Get.context!);
            _showDeleteDialog(slotNumber);
          },
        ),
      if (slot != null && controller.extendedRetiredSlots)
        _slotActionButton(
          text: S.of(context).pivMoveKey,
          onPressed: () {
            Navigator.pop(Get.context!);
            _showMoveKeyDialog(slotNumber);
          },
        ),
    ];
    final actionScrollController = ScrollController();

    AppDialog.show(AppDialogSurface(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SizedBox(
          width: slot == null && certificate == null
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
              if (certificate != null && certBytes != null) ...[
                Flexible(
                  child: SingleChildScrollView(
                      padding: Spacing.all(16),
                      child: Form(
                        child: Column(
                          children: [
                            if (slot != null) ...[
                              CustomizedText.bodySmall(
                                _slotUsageHint(slotNumber, slot.algorithm),
                                color: contentTheme.onBackground.withAlpha(180),
                              ),
                              Spacing.height(16),
                            ],
                            TextFormField(
                              initialValue: certificate.subject,
                              readOnly: true,
                              decoration: InputDecoration(
                                  labelText:
                                      S.of(context).pivCertificateSubject,
                                  border: outlineInputBorder,
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.auto),
                            ),
                            Spacing.height(16),
                            TextFormField(
                              initialValue: certificate.issuer,
                              readOnly: true,
                              decoration: InputDecoration(
                                  labelText: S.of(context).pivCertificateIssuer,
                                  border: outlineInputBorder,
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.auto),
                            ),
                            Spacing.height(16),
                            TextFormField(
                              initialValue: certificate.serialNumber,
                              readOnly: true,
                              decoration: InputDecoration(
                                  labelText: S.of(context).pivCertificateSerial,
                                  border: outlineInputBorder,
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.auto),
                            ),
                            Spacing.height(16),
                            TextFormField(
                              initialValue: _certificateKeySummary(certificate),
                              readOnly: true,
                              decoration: InputDecoration(
                                  labelText: S.of(context).pivPublicKey,
                                  border: outlineInputBorder,
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.auto),
                            ),
                            Spacing.height(16),
                            TextFormField(
                              initialValue: x509SignatureAlgorithmName(
                                  certificate.signatureAlgorithm),
                              readOnly: true,
                              decoration: InputDecoration(
                                  labelText:
                                      S.of(context).pivSignatureAlgorithm,
                                  border: outlineInputBorder,
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.auto),
                            ),
                            Spacing.height(16),
                            TextFormField(
                              initialValue: _sha256Fingerprint(certBytes),
                              readOnly: true,
                              decoration: InputDecoration(
                                  labelText: S.of(context).pivSha256Fingerprint,
                                  border: outlineInputBorder,
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.auto),
                            ),
                            Spacing.height(16),
                            TextFormField(
                              initialValue: certificate.notBefore,
                              readOnly: true,
                              decoration: InputDecoration(
                                  labelText:
                                      S.of(context).pivCertificateValidFrom,
                                  border: outlineInputBorder,
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.auto),
                            ),
                            Spacing.height(16),
                            TextFormField(
                              initialValue: certificate.notAfter,
                              readOnly: true,
                              decoration: InputDecoration(
                                  labelText:
                                      S.of(context).pivCertificateValidTo,
                                  border: outlineInputBorder,
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.auto),
                            ),
                            Spacing.height(16),
                            TextFormField(
                              initialValue: _formatBytes(certBytes.length),
                              readOnly: true,
                              decoration: InputDecoration(
                                  labelText: S.of(context).pivCertificateSize,
                                  border: outlineInputBorder,
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.auto),
                            ),
                          ],
                        ),
                      )),
                ),
                Divider(height: 0, thickness: 1)
              ],
              Flexible(
                child: SizedBox(
                  width: double.infinity,
                  child: Scrollbar(
                    controller: actionScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: actionScrollController,
                      padding: Spacing.all(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 24.0;
                          final columnCount = constraints.maxWidth >= 1024
                              ? 3
                              : constraints.maxWidth >= 640
                                  ? 2
                                  : 1;
                          final sectionWidth = (constraints.maxWidth -
                                  spacing * (columnCount - 1)) /
                              columnCount;
                          final sections = <Widget>[
                            _slotActionSection(S.of(context).pivProvisioning,
                                provisioningActions),
                            if (exportActions.isNotEmpty)
                              _slotActionSection(
                                  S.of(context).pivExport, exportActions),
                            if (diagnosticActions.isNotEmpty)
                              _slotActionSection(S.of(context).pivDiagnostics,
                                  diagnosticActions),
                            if (dangerActions.isNotEmpty)
                              _slotActionSection(
                                  S.of(context).pivDangerZone, dangerActions),
                          ];
                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            children: [
                              for (final section in sections)
                                SizedBox(
                                  width: sectionWidth,
                                  child: section,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
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
                      onPressed: () => Navigator.pop(Get.context!),
                      elevation: 0,
                      padding: Spacing.xy(20, 16),
                      backgroundColor: contentTheme.secondary,
                      child: CustomizedText.labelMedium(
                        S.of(context).close,
                        color: contentTheme.onSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )).whenComplete(actionScrollController.dispose);
  }

  void _showExportDialog(Uint8List certificateBytes) {
    AppDialog.show(AppDialogSurface(
        child: SizedBox(
            width: AppDialogWidth.compact,
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
                                final saved = await _savePivFile(
                                  name: 'certificate',
                                  extension: 'der',
                                  bytes: certificateBytes,
                                );
                                if (saved) {
                                  Get.back();
                                }
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
                                        base64.encode(certificateBytes), 64)
                                    .join("\n");
                                String pem =
                                    '${X509Utils.BEGIN_CERT}\n$encodedDer\n${X509Utils.END_CERT}';
                                final saved = await _savePivFile(
                                  name: 'certificate',
                                  extension: 'pem',
                                  bytes: utf8.encode(pem),
                                  mimeType: MimeType.text,
                                );
                                if (saved) {
                                  Get.back();
                                }
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

  void _showExportPublicKeyDialog(SlotInfo slot) {
    final publicKey = controller.publicKeyForSlot(slot);
    if (publicKey == null) {
      Prompts.showPrompt(
          S.of(context).pivNoPublicKeyAvailable, ContentThemeColor.danger);
      return;
    }
    AppDialog.show(AppDialogSurface(
        child: SizedBox(
            width: AppDialogWidth.compact,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                      padding: Spacing.all(16),
                      child: CustomizedText.labelLarge(
                          S.of(context).pivExportPublicKey)),
                  Divider(height: 0, thickness: 1),
                  Padding(
                      padding: Spacing.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomizedText.bodySmall(S
                              .of(context)
                              .pivAlgorithmValue(slot.algorithm.label)),
                          Spacing.height(16),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomizedButton.rounded(
                                  onPressed: () async {
                                    final saved = await _savePivFile(
                                      name: 'public-key',
                                      extension: 'der',
                                      bytes:
                                          publicKey.encodedSubjectPublicKeyInfo,
                                    );
                                    if (saved) {
                                      Get.back();
                                    }
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
                                    final saved = await _savePivFile(
                                      name: 'public-key',
                                      extension: 'pem',
                                      bytes: utf8.encode(publicKey.toPem()),
                                      mimeType: MimeType.text,
                                    );
                                    if (saved) {
                                      Get.back();
                                    }
                                  },
                                  elevation: 0,
                                  padding: Spacing.xy(20, 16),
                                  backgroundColor: contentTheme.primary,
                                  child: CustomizedText.labelMedium('PEM',
                                      color: contentTheme.onPrimary),
                                ),
                              ]),
                        ],
                      ))
                ]))));
  }

  void _showMessageSignDialog(
      BuildContext currentDialogContext, String slotNumber, SlotInfo slot) {
    FormValidator validator = FormValidator();
    validator.addField('pin',
        required: true,
        controller: TextEditingController(),
        validators: [LengthValidator(min: 6, max: 8)]);
    validator.addField('message',
        required: true,
        controller: TextEditingController(text: 'hello canokey'));
    final signature = ''.obs;

    final dialog = KeyboardSafeDialog(
      useCompositedKeyboardMotion: true,
      child: SizedBox(
        width: AppDialogWidth.medium,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.of(context).pivSignMessage),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Form(
                key: validator.formKey,
                child: Column(
                  children: [
                    TextFormField(
                      onTap: SmartCard.eject,
                      obscureText: true,
                      controller: validator.getController('pin'),
                      validator: validator.getValidator('pin'),
                      decoration: InputDecoration(
                          labelText: 'PIN', border: outlineInputBorder),
                    ),
                    Spacing.height(16),
                    TextFormField(
                      controller: validator.getController('message'),
                      validator: validator.getValidator('message'),
                      maxLines: 3,
                      decoration: InputDecoration(
                          labelText: S.of(context).pivMessage,
                          border: outlineInputBorder),
                    ),
                    Obx(() => signature.value.isEmpty
                        ? SizedBox.shrink()
                        : Column(
                            children: [
                              Spacing.height(16),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: CustomizedText.bodyMedium(
                                  S.of(context).pivSignatureHex,
                                  fontWeight: 600,
                                ),
                              ),
                              Spacing.height(8),
                              Container(
                                width: double.infinity,
                                constraints: BoxConstraints(maxHeight: 120),
                                padding: Spacing.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: contentTheme.cardBorder),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: SingleChildScrollView(
                                  child: SelectableText(signature.value),
                                ),
                              ),
                            ],
                          )),
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
                      AppLoaderOverlay.show();
                      try {
                        final result = await controller.signData(
                          slotNumber,
                          slot,
                          validator.getController('pin')!.text,
                          Uint8List.fromList(utf8.encode(
                              validator.getController('message')!.text)),
                        );
                        if (result == null) {
                          Prompts.showPrompt(S.current.pivMessageSigningFailed,
                              ContentThemeColor.danger);
                          return;
                        }
                        signature.value = hex.encode(result);
                      } finally {
                        AppLoaderOverlay.hide();
                      }
                    },
                    elevation: 0,
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium(S.of(context).pivSign,
                        color: contentTheme.onPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    AppDialog.replace(
      currentDialogContext,
      dialog,
      useSafeArea: false,
    );
  }

  void _showFileSignDialog(String slotNumber, SlotInfo slot) {
    FormValidator validator = FormValidator();
    validator.addField('pin',
        required: true,
        controller: TextEditingController(),
        validators: [LengthValidator(min: 6, max: 8)]);
    final selectedFileName = ''.obs;
    Uint8List? selectedBytes;

    AppDialog.show(KeyboardSafeDialog(
      child: Obx(
        () => SizedBox(
          width: AppDialogWidth.medium,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.all(16),
                child: CustomizedText.labelLarge(S.of(context).pivSignFile),
              ),
              Divider(height: 0, thickness: 1),
              Padding(
                padding: Spacing.all(16),
                child: Form(
                  key: validator.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomizedText.bodySmall(S.of(context).pivSignFilePrompt),
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
                      Row(
                        children: [
                          Expanded(
                            child: CustomizedText.bodyMedium(
                              selectedFileName.value.isEmpty
                                  ? S.of(context).pivNoFileSelected
                                  : selectedFileName.value,
                            ),
                          ),
                          Spacing.width(12),
                          CustomizedButton.rounded(
                            onPressed: () async {
                              final result = await FilePicker.pickFiles();
                              final file = result.firstOrNull;
                              if (file == null) return;
                              selectedFileName.value = file.name;
                              selectedBytes = await file.xFile.readAsBytes();
                            },
                            elevation: 0,
                            backgroundColor: contentTheme.primary,
                            child: CustomizedText.labelMedium(
                                S.of(context).select,
                                color: contentTheme.onPrimary),
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
                        final data = selectedBytes;
                        if (data == null) {
                          Prompts.showPrompt(S.of(context).pivSelectFileFirst,
                              ContentThemeColor.danger);
                          return;
                        }
                        AppLoaderOverlay.show();
                        try {
                          final signature = await controller.signData(
                            slotNumber,
                            slot,
                            validator.getController('pin')!.text,
                            data,
                          );
                          if (signature == null) {
                            Prompts.showPrompt(S.current.pivFileSigningFailed,
                                ContentThemeColor.danger);
                            return;
                          }
                          final saved = await _savePivFile(
                            name: selectedFileName.value.isEmpty
                                ? 'signature'
                                : selectedFileName.value,
                            extension: 'sig',
                            bytes: signature,
                          );
                          if (saved) {
                            Get.back();
                          }
                        } finally {
                          AppLoaderOverlay.hide();
                        }
                      },
                      elevation: 0,
                      backgroundColor: contentTheme.primary,
                      child: CustomizedText.labelMedium(S.of(context).pivSign,
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

  void _showFileVerifyDialog(SlotInfo slot) {
    final selectedFileName = ''.obs;
    final selectedSignatureName = ''.obs;
    final verifyResult = ''.obs;
    Uint8List? selectedBytes;
    Uint8List? selectedSignature;

    AppDialog.show(AppDialogSurface(
      child: Obx(
        () => SizedBox(
          width: AppDialogWidth.medium,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.all(16),
                child: CustomizedText.labelLarge(
                    S.of(context).pivVerifyFileSignature),
              ),
              Divider(height: 0, thickness: 1),
              Padding(
                padding: Spacing.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomizedText.bodySmall(
                        S.of(context).pivVerifyFileSignaturePrompt),
                    Spacing.height(16),
                    _buildFilePickerRow(
                      label: S.of(context).pivFile,
                      value: selectedFileName.value,
                      onPick: () async {
                        final result = await FilePicker.pickFiles();
                        final file = result.firstOrNull;
                        if (file == null) return;
                        selectedFileName.value = file.name;
                        selectedBytes = await file.xFile.readAsBytes();
                        verifyResult.value = '';
                      },
                    ),
                    Spacing.height(12),
                    _buildFilePickerRow(
                      label: S.of(context).pivSignatureFile,
                      value: selectedSignatureName.value,
                      onPick: () async {
                        final result = await FilePicker.pickFiles();
                        final file = result.firstOrNull;
                        if (file == null) return;
                        selectedSignatureName.value = file.name;
                        selectedSignature = await file.xFile.readAsBytes();
                        verifyResult.value = '';
                      },
                    ),
                    if (verifyResult.value.isNotEmpty) ...[
                      Spacing.height(16),
                      CustomizedText.bodyMedium(
                        verifyResult.value,
                        color:
                            verifyResult.value == S.current.pivSignatureVerified
                                ? contentTheme.success
                                : contentTheme.danger,
                      ),
                    ],
                  ],
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
                      child: CustomizedText.labelMedium(S.of(context).close,
                          color: contentTheme.onSecondary),
                    ),
                    Spacing.width(12),
                    CustomizedButton.rounded(
                      onPressed: () async {
                        final data = selectedBytes;
                        final signature = selectedSignature;
                        if (data == null || signature == null) {
                          Prompts.showPrompt(
                              S.of(context).pivSelectFileAndSignatureFirst,
                              ContentThemeColor.danger);
                          return;
                        }
                        final ok = await controller.verifySignature(
                          slot,
                          data,
                          signature,
                        );
                        verifyResult.value = ok
                            ? S.current.pivSignatureVerified
                            : S.current.pivSignatureVerificationFailed;
                      },
                      elevation: 0,
                      backgroundColor: contentTheme.primary,
                      child: CustomizedText.labelMedium(S.of(context).pivVerify,
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

  Widget _buildFilePickerRow({
    required String label,
    required String value,
    required VoidCallback onPick,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomizedText.bodySmall(label, fontWeight: 600),
              Spacing.height(4),
              CustomizedText.bodyMedium(
                value.isEmpty ? S.of(context).pivNotSelected : value,
              ),
            ],
          ),
        ),
        Spacing.width(12),
        CustomizedButton.rounded(
          onPressed: onPick,
          elevation: 0,
          backgroundColor: contentTheme.primary,
          child: CustomizedText.labelMedium(S.of(context).select,
              color: contentTheme.onPrimary),
        ),
      ],
    );
  }

  void _showImportDialog(String slotNumber) {
    Rx<int> step = 0.obs;
    Rx<bool> hasCert = false.obs;
    Rx<bool> hasKey = false.obs;
    Rx<bool> selected = false.obs;
    Rx<String> parseMessage = ''.obs;
    RxList<String> importWarnings = <String>[].obs;
    RxList<String> importErrors = <String>[].obs;
    PinPolicy pinPolicy = recommendedPivPinPolicy(slotNumber);
    TouchPolicy touchPolicy = TouchPolicy.never;
    bool usePinOnly = controller.pinOnlyMode;
    FormValidator authValidator = FormValidator();
    authValidator.addField('pin',
        required: true,
        controller: TextEditingController(),
        validators: [LengthValidator(min: 6, max: 8)]);
    authValidator.addField('managementKey',
        required: false,
        controller: TextEditingController(),
        validators: [
          LengthValidator(exact: 48, required: false),
          HexStringValidator(required: false)
        ]);
    ECPrivateKey? ecPrivateKey;
    RSAPrivateKey? rsaPrivateKey;
    Uint8List? edPrivateKey;
    X509CertData? cert;
    Uint8List? certBytes;

    bool certificateMatchesSelectedKey() {
      if (certBytes == null || !hasKey.value) {
        return true;
      }
      return _certificateMatchesPrivateKey(
        certBytes: certBytes!,
        ecPrivateKey: ecPrivateKey,
        rsaPrivateKey: rsaPrivateKey,
        edPrivateKey: edPrivateKey,
      );
    }

    bool validateSelectedImport() {
      if (importErrors.isNotEmpty) {
        Prompts.showPrompt(importErrors.first, ContentThemeColor.danger);
        return false;
      }
      return true;
    }

    void analyzeSelectedImport() {
      importWarnings.clear();
      importErrors.clear();

      final algorithm = _selectedImportAlgorithm(
        ecPrivateKey: ecPrivateKey,
        rsaPrivateKey: rsaPrivateKey,
        edPrivateKey: edPrivateKey,
      );

      if (algorithm != null && !controller.supportsAlgorithm(algorithm)) {
        importErrors.add(
            '${_algorithmLabel(algorithm)}: ${S.of(context).notSupported}');
      }

      if (slotNumber != '9D' && algorithm == AlgorithmType.x25519) {
        importErrors.add(S.of(context).pivX25519OnlyIn9D);
      }
      if (certBytes != null &&
          hasKey.value &&
          !certificateMatchesSelectedKey()) {
        importErrors.add(S.of(context).pivCertificateDoesNotMatchPrivateKey);
      }
      if (certBytes != null && algorithm == AlgorithmType.x25519) {
        importErrors.add(S.of(context).pivX25519CannotUseCertificate);
      }

      if (hasKey.value && _slotHasKey(slotNumber)) {
        importWarnings.add(S.of(context).pivImportWillReplacePrivateKey);
      }
      if (certBytes != null && _slotHasCertificate(slotNumber)) {
        importWarnings.add(S.of(context).pivImportWillReplaceCertificate);
      }
      if (certBytes != null && !hasKey.value && _slotHasKey(slotNumber)) {
        importWarnings.add(S.of(context).pivCertificateOnlyKeepsPrivateKey);
      }
      if (certBytes == null &&
          hasKey.value &&
          _slotHasCertificate(slotNumber)) {
        importWarnings.add(S.of(context).pivKeyOnlyKeepsCertificate);
      }
    }

    void nextStep() async {
      if (step.value == 0) {
        if (!authValidator.validateForm()) return;
        if (!_validateManagementKeyInput(
            authValidator, 'managementKey', usePinOnly)) {
          return;
        }
        setState(() => step.value++);
        return;
      }
      if (step.value == 1) {
        if (!hasCert.value && !hasKey.value) {
          Prompts.showPrompt(S.of(context).pivSelectCertificateOrKeyFirst,
              ContentThemeColor.danger);
          return;
        }
        if (!validateSelectedImport()) {
          return;
        }
        setState(() => step.value++);
        return;
      }
      if (step.value == 2) {
        setState(() => step.value++);
        return;
      }

      if (!validateSelectedImport()) {
        return;
      }

      if (hasKey.value &&
          !await _confirmOverwriteKey(
              slotNumber: slotNumber,
              action: S.of(context).pivImportingPrivateKey)) {
        return;
      }

      AppLoaderOverlay.show();
      try {
        final importSuccess = await controller.importAuthenticated(
          slot: slotNumber,
          pin: authValidator.getController('pin')!.text,
          managementKey: authValidator.getController('managementKey')!.text,
          usePinOnly: usePinOnly,
          ecPrivateKey: ecPrivateKey,
          rsaPrivateKey: rsaPrivateKey,
          edPrivateKey: edPrivateKey,
          cert: certBytes,
          pinPolicy: pinPolicy,
          touchPolicy: touchPolicy,
        );
        if (!importSuccess) {
          Prompts.showPrompt(
              S.current.pivImportFailed, ContentThemeColor.danger);
          return;
        }

        await controller.refreshData();
        Prompts.showPrompt(
            S.current.pivImportSucceeded, ContentThemeColor.success);
        Navigator.pop(Get.context!);
      } finally {
        AppLoaderOverlay.hide();
      }
    }

    void prevStep() {
      if (step.value == 0) {
        Get.back();
      } else if (step.value > 0) {
        setState(() => step.value--);
      }
    }

    void resetImportState() {
      hasCert.value = false;
      hasKey.value = false;
      ecPrivateKey = null;
      rsaPrivateKey = null;
      edPrivateKey = null;
      cert = null;
      certBytes = null;
      parseMessage.value = '';
      importWarnings.clear();
      importErrors.clear();
    }

    void parsePem(Uint8List bytes) {
      final pem = utf8.decode(bytes, allowMalformed: true);
      pem.split('-----BEGIN ').forEach((element) {
        if (element.isNotEmpty) {
          final item = '-----BEGIN $element';
          try {
            if (item.startsWith(CryptoUtils.BEGIN_EC_PRIVATE_KEY)) {
              ecPrivateKey = CryptoUtils.ecPrivateKeyFromPem(item);
              hasKey.value = true;
            } else if (item.startsWith(CryptoUtils.BEGIN_RSA_PRIVATE_KEY)) {
              rsaPrivateKey = CryptoUtils.rsaPrivateKeyFromPemPkcs1(item);
              hasKey.value = true;
            } else if (item.startsWith(CryptoUtils.BEGIN_PRIVATE_KEY)) {
              try {
                rsaPrivateKey = CryptoUtils.rsaPrivateKeyFromPem(item);
              } catch (_) {
                try {
                  ecPrivateKey = CryptoUtils.ecPrivateKeyFromPem(item);
                } catch (_) {
                  edPrivateKey = CryptoUtils.ed25519PrivateKeyFromPem(item);
                }
              }
              hasKey.value = true;
            } else if (item.startsWith(X509Utils.BEGIN_CERT)) {
              cert = parseX509CertFromPem(pem: item);
              certBytes = cert!.bytes;
              hasCert.value = true;
            }
          } catch (e) {
            parseMessage.value = e.toString();
          }
        }
      });
    }

    void parseDer(Uint8List bytes) {
      try {
        cert = parseX509CertFromDer(der: bytes);
        certBytes = cert!.bytes;
        hasCert.value = true;
        return;
      } catch (_) {}
      try {
        rsaPrivateKey = CryptoUtils.rsaPrivateKeyFromDERBytes(bytes);
        hasKey.value = true;
        return;
      } catch (_) {}
      try {
        rsaPrivateKey = CryptoUtils.rsaPrivateKeyFromDERBytesPkcs1(bytes);
        hasKey.value = true;
        return;
      } catch (_) {}
      try {
        ecPrivateKey = CryptoUtils.ecPrivateKeyFromDerBytes(bytes, pkcs8: true);
        hasKey.value = true;
        return;
      } catch (_) {}
      try {
        ecPrivateKey = CryptoUtils.ecPrivateKeyFromDerBytes(bytes);
        hasKey.value = true;
        return;
      } catch (e) {
        parseMessage.value = e.toString();
      }
    }

    void parseImportFile(Uint8List bytes) {
      resetImportState();
      final text = utf8.decode(bytes, allowMalformed: true);
      if (text.contains('-----BEGIN ')) {
        parsePem(bytes);
      } else {
        parseDer(bytes);
      }
      if (!hasCert.value && !hasKey.value && parseMessage.value.isEmpty) {
        parseMessage.value = S.of(context).pivUnsupportedImportFile;
      }
      analyzeSelectedImport();
    }

    String keySummary() {
      final algorithm = _selectedImportAlgorithm(
        ecPrivateKey: ecPrivateKey,
        rsaPrivateKey: rsaPrivateKey,
        edPrivateKey: edPrivateKey,
      );
      if (algorithm == null) {
        return S.of(context).pivEmpty;
      }
      return _algorithmLabel(algorithm);
    }

    AppDialog.show(AppDialogSurface(
      child: Obx(
        () => SizedBox(
          width: AppDialogWidth.medium,
          child: Stepper(
            currentStep: step.value,
            onStepContinue: nextStep,
            onStepCancel: prevStep,
            controlsBuilder: (BuildContext context, ControlsDetails details) {
              return Row(
                children: <Widget>[
                  CustomizedButton.rounded(
                    onPressed: details.onStepContinue,
                    elevation: 0,
                    backgroundColor: ContentThemeColor.primary.color,
                    child: CustomizedText.labelMedium(
                        step.value == 3
                            ? S.of(context).pivImport
                            : S.of(context).next,
                        color: ContentThemeColor.primary.onColor),
                  ),
                  Spacing.width(12),
                  CustomizedButton.rounded(
                    onPressed: details.onStepCancel,
                    elevation: 0,
                    backgroundColor: ContentThemeColor.secondary.color,
                    child: CustomizedText.labelMedium(
                        step.value == 0
                            ? S.of(context).cancel
                            : S.of(context).back,
                        color: ContentThemeColor.secondary.onColor),
                  ),
                ],
              );
            },
            steps: [
              Step(
                title: Text(S.of(context).pivVerifyPinAndManagementKey),
                content: StatefulBuilder(
                  builder: (context, setDialogState) => Form(
                    key: authValidator.formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          autofocus: true,
                          onTap: SmartCard.eject,
                          obscureText: true,
                          controller: authValidator.getController('pin'),
                          validator: authValidator.getValidator('pin'),
                          decoration: InputDecoration(
                              labelText: 'PIN', border: outlineInputBorder),
                        ),
                        if (controller.pinOnlyMode) ...[
                          Spacing.height(12),
                          _buildManagementKeyAuthModeControl(
                            usePinOnly: usePinOnly,
                            onChanged: (value) =>
                                setDialogState(() => usePinOnly = value),
                          ),
                        ],
                        if (!usePinOnly) ...[
                          Spacing.height(18),
                          _buildManagementKeyField(
                            authValidator,
                            'managementKey',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Step(
                title: Text(S.of(context).pivSelectFile),
                content: InkWell(
                  onTap: () async {
                    final result = await FilePicker.pickFiles();
                    final file = result.firstOrNull;
                    if (file != null) {
                      selected.value = true;
                      parseImportFile(await file.xFile.readAsBytes());
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
                                S.of(context).pivSelectFilePrompt,
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
                                  parseMessage.value.isEmpty
                                      ? S.of(context).pivSelectFileHint
                                      : parseMessage.value,
                                  muted: true,
                                  fontWeight: 500,
                                  fontSize: 12,
                                  textAlign: TextAlign.center,
                                  color: contentTheme.danger,
                                ),
                              ),
                            if (importErrors.isNotEmpty) ...[
                              Spacing.height(8),
                              for (final message in importErrors)
                                CustomizedText.bodySmall(
                                  message,
                                  color: contentTheme.danger,
                                  textAlign: TextAlign.center,
                                ),
                            ],
                            if (importErrors.isEmpty &&
                                importWarnings.isNotEmpty) ...[
                              Spacing.height(8),
                              for (final message in importWarnings)
                                CustomizedText.bodySmall(
                                  message,
                                  color: contentTheme.warning,
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Step(
                title: Text(S.of(context).pivPinAndTouchPolicy),
                content: Column(
                  children: [
                    CustomizedText.bodySmall(
                      _slotUsageHint(
                          slotNumber,
                          _selectedImportAlgorithm(
                                ecPrivateKey: ecPrivateKey,
                                rsaPrivateKey: rsaPrivateKey,
                                edPrivateKey: edPrivateKey,
                              ) ??
                              AlgorithmType.eccp256),
                    ),
                    Spacing.height(12),
                    DropdownButtonFormField(
                      initialValue: pinPolicy,
                      items: [PinPolicy.never, PinPolicy.once, PinPolicy.always]
                          .map((e) => DropdownMenuItem(
                              value: e, child: Text(e.toString())))
                          .toList(),
                      onChanged: (value) => setState(() => pinPolicy = value!),
                      decoration: InputDecoration(
                          labelText: S.of(context).pivPinPolicy),
                      dropdownColor: contentTheme.background,
                    ),
                    Spacing.height(12),
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
                      decoration: InputDecoration(
                          labelText: S.of(context).pivTouchPolicy),
                      dropdownColor: contentTheme.background,
                    ),
                  ],
                ),
              ),
              Step(
                  title: Text(S.of(context).pivReview),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomizedText.bodyMedium(
                          '${S.of(context).pivPrivateKey}: ${hasKey.value ? keySummary() : S.of(context).pivEmpty}'),
                      Spacing.height(8),
                      if (cert != null)
                        CustomizedText.bodyMedium(
                            '${S.of(context).pivCertificate}: ${cert!.subject != "" ? cert!.subject : S.of(context).pivEmpty}'),
                      if (cert != null) ...[
                        Spacing.height(8),
                        CustomizedText.bodyMedium(
                            '${S.of(context).pivCertificateKey}: ${_certificateKeySummary(cert!)}'),
                      ],
                      if (certBytes != null && hasKey.value) ...[
                        Spacing.height(8),
                        CustomizedText.bodyMedium(
                          certificateMatchesSelectedKey()
                              ? S.of(context).pivCertificateMatchesPrivateKey
                              : S.of(context).pivCertificateMismatchPrivateKey,
                          color: certificateMatchesSelectedKey()
                              ? contentTheme.success
                              : contentTheme.danger,
                        ),
                      ],
                      if (importWarnings.isNotEmpty) ...[
                        Spacing.height(12),
                        for (final message in importWarnings) ...[
                          CustomizedText.bodySmall(
                            message,
                            color: contentTheme.warning,
                          ),
                          Spacing.height(4),
                        ],
                      ],
                      Spacing.height(8),
                      CustomizedText.bodyMedium(
                          '${S.of(context).pivPinPolicy}: $pinPolicy'),
                      Spacing.height(8),
                      CustomizedText.bodyMedium(
                          '${S.of(context).pivTouchPolicy}: $touchPolicy'),
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
    PinPolicy pinPolicy = recommendedPivPinPolicy(slotNumber);
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
      if (!await _confirmOverwriteKey(
          slotNumber: slotNumber,
          action: selfSigned
              ? S.of(context).pivCreatingSelfSignedCertificate
              : S.of(context).pivGeneratingCsr)) {
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

      AppLoaderOverlay.show();
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
                S.current.pivCreateCertificateFailed, ContentThemeColor.danger);
            return;
          }
          await controller.refreshData();
          Prompts.showPrompt(
              S.current.pivCertificateCreated, ContentThemeColor.success);
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
            Prompts.showPrompt(
                S.current.pivGenerateCsrFailed, ContentThemeColor.danger);
            return;
          }

          await controller.refreshData();
          Prompts.showPrompt(
              S.current.pivCsrGenerated, ContentThemeColor.success);
          Navigator.pop(Get.context!);
          _showCsrResultDialog(slotNumber, csr);
        }
      } finally {
        AppLoaderOverlay.hide();
      }
    }

    void prevStep() {
      if (step.value == 0) {
        Get.back();
      } else {
        step.value--;
      }
    }

    AppDialog.show(AppDialogSurface(
      child: Obx(
        () => SizedBox(
          width: AppDialogWidth.medium,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: Spacing.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CustomizedText.labelLarge(
                    selfSigned
                        ? S.of(context).pivSelfSignCertificate
                        : S.of(context).pivGenerateCsr,
                  ),
                ),
              ),
              Divider(height: 0, thickness: 1),
              Flexible(
                child: Stepper(
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
                            : AppTheme.theme.colorScheme.onSurface
                                .withAlpha(96),
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
                                      ? S.of(context).pivCreateCertificate
                                      : S.of(context).pivGenerateCsr)
                                  : S.of(context).next,
                              color: ContentThemeColor.primary.onColor),
                        ),
                        Spacing.width(12),
                        CustomizedButton.rounded(
                          onPressed: details.onStepCancel,
                          elevation: 0,
                          backgroundColor: ContentThemeColor.secondary.color,
                          child: CustomizedText.labelMedium(
                              step.value == 0
                                  ? S.of(context).cancel
                                  : S.of(context).back,
                              color: ContentThemeColor.secondary.onColor),
                        ),
                      ],
                    );
                  },
                  steps: [
                    Step(
                      isActive: step.value == 0,
                      state: step.value == 0
                          ? StepState.editing
                          : StepState.indexed,
                      title: Text(S.of(context).pivVerifyPinAndManagementKey),
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
                                    labelText: 'PIN',
                                    border: outlineInputBorder),
                              ),
                              if (controller.pinOnlyMode) ...[
                                Spacing.height(12),
                                _buildManagementKeyAuthModeControl(
                                  usePinOnly: usePinOnly,
                                  onChanged: (value) =>
                                      setState(() => usePinOnly = value),
                                ),
                              ],
                              if (!usePinOnly) ...[
                                Spacing.height(18),
                                _buildManagementKeyField(
                                  pinValidator,
                                  'managementKey',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    Step(
                      isActive: step.value == 1,
                      state: step.value == 1
                          ? StepState.editing
                          : StepState.indexed,
                      title: Text(S.of(context).pivKeyOptions),
                      content: Padding(
                        padding: Spacing.top(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomizedText.bodySmall(
                              selfSigned
                                  ? S
                                      .of(context)
                                      .pivSelfSignedCertificateWarning
                                  : S.of(context).pivCsrGenerationPrompt,
                              color: contentTheme.onBackground.withAlpha(180),
                            ),
                            Spacing.height(12),
                            DropdownButtonFormField(
                              initialValue: algorithm,
                              items: [
                                AlgorithmType.eccp256,
                                AlgorithmType.eccp384,
                                AlgorithmType.eccp521,
                                AlgorithmType.secp256k1,
                                AlgorithmType.sm2,
                                AlgorithmType.ed25519,
                                if (selfSigned) AlgorithmType.mldsa65,
                                AlgorithmType.rsa2048,
                                AlgorithmType.rsa3072,
                                AlgorithmType.rsa4096,
                              ]
                                  .where(controller.supportsAlgorithm)
                                  .map((e) => DropdownMenuItem(
                                      value: e, child: Text(e.label)))
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => algorithm = value!),
                              decoration: InputDecoration(
                                  labelText: S.of(context).pivAlgorithm),
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
                              decoration: InputDecoration(
                                  labelText: S.of(context).pivPinPolicy),
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
                              decoration: InputDecoration(
                                  labelText: S.of(context).pivTouchPolicy),
                              dropdownColor: contentTheme.background,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Step(
                      isActive: step.value == 2,
                      state: step.value == 2
                          ? StepState.editing
                          : StepState.indexed,
                      title: Text(selfSigned
                          ? S.of(context).pivCertificateSubjectStep
                          : S.of(context).pivCsrSubject),
                      content: Padding(
                        padding: Spacing.top(10),
                        child: Form(
                          key: subjectValidator.formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller:
                                    subjectValidator.getController('cn'),
                                validator: subjectValidator.getValidator('cn'),
                                decoration: InputDecoration(
                                    labelText: S.of(context).pivCommonName,
                                    border: outlineInputBorder),
                              ),
                              Spacing.height(18),
                              TextFormField(
                                controller: subjectValidator.getController('o'),
                                validator: subjectValidator.getValidator('o'),
                                decoration: InputDecoration(
                                    labelText: S.of(context).pivOrganization,
                                    border: outlineInputBorder),
                              ),
                              Spacing.height(18),
                              TextFormField(
                                controller:
                                    subjectValidator.getController('ou'),
                                validator: subjectValidator.getValidator('ou'),
                                decoration: InputDecoration(
                                    labelText:
                                        S.of(context).pivOrganizationalUnit,
                                    border: outlineInputBorder),
                              ),
                              Spacing.height(18),
                              TextFormField(
                                controller: subjectValidator.getController('c'),
                                validator: subjectValidator.getValidator('c'),
                                decoration: InputDecoration(
                                    labelText: S.of(context).pivCountryCode,
                                    border: outlineInputBorder),
                              ),
                              Spacing.height(18),
                              TextFormField(
                                controller:
                                    subjectValidator.getController('sans'),
                                validator:
                                    subjectValidator.getValidator('sans'),
                                decoration: InputDecoration(
                                    labelText: S.of(context).pivDnsSans,
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
                                      labelText: S.of(context).pivValidityDays,
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
              ),
            ],
          ),
        ),
      ),
    ));
  }

  void _showGenerateKeyDialog(String slotNumber) {
    final algorithms = <AlgorithmType>[
      if (slotNumber == '9D') AlgorithmType.x25519,
      AlgorithmType.mlkem768,
    ].where(controller.supportsAlgorithm).toList();
    AlgorithmType algorithm = algorithms.first;
    PinPolicy pinPolicy = recommendedPivPinPolicy(slotNumber);
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

    AppDialog.show(KeyboardSafeDialog(
      child: StatefulBuilder(
        builder: (context, setDialogState) => SizedBox(
          width: AppDialogWidth.medium,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.all(16),
                child: CustomizedText.labelLarge(S.of(context).pivGenerateKey),
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
                        _buildManagementKeyAuthModeControl(
                          usePinOnly: usePinOnly,
                          onChanged: (value) =>
                              setDialogState(() => usePinOnly = value),
                        ),
                      ],
                      if (!usePinOnly) ...[
                        Spacing.height(18),
                        _buildManagementKeyField(
                          validator,
                          'managementKey',
                        ),
                      ],
                      Spacing.height(18),
                      DropdownButtonFormField(
                        initialValue: algorithm,
                        items: algorithms
                            .map((value) => DropdownMenuItem(
                                value: value, child: Text(value.label)))
                            .toList(),
                        onChanged: (value) =>
                            setDialogState(() => algorithm = value!),
                        decoration: InputDecoration(
                            labelText: S.of(context).pivAlgorithm),
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
                        decoration: InputDecoration(
                            labelText: S.of(context).pivPinPolicy),
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
                        decoration: InputDecoration(
                            labelText: S.of(context).pivTouchPolicy),
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
                        if (!await _confirmOverwriteKey(
                            slotNumber: slotNumber,
                            action: S
                                .of(context)
                                .pivGeneratingKey(algorithm.label))) {
                          return;
                        }
                        AppLoaderOverlay.show();
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
                            Prompts.showPrompt(S.current.pivGenerateKeyFailed,
                                ContentThemeColor.danger);
                            return;
                          }
                          await controller.refreshData();
                          Prompts.showPrompt(S.current.pivKeyGenerated,
                              ContentThemeColor.success);
                          Navigator.pop(Get.context!);
                        } finally {
                          AppLoaderOverlay.hide();
                        }
                      },
                      elevation: 0,
                      backgroundColor: contentTheme.primary,
                      child: CustomizedText.labelMedium(
                          S.of(context).pivGenerate,
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

  void _showCsrResultDialog(String slotNumber, String csr) {
    AppDialog.show(AppDialogSurface(
      child: SizedBox(
        width: AppDialogWidth.large,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.current.pivCsrGenerated),
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
                          S.current.pivCsrCopied, ContentThemeColor.success);
                    },
                    elevation: 0,
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium(S.of(context).copy,
                        color: contentTheme.onPrimary),
                  ),
                  Spacing.width(12),
                  CustomizedButton.rounded(
                    onPressed: () async {
                      await _savePivFile(
                        name: 'piv-$slotNumber',
                        extension: 'csr',
                        bytes: utf8.encode(csr),
                        mimeType: MimeType.text,
                      );
                    },
                    elevation: 0,
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium(S.of(context).save,
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
    AppDialog.show(AppDialogSurface(
      child: SizedBox(
        width: AppDialogWidth.medium,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.current.pivCertificateCreated),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.bodyMedium(
                  S.of(context).pivCertificateWritten(slotNumber)),
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
                      Prompts.showPrompt(S.current.pivCertificateCopied,
                          ContentThemeColor.success);
                    },
                    elevation: 0,
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium(S.of(context).pivCopyPem,
                        color: contentTheme.onPrimary),
                  ),
                  Spacing.width(12),
                  CustomizedButton.rounded(
                    onPressed: () async {
                      await _savePivFile(
                        name: 'piv-$slotNumber',
                        extension: 'pem',
                        bytes: utf8.encode(pem),
                        mimeType: MimeType.text,
                      );
                    },
                    elevation: 0,
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium(S.of(context).pivSavePem,
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

  Future<void> _downloadAttestation(String slotNumber) async {
    AppLoaderOverlay.show();
    try {
      final certificate = await controller.attestKey(slotNumber);
      if (certificate == null || certificate.isEmpty) {
        Prompts.showPrompt(
          S.current.pivAttestationUnavailable,
          ContentThemeColor.danger,
        );
        return;
      }
      await _savePivFile(
        name: 'piv-attestation-${slotNumber.toLowerCase()}',
        extension: 'der',
        bytes: certificate,
      );
    } finally {
      AppLoaderOverlay.hide();
    }
  }

  void _showMoveKeyDialog(String sourceSlot) {
    final source = int.parse(sourceSlot, radix: 16);
    final candidateSlots = <int>[
      0x9A,
      0x9C,
      0x9D,
      0x9E,
      ..._retiredSlots(),
    ];
    final targets = candidateSlots
        .where((slot) => slot != source && controller.slots[slot] == null)
        .toList(growable: false);
    if (targets.isEmpty) {
      Prompts.showPrompt(
        S.of(context).pivNoEmptyDestinationSlot,
        ContentThemeColor.warning,
      );
      return;
    }

    bool usePinOnly = controller.pinOnlyMode;
    var targetSlot = targets.first;
    final validator = FormValidator();
    validator.addField(
      'pin',
      required: usePinOnly,
      controller: TextEditingController(),
      validators: [LengthValidator(min: 6, max: 8, required: usePinOnly)],
    );
    validator.addField(
      'managementKey',
      required: !usePinOnly,
      controller: TextEditingController(),
      validators: [
        LengthValidator(exact: 48, required: !usePinOnly),
        HexStringValidator(required: !usePinOnly),
      ],
    );

    AppDialog.show(KeyboardSafeDialog(
      child: StatefulBuilder(
        builder: (context, setDialogState) => SizedBox(
          width: AppDialogWidth.medium,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.all(16),
                child: CustomizedText.labelLarge(
                  S.of(context).pivMoveKeyFrom(sourceSlot),
                ),
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
                        S.of(context).pivMoveKeyPrompt,
                        color: contentTheme.onBackground.withAlpha(190),
                      ),
                      Spacing.height(16),
                      DropdownButtonFormField<int>(
                        initialValue: targetSlot,
                        decoration: InputDecoration(
                          labelText: S.of(context).pivDestinationSlot,
                          border: outlineInputBorder,
                        ),
                        items: [
                          for (final slot in targets)
                            DropdownMenuItem(
                              value: slot,
                              child: Text(slot
                                  .toRadixString(16)
                                  .padLeft(2, '0')
                                  .toUpperCase()),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => targetSlot = value);
                          }
                        },
                      ),
                      if (controller.pinOnlyMode) ...[
                        Spacing.height(12),
                        _buildManagementKeyAuthModeControl(
                          usePinOnly: usePinOnly,
                          onChanged: (value) =>
                              setDialogState(() => usePinOnly = value),
                        ),
                      ],
                      if (usePinOnly) ...[
                        Spacing.height(16),
                        TextFormField(
                          autofocus: true,
                          onTap: SmartCard.eject,
                          obscureText: true,
                          controller: validator.getController('pin'),
                          validator: validator.getValidator('pin'),
                          decoration: InputDecoration(
                            labelText: 'PIN',
                            border: outlineInputBorder,
                          ),
                        ),
                      ],
                      if (!usePinOnly) ...[
                        Spacing.height(16),
                        _buildManagementKeyField(
                          validator,
                          'managementKey',
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
                      onPressed: () => Get.back(),
                      elevation: 0,
                      backgroundColor: contentTheme.secondary,
                      child: CustomizedText.labelMedium(
                        S.of(context).cancel,
                        color: contentTheme.onSecondary,
                      ),
                    ),
                    Spacing.width(12),
                    CustomizedButton.rounded(
                      onPressed: () async {
                        if (!validator.validateForm() ||
                            !_validateManagementKeyInput(
                                validator, 'managementKey', usePinOnly)) {
                          return;
                        }
                        AppLoaderOverlay.show();
                        try {
                          final ok = await controller.moveKeyAuthenticated(
                            sourceSlot: sourceSlot,
                            targetSlot: targetSlot
                                .toRadixString(16)
                                .padLeft(2, '0')
                                .toUpperCase(),
                            pin: validator.getController('pin')!.text,
                            managementKey:
                                validator.getController('managementKey')!.text,
                            usePinOnly: usePinOnly,
                          );
                          if (!ok) {
                            Prompts.showPrompt(
                              S.current.pivMoveKeyFailed,
                              ContentThemeColor.danger,
                            );
                            return;
                          }
                          await controller.refreshData();
                          Get.back();
                          Prompts.showPrompt(
                            S.current.pivKeyMoved,
                            ContentThemeColor.success,
                          );
                        } finally {
                          AppLoaderOverlay.hide();
                        }
                      },
                      elevation: 0,
                      backgroundColor: contentTheme.primary,
                      child: CustomizedText.labelMedium(
                        S.of(context).pivMoveKey,
                        color: contentTheme.onPrimary,
                      ),
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

  void _showDeleteDialog(String slotNumber) {
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

    AppDialog.show(KeyboardSafeDialog(
      child: StatefulBuilder(
        builder: (context, setDialogState) => SizedBox(
          width: AppDialogWidth.medium,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.all(16),
                child: CustomizedText.labelLarge(
                    S.of(context).pivClearSlotTitle(slotNumber)),
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
                        S.of(context).pivClearSlotPrompt,
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
                            labelText: 'PIN', border: outlineInputBorder),
                      ),
                      if (controller.pinOnlyMode) ...[
                        Spacing.height(12),
                        _buildManagementKeyAuthModeControl(
                          usePinOnly: usePinOnly,
                          onChanged: (value) =>
                              setDialogState(() => usePinOnly = value),
                        ),
                      ],
                      if (!usePinOnly) ...[
                        Spacing.height(16),
                        _buildManagementKeyField(
                          validator,
                          'managementKey',
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
                        AppLoaderOverlay.show();
                        try {
                          final ok = await controller.clearSlotAuthenticated(
                            slot: slotNumber,
                            pin: validator.getController('pin')!.text,
                            managementKey:
                                validator.getController('managementKey')!.text,
                            usePinOnly: usePinOnly,
                          );
                          if (!ok) {
                            Prompts.showPrompt(S.current.pivClearSlotFailed,
                                ContentThemeColor.danger);
                            return;
                          }
                          await controller.refreshData();
                          Get.back();
                          Prompts.showPrompt(S.current.pivSlotCleared,
                              ContentThemeColor.success);
                        } finally {
                          AppLoaderOverlay.hide();
                        }
                      },
                      elevation: 0,
                      backgroundColor: contentTheme.danger,
                      child: CustomizedText.labelMedium(
                          S.of(context).pivClearSlot,
                          color: contentTheme.onDanger),
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
