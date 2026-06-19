import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:canokey_console/src/rust/api/crypto.dart';

import 'package:basic_utils/basic_utils.dart';
import 'package:canokey_console/controller/applets/piv/piv_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/utils/piv_signature.dart';
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
import 'package:canokey_console/views/applets/piv/widgets/piv_pin_management_card.dart';
import 'package:canokey_console/views/applets/piv/widgets/piv_slot_list_item.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:platform_detector/platform_detector.dart';
import 'package:pointycastle/asn1/primitives/asn1_bit_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_integer.dart';
import 'package:pointycastle/asn1/primitives/asn1_null.dart';
import 'package:pointycastle/asn1/primitives/asn1_object_identifier.dart';
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';

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

  Future<bool> _savePivFile({
    required String name,
    required String extension,
    required List<int> bytes,
    MimeType mimeType = MimeType.other,
  }) async {
    try {
      final path = await FileSaver.instance.saveAs(
        name: name,
        bytes: Uint8List.fromList(bytes),
        fileExtension: extension,
        mimeType: mimeType,
      );
      if (path == null || path.isEmpty) {
        return false;
      }
      if (path == 'Failed to save file') {
        Prompts.showPrompt(path, ContentThemeColor.danger);
        return false;
      }
      Prompts.showPrompt('Saved', ContentThemeColor.success);
      return true;
    } catch (e) {
      Prompts.showPrompt('Save failed: $e', ContentThemeColor.danger);
      return false;
    }
  }

  String _t({required String en, required String zh}) {
    return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  }

  String _sha256Fingerprint(List<int> bytes) {
    final digest = sha256.convert(bytes).bytes;
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
    return algorithm.name.toUpperCase();
  }

  String _slotUsageHint(String slotNumber, AlgorithmType algorithm) {
    final base = switch (slotNumber) {
      '9A' => _t(
          en: 'Authentication slot. Use a signing-capable key for login.',
          zh: '认证槽。用于登录时应选择可签名密钥。'),
      '9C' => _t(
          en: 'Digital signature slot. PIN policy defaults to always.',
          zh: '数字签名槽。PIN 策略默认总是验证。'),
      '9D' => _t(
          en: 'Key management slot. X25519 can derive shared secrets only.',
          zh: '密钥管理槽。X25519 只能用于派生共享密钥。'),
      '9E' => _t(
          en: 'Card authentication slot. PIN may be unnecessary for some uses.',
          zh: '卡认证槽。部分用途可能不需要 PIN。'),
      _ => _t(
          en: 'Retired key management slot for old encryption certificates.',
          zh: '过期密钥管理槽，用于旧加密证书。'),
    };
    if (algorithm == AlgorithmType.x25519) {
      return '$base ${_t(en: 'CSR and certificates are disabled for X25519.', zh: 'X25519 不支持 CSR 和证书。')}';
    }
    if (algorithm == AlgorithmType.ed25519 || algorithm == AlgorithmType.sm2) {
      return '$base ${_t(en: 'Check client compatibility before using this algorithm.', zh: '使用此算法前请确认客户端兼容性。')}';
    }
    return base;
  }

  AlgorithmType? _algorithmFromEcDomain(String? domainName) {
    return switch (domainName) {
      'prime256v1' => AlgorithmType.eccp256,
      'secp384r1' => AlgorithmType.eccp384,
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
    final algorithm = switch (cert.publicKeyAlgorithm) {
      '1.2.840.113549.1.1.1' => 'RSA',
      '1.2.840.10045.2.1' => 'EC',
      '1.3.101.112' => 'Ed25519',
      '1.3.101.110' => 'X25519',
      _ => cert.publicKeyAlgorithm,
    };
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
    return controller.slots[int.parse(slotNumber, radix: 16)]?.certBytes !=
        null;
  }

  bool _isCertificateOnlySlot(String slotNumber) {
    return slotNumber != '9A' &&
        slotNumber != '9C' &&
        slotNumber != '9D' &&
        slotNumber != '9E';
  }

  Future<bool> _confirmOverwriteKey({
    required String slotNumber,
    required String action,
  }) async {
    final slot = controller.slots[int.parse(slotNumber, radix: 16)];
    if (slot == null) {
      return true;
    }

    final c = Completer<bool>();
    Get.dialog(Dialog(
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(
                  _t(en: 'Overwrite Key', zh: '覆盖密钥')),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.bodyMedium(
                _t(
                    en: '$action will replace the private key in slot $slotNumber. Existing authentication or signing that depends on this key may stop working.',
                    zh: '$action 将替换 $slotNumber 槽中的私钥。依赖此密钥的认证或签名可能会失效。'),
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
                        _t(en: 'Overwrite', zh: '覆盖'),
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
      topActions: isWeb() || isIOSApp()
          ? IconButton(
              onPressed: _refreshSlots,
              icon:
                  Icon(LucideIcons.refreshCw, color: topBarTheme.onBackground),
            )
          : Container(),
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
                    PivPinManagementCard(
                      pinInfo: controller.pinInfo,
                      pukInfo: controller.pukInfo,
                      pinOnlyMode: controller.pinOnlyMode,
                      canUnblockPin: controller.pinInfo?.remainingCount == 0,
                      flexSpacing: flexSpacing,
                      contentTheme: contentTheme,
                      credentialRetryValue: _credentialRetryValue,
                      t: ({required en, required zh}) => _t(en: en, zh: zh),
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
                        title: _t(en: 'Unblock PIN', zh: '解锁 PIN'),
                        oldValueLabel: S.of(context).pivOldPUK,
                        newValueLabel: S.of(context).newPin,
                        prompt: _t(
                            en: 'Enter the current PUK and set a new PIN.',
                            zh: '输入当前 PUK 并设置新的 PIN。'),
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
      return _t(en: 'Retries: unknown', zh: '剩余次数：未知');
    }
    return _t(
        en: 'Retries: ${info.remainingCount}/${info.retriesCount}',
        zh: '剩余次数：${info.remainingCount}/${info.retriesCount}');
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
        ? _t(
            en: 'Use the PIN to unlock the management key stored on this card.',
            zh: '使用 PIN 解锁保存在卡内的管理密钥。')
        : _t(
            en: 'Enter the 24-byte management key for this operation.',
            zh: '为本次操作输入 24 字节管理密钥。');
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
                child: CustomizedText.labelLarge(
                    _t(en: 'Set PIN/PUK Retries', zh: '设置 PIN/PUK 重试次数')),
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
                        _t(
                            en: 'This resets PIN to 123456 and PUK to 12345678.',
                            zh: '此操作会将 PIN 重置为 123456，PUK 重置为 12345678。'),
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
                                  labelText:
                                      _t(en: 'PIN retries', zh: 'PIN 重试次数'),
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
                                  labelText:
                                      _t(en: 'PUK retries', zh: 'PUK 重试次数'),
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
                                _t(en: 'Set retries failed', zh: '设置重试次数失败'),
                                ContentThemeColor.danger);
                            return;
                          }
                          await controller.refreshData();
                          Prompts.showPrompt(
                              _t(
                                  en: 'PIN/PUK retries set. PIN and PUK were reset.',
                                  zh: 'PIN/PUK 重试次数已设置，PIN 和 PUK 已重置。'),
                              ContentThemeColor.success);
                          Get.back();
                        } finally {
                          Get.context!.loaderOverlay.hide();
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

    Get.dialog(Dialog(
      child: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(_t(
                  en: 'Use PIN-Protected Management Key', zh: '使用 PIN 保护管理密钥')),
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
                      _t(
                          en: 'A random management key will be set and stored on the card, protected by PIN.',
                          zh: '将设置随机管理密钥，并以 PIN 保护的形式保存在卡内。'),
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
                      Get.context!.loaderOverlay.show();
                      try {
                        final ok = await controller.enablePinOnlyMode(
                          validator.getController('pin')!.text,
                          validator.getController('managementKey')!.text,
                        );
                        if (!ok) {
                          Prompts.showPrompt(
                              _t(
                                  en: 'Failed to store a PIN-protected management key',
                                  zh: '保存 PIN 保护管理密钥失败'),
                              ContentThemeColor.danger);
                          return;
                        }
                        await controller.refreshData();
                        Prompts.showPrompt(
                            _t(
                                en: 'Management key is now PIN-protected',
                                zh: '管理密钥已由 PIN 保护'),
                            ContentThemeColor.success);
                        Get.back();
                      } finally {
                        Get.context!.loaderOverlay.hide();
                      }
                    },
                    elevation: 0,
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium(
                        _t(en: 'Enable', zh: '启用'),
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
                child: CustomizedText.labelLarge(
                    _t(en: 'Return to Manual Management Key', zh: '改为手动管理密钥')),
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
                        _t(
                            en: 'A new management key will be set before the PIN-protected copy is cleared.',
                            zh: '清除 PIN 保护的副本前会先设置新的管理密钥。'),
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
                            Prompts.showPrompt(
                                _t(
                                    en: 'Failed to return to manual management key',
                                    zh: '改为手动管理密钥失败'),
                                ContentThemeColor.danger);
                            return;
                          }
                          await controller.refreshData();
                          Prompts.showPrompt(
                              _t(
                                  en: 'Manual management key is now required',
                                  zh: '之后需要手动输入管理密钥'),
                              ContentThemeColor.success);
                          Get.back();
                        } finally {
                          Get.context!.loaderOverlay.hide();
                        }
                      },
                      elevation: 0,
                      backgroundColor: contentTheme.primary,
                      child: CustomizedText.labelMedium(
                          _t(en: 'Disable', zh: '禁用'),
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
                        if (controller.pinOnlyMode) ...[
                          Spacing.height(12),
                          CheckboxListTile(
                            value: storeOnDevice,
                            onChanged: (value) => setDialogState(
                                () => storeOnDevice = value ?? true),
                            contentPadding: EdgeInsets.zero,
                            title: Text(_t(
                                en: 'Store the new management key on this card',
                                zh: '将新管理密钥保存在卡内')),
                            subtitle: Text(_t(
                                en: 'When enabled, future management operations can authenticate with PIN.',
                                zh: '启用后，后续管理操作可用 PIN 完成认证。')),
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
    return PivSlotListItem(
      title: title,
      slotNumber: slotNumber,
      slot: slot,
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
    if (Localizations.localeOf(context).languageCode == 'zh') {
      return '过期证书 $index';
    }
    return 'Retired $index';
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

  void _showSlotDetailDialog(String title, String slotNumber, SlotInfo? slot) {
    final isX25519Slot = slot?.algorithm == AlgorithmType.x25519;
    final canGenerateX25519Key =
        slotNumber == '9D' && (slot == null || isX25519Slot);
    final canUseCertificateWorkflows = !isX25519Slot;
    final provisioningActions = <Widget>[
      if (canUseCertificateWorkflows) ...[
        _slotActionButton(
          text: 'Generate CSR',
          onPressed: () {
            Navigator.pop(Get.context!);
            _showGenerateDialog(slotNumber, selfSigned: false);
          },
        ),
        _slotActionButton(
          text: 'Self-sign',
          onPressed: () {
            Navigator.pop(Get.context!);
            _showGenerateDialog(slotNumber, selfSigned: true);
          },
        ),
      ],
      if (canGenerateX25519Key)
        _slotActionButton(
          text: 'Generate X25519 Key',
          onPressed: () {
            Navigator.pop(Get.context!);
            _showGenerateKeyDialog(slotNumber);
          },
        ),
      _slotActionButton(
        text: S.of(context).pivImport,
        onPressed: () {
          Navigator.pop(Get.context!);
          _showImportDialog(slotNumber);
        },
      ),
    ];
    final exportActions = <Widget>[
      if (slot != null)
        _slotActionButton(
          text: 'Export Public Key',
          onPressed: () {
            Navigator.pop(Get.context!);
            _showExportPublicKeyDialog(slot);
          },
        ),
      if (slot?.certBytes != null)
        _slotActionButton(
          text: S.of(context).pivExportCertificate,
          onPressed: () {
            Navigator.pop(Get.context!);
            _showExportDialog(slot!);
          },
        ),
    ];
    final diagnosticActions = <Widget>[
      if (slot?.algorithm == AlgorithmType.x25519)
        _slotActionButton(
          text: 'Derive Secret',
          onPressed: () {
            Navigator.pop(Get.context!);
            _showDeriveSecretDialog(slotNumber);
          },
        ),
      if (slot != null && slot.algorithm != AlgorithmType.x25519) ...[
        _slotActionButton(
          text: 'Sign / Verify',
          onPressed: () {
            Navigator.pop(Get.context!);
            _showSignVerifyDialog(slotNumber, slot);
          },
        ),
        _slotActionButton(
          text: _t(en: 'Sign File', zh: '签名文件'),
          onPressed: () {
            Navigator.pop(Get.context!);
            _showFileSignDialog(slotNumber, slot);
          },
        ),
        _slotActionButton(
          text: _t(en: 'Verify File', zh: '验证文件'),
          onPressed: () {
            Navigator.pop(Get.context!);
            _showFileVerifyDialog(slot);
          },
        ),
      ],
    ];
    final dangerActions = <Widget>[
      if (slot != null)
        _slotActionButton(
          text: _t(en: 'Clear Slot', zh: '清空槽'),
          danger: true,
          onPressed: () {
            Navigator.pop(Get.context!);
            _showDeleteDialog(slotNumber);
          },
        ),
    ];

    Get.dialog(Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
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
                Flexible(
                  child: SingleChildScrollView(
                      padding: Spacing.all(16),
                      child: Form(
                        child: Column(
                          children: [
                            CustomizedText.bodySmall(
                              _slotUsageHint(slotNumber, slot.algorithm),
                              color: contentTheme.onBackground.withAlpha(180),
                            ),
                            Spacing.height(16),
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
                              initialValue: _certificateKeySummary(slot.cert!),
                              readOnly: true,
                              decoration: InputDecoration(
                                  labelText: _t(en: 'Public Key', zh: '公钥'),
                                  border: outlineInputBorder,
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.auto),
                            ),
                            Spacing.height(16),
                            TextFormField(
                              initialValue: slot.cert!.signatureAlgorithm,
                              readOnly: true,
                              decoration: InputDecoration(
                                  labelText:
                                      _t(en: 'Signature Algorithm', zh: '签名算法'),
                                  border: outlineInputBorder,
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.auto),
                            ),
                            Spacing.height(16),
                            TextFormField(
                              initialValue: _sha256Fingerprint(slot.certBytes!),
                              readOnly: true,
                              decoration: InputDecoration(
                                  labelText: _t(
                                      en: 'SHA-256 Fingerprint',
                                      zh: 'SHA-256 指纹'),
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
                            TextFormField(
                              initialValue:
                                  _formatBytes(slot.certBytes!.length),
                              readOnly: true,
                              decoration: InputDecoration(
                                  labelText:
                                      _t(en: 'Certificate Size', zh: '证书大小'),
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
              Padding(
                padding: Spacing.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _slotActionSection(
                        _t(en: 'Provisioning', zh: '配置'), provisioningActions),
                    if (exportActions.isNotEmpty) ...[
                      Spacing.height(16),
                      _slotActionSection(
                          _t(en: 'Export', zh: '导出'), exportActions),
                    ],
                    if (diagnosticActions.isNotEmpty) ...[
                      Spacing.height(16),
                      _slotActionSection(
                          _t(en: 'Diagnostics', zh: '诊断'), diagnosticActions),
                    ],
                    if (dangerActions.isNotEmpty) ...[
                      Spacing.height(16),
                      _slotActionSection(
                          _t(en: 'Danger Zone', zh: '危险操作'), dangerActions),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
                                final saved = await _savePivFile(
                                  name: 'certificate',
                                  extension: 'der',
                                  bytes: slot.certBytes!,
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
                                        base64.encode(slot.certBytes!), 64)
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
      Prompts.showPrompt('No public key available', ContentThemeColor.danger);
      return;
    }
    Get.dialog(Dialog(
        child: SizedBox(
            width: 360,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                      padding: Spacing.all(16),
                      child: CustomizedText.labelLarge('Export Public Key')),
                  Divider(height: 0, thickness: 1),
                  Padding(
                      padding: Spacing.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomizedText.bodySmall(
                              'Algorithm: ${slot.algorithm.name.toUpperCase()}'),
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

  void _showSignVerifyDialog(String slotNumber, SlotInfo slot) {
    FormValidator validator = FormValidator();
    validator.addField('pin',
        required: true,
        controller: TextEditingController(),
        validators: [LengthValidator(min: 6, max: 8)]);
    validator.addField('message',
        required: true,
        controller: TextEditingController(text: 'hello canokey'));
    final signature = ''.obs;
    final verifyResult = ''.obs;

    Get.dialog(Dialog(
      child: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge('Sign / Verify Test'),
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
                    Spacing.height(16),
                    TextFormField(
                      controller: validator.getController('message'),
                      validator: validator.getValidator('message'),
                      maxLines: 3,
                      decoration: InputDecoration(
                          labelText: 'Message', border: outlineInputBorder),
                    ),
                    Obx(() => signature.value.isEmpty
                        ? SizedBox.shrink()
                        : Column(
                            children: [
                              Spacing.height(16),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: CustomizedText.bodyMedium(
                                  'Signature (hex)',
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
                              Spacing.height(16),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: CustomizedText.bodyMedium(
                                  'Verify Result',
                                  fontWeight: 600,
                                ),
                              ),
                              Spacing.height(8),
                              Container(
                                width: double.infinity,
                                padding: Spacing.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: contentTheme.cardBorder),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: SelectableText(verifyResult.value),
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
                      Get.context!.loaderOverlay.show();
                      try {
                        final result = await controller.signAndVerify(
                          slotNumber,
                          slot,
                          validator.getController('pin')!.text,
                          Uint8List.fromList(utf8.encode(
                              validator.getController('message')!.text)),
                        );
                        if (result == null) {
                          Prompts.showPrompt(
                              'Sign / verify failed', ContentThemeColor.danger);
                          return;
                        }
                        signature.value = hex.encode(result.signature);
                        verifyResult.value = result.verified
                            ? 'Verified'
                            : 'Verification failed';
                      } finally {
                        Get.context!.loaderOverlay.hide();
                      }
                    },
                    elevation: 0,
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium('Sign and Verify',
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

  void _showFileSignDialog(String slotNumber, SlotInfo slot) {
    FormValidator validator = FormValidator();
    validator.addField('pin',
        required: true,
        controller: TextEditingController(),
        validators: [LengthValidator(min: 6, max: 8)]);
    final selectedFileName = ''.obs;
    Uint8List? selectedBytes;

    Get.dialog(Dialog(
      child: Obx(
        () => SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.all(16),
                child:
                    CustomizedText.labelLarge(_t(en: 'Sign File', zh: '签名文件')),
              ),
              Divider(height: 0, thickness: 1),
              Padding(
                padding: Spacing.all(16),
                child: Form(
                  key: validator.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomizedText.bodySmall(_t(
                          en: 'Creates a detached raw signature for the selected file.',
                          zh: '为所选文件生成分离式原始签名。')),
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
                                  ? _t(en: 'No file selected', zh: '未选择文件')
                                  : selectedFileName.value,
                            ),
                          ),
                          Spacing.width(12),
                          CustomizedButton.rounded(
                            onPressed: () async {
                              final result = await FilePicker.pickFiles();
                              final file = result?.files.firstOrNull;
                              if (file == null) return;
                              selectedFileName.value = file.name;
                              selectedBytes = await file.xFile.readAsBytes();
                            },
                            elevation: 0,
                            backgroundColor: contentTheme.primary,
                            child: CustomizedText.labelMedium(
                                _t(en: 'Select', zh: '选择'),
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
                          Prompts.showPrompt(
                              _t(en: 'Select a file first.', zh: '请先选择文件。'),
                              ContentThemeColor.danger);
                          return;
                        }
                        Get.context!.loaderOverlay.show();
                        try {
                          final signature = await controller.signData(
                            slotNumber,
                            slot,
                            validator.getController('pin')!.text,
                            data,
                          );
                          if (signature == null) {
                            Prompts.showPrompt(
                                _t(en: 'File signing failed', zh: '文件签名失败'),
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
                          Get.context!.loaderOverlay.hide();
                        }
                      },
                      elevation: 0,
                      backgroundColor: contentTheme.primary,
                      child: CustomizedText.labelMedium(
                          _t(en: 'Sign', zh: '签名'),
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

    Get.dialog(Dialog(
      child: Obx(
        () => SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.all(16),
                child: CustomizedText.labelLarge(
                    _t(en: 'Verify File Signature', zh: '验证文件签名')),
              ),
              Divider(height: 0, thickness: 1),
              Padding(
                padding: Spacing.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomizedText.bodySmall(_t(
                        en: 'Verifies a detached raw signature against this slot public key.',
                        zh: '使用当前槽位公钥验证分离式原始签名。')),
                    Spacing.height(16),
                    _buildFilePickerRow(
                      label: _t(en: 'File', zh: '文件'),
                      value: selectedFileName.value,
                      onPick: () async {
                        final result = await FilePicker.pickFiles();
                        final file = result?.files.firstOrNull;
                        if (file == null) return;
                        selectedFileName.value = file.name;
                        selectedBytes = await file.xFile.readAsBytes();
                        verifyResult.value = '';
                      },
                    ),
                    Spacing.height(12),
                    _buildFilePickerRow(
                      label: _t(en: 'Signature', zh: '签名'),
                      value: selectedSignatureName.value,
                      onPick: () async {
                        final result = await FilePicker.pickFiles();
                        final file = result?.files.firstOrNull;
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
                        color: verifyResult.value ==
                                _t(en: 'Signature verified', zh: '签名验证通过')
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
                              _t(
                                  en: 'Select a file and signature first.',
                                  zh: '请先选择文件和签名。'),
                              ContentThemeColor.danger);
                          return;
                        }
                        final ok = await controller.verifySignature(
                          slot,
                          data,
                          signature,
                        );
                        verifyResult.value = ok
                            ? _t(en: 'Signature verified', zh: '签名验证通过')
                            : _t(
                                en: 'Signature verification failed',
                                zh: '签名验证失败');
                      },
                      elevation: 0,
                      backgroundColor: contentTheme.primary,
                      child: CustomizedText.labelMedium(
                          _t(en: 'Verify', zh: '验证'),
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
                value.isEmpty ? _t(en: 'Not selected', zh: '未选择') : value,
              ),
            ],
          ),
        ),
        Spacing.width(12),
        CustomizedButton.rounded(
          onPressed: onPick,
          elevation: 0,
          backgroundColor: contentTheme.primary,
          child: CustomizedText.labelMedium(_t(en: 'Select', zh: '选择'),
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
    PinPolicy pinPolicy =
        slotNumber == '9C' ? PinPolicy.always : PinPolicy.once;
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

      if (_isCertificateOnlySlot(slotNumber) && hasKey.value) {
        importErrors.add(S.of(context).pivRetiredSlotsCertificateOnly);
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
          Prompts.showPrompt(
              _t(
                  en: 'Select a certificate or private key first.',
                  zh: '请先选择证书或私钥。'),
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
              action: _t(en: 'Importing a private key', zh: '导入私钥'))) {
        return;
      }

      Get.context!.loaderOverlay.show();
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
              _t(en: 'Import failed', zh: '导入失败'), ContentThemeColor.danger);
          return;
        }

        await controller.refreshData();
        Prompts.showPrompt(
            _t(en: 'Import succeeded', zh: '导入成功'), ContentThemeColor.success);
        Navigator.pop(Get.context!);
      } finally {
        Get.context!.loaderOverlay.hide();
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
        parseMessage.value = _t(
            en: 'Unsupported file. Use PEM or DER certificate/private key files.',
            zh: '不支持的文件。请使用 PEM 或 DER 格式的证书/私钥文件。');
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

    Get.dialog(Dialog(
      child: Obx(
        () => SizedBox(
          width: 460,
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
                            ? _t(en: 'Import', zh: '导入')
                            : _t(en: 'Next', zh: '下一步'),
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
                            : _t(en: 'Back', zh: '上一步'),
                        color: ContentThemeColor.secondary.onColor),
                  ),
                ],
              );
            },
            steps: [
              Step(
                title: Text(_t(
                    en: 'Verify PIN and Management Key', zh: '验证 PIN 和管理密钥')),
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
                title: Text(_t(en: 'Select File', zh: '选择文件')),
                content: InkWell(
                  onTap: () async {
                    final result = await FilePicker.pickFiles();
                    final file = result?.files.firstOrNull;
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
                                _t(
                                    en: 'Click to select a PEM or DER certificate/key',
                                    zh: '点击选择 PEM 或 DER 证书/私钥'),
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
                                      ? _t(
                                          en: '(Make sure the file contains a plaintext key or a certificate)',
                                          zh: '（请确认文件包含明文私钥或证书）')
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
                title: Text(_t(en: 'PIN and Touch Policy', zh: 'PIN 和触摸策略')),
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
                  title: Text(_t(en: 'Review', zh: '确认')),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomizedText.bodyMedium(
                          '${_t(en: 'Private Key', zh: '私钥')}: ${hasKey.value ? keySummary() : S.of(context).pivEmpty}'),
                      Spacing.height(8),
                      if (cert != null)
                        CustomizedText.bodyMedium(
                            '${S.of(context).pivCertificate}: ${cert!.subject != "" ? cert!.subject : S.of(context).pivEmpty}'),
                      if (cert != null) ...[
                        Spacing.height(8),
                        CustomizedText.bodyMedium(
                            '${_t(en: 'Certificate Key', zh: '证书公钥')}: ${_certificateKeySummary(cert!)}'),
                      ],
                      if (certBytes != null && hasKey.value) ...[
                        Spacing.height(8),
                        CustomizedText.bodyMedium(
                          certificateMatchesSelectedKey()
                              ? _t(
                                  en: 'Certificate matches the private key',
                                  zh: '证书与私钥匹配')
                              : _t(
                                  en: 'Certificate does not match the private key',
                                  zh: '证书与私钥不匹配'),
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
      if (!await _confirmOverwriteKey(
          slotNumber: slotNumber,
          action: selfSigned
              ? _t(en: 'Creating a self-signed certificate', zh: '创建自签证书')
              : _t(en: 'Generating a CSR', zh: '生成 CSR'))) {
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
                    state:
                        step.value == 1 ? StepState.editing : StepState.indexed,
                    title: Text('Key Options'),
                    content: Padding(
                      padding: Spacing.top(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomizedText.bodySmall(
                            selfSigned
                                ? _t(
                                    en:
                                        'Self-signed certificates are for local testing and compatibility depends on the client.',
                                    zh: '自签证书适合本地测试，兼容性取决于客户端。')
                                : _t(
                                    en: 'CSR generation signs the request with the new key on the card.',
                                    zh: '生成 CSR 会使用卡内新密钥对请求签名。'),
                            color: contentTheme.onBackground.withAlpha(180),
                          ),
                          Spacing.height(12),
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
    final algorithm = AlgorithmType.x25519;
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
                child: CustomizedText.labelLarge('Generate X25519 Key'),
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
                        if (!await _confirmOverwriteKey(
                            slotNumber: slotNumber,
                            action: _t(
                                en: 'Generating an X25519 key',
                                zh: '生成 X25519 密钥'))) {
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
                            Prompts.showPrompt('Generate X25519 Key Failed',
                                ContentThemeColor.danger);
                            return;
                          }
                          await controller.refreshData();
                          Prompts.showPrompt('X25519 Key Generated',
                              ContentThemeColor.success);
                          Navigator.pop(Get.context!);
                        } finally {
                          Get.context!.loaderOverlay.hide();
                        }
                      },
                      elevation: 0,
                      backgroundColor: contentTheme.primary,
                      child: CustomizedText.labelMedium('Generate X25519',
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
                      await _savePivFile(
                        name: 'piv-$slotNumber',
                        extension: 'csr',
                        bytes: utf8.encode(csr),
                        mimeType: MimeType.text,
                      );
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
                      await _savePivFile(
                        name: 'piv-$slotNumber',
                        extension: 'pem',
                        bytes: utf8.encode(pem),
                        mimeType: MimeType.text,
                      );
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
                child: CustomizedText.labelLarge(
                    _t(en: 'Clear Slot $slotNumber', zh: '清空槽 $slotNumber')),
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
                        _t(
                            en: 'This removes both the private key and certificate from this slot. Make sure you have another way to authenticate.',
                            zh: '此操作会删除此槽中的私钥和证书。请确认您仍有其他认证方式。'),
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
                        Get.context!.loaderOverlay.show();
                        try {
                          final ok = await controller.clearSlotAuthenticated(
                            slot: slotNumber,
                            pin: validator.getController('pin')!.text,
                            managementKey:
                                validator.getController('managementKey')!.text,
                            usePinOnly: usePinOnly,
                          );
                          if (!ok) {
                            Prompts.showPrompt(
                                _t(
                                    en: 'Clear slot failed. Make sure the firmware supports key deletion.',
                                    zh: '清空槽失败。请确认固件支持删除私钥。'),
                                ContentThemeColor.danger);
                            return;
                          }
                          await controller.refreshData();
                          Get.back();
                          Prompts.showPrompt(_t(en: 'Slot cleared', zh: '槽已清空'),
                              ContentThemeColor.success);
                        } finally {
                          Get.context!.loaderOverlay.hide();
                        }
                      },
                      elevation: 0,
                      backgroundColor: contentTheme.danger,
                      child: CustomizedText.labelMedium(
                          _t(en: 'Clear Slot', zh: '清空槽'),
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
