import 'dart:convert';
import 'dart:typed_data';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/base_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/ndef.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ndef/ndef.dart';

class NdefRecordDialog extends BaseDialog {
  final NDEFRecord? record;
  final String defaultLanguage;

  const NdefRecordDialog({
    super.key,
    this.record,
    required this.defaultLanguage,
  });

  static Future<NDEFRecord?> show({
    NDEFRecord? record,
    required String defaultLanguage,
  }) {
    return Get.dialog<NDEFRecord>(
      NdefRecordDialog(record: record, defaultLanguage: defaultLanguage),
      barrierDismissible: false,
    );
  }

  @override
  State<NdefRecordDialog> createState() => _NdefRecordDialogState();
}

class _NdefRecordDialogState extends BaseDialogState<NdefRecordDialog>
    with UIMixin {
  static const _typeOptions = [
    NdefEditableRecordType.uri,
    NdefEditableRecordType.text,
    NdefEditableRecordType.phone,
    NdefEditableRecordType.contact,
    NdefEditableRecordType.wifi,
    NdefEditableRecordType.androidApplication,
    NdefEditableRecordType.custom,
  ];

  final _formKey = GlobalKey<FormState>();

  late NdefEditableRecordType _type;
  late TextEncoding _textEncoding;
  late NdefPayloadEncoding _payloadEncoding;
  late TypeNameFormat _tnf;
  late WifiAuthenticationType _wifiAuthentication;
  late WifiEncryptionType _wifiEncryption;

  late final TextEditingController _valueController;
  late final TextEditingController _secondaryController;
  late final TextEditingController _languageController;
  late final TextEditingController _typeController;
  late final TextEditingController _payloadController;
  late final TextEditingController _idController;
  late final TextEditingController _macController;
  late final TextEditingController _emailController;
  late final TextEditingController _organizationController;

  String? _recordError;

  bool get _editing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _type = record?.editableType ?? NdefEditableRecordType.uri;
    _textEncoding = record is TextRecord ? record.encoding : TextEncoding.UTF8;
    _payloadEncoding =
        record == null ? NdefPayloadEncoding.text : NdefPayloadEncoding.hex;
    _tnf = record?.tnf ?? TypeNameFormat.media;
    _wifiAuthentication = record is WifiRecord
        ? record.authenticationType
        : WifiAuthenticationType.wpa2Personal;
    _wifiEncryption =
        record is WifiRecord ? record.encryptionType : WifiEncryptionType.aes;

    _valueController = TextEditingController(text: _initialValue(record));
    _secondaryController =
        TextEditingController(text: _initialSecondaryValue(record));
    _languageController = TextEditingController(
      text: record is TextRecord
          ? record.language ?? widget.defaultLanguage
          : widget.defaultLanguage,
    );
    _typeController = TextEditingController(
      text: _type == NdefEditableRecordType.custom
          ? record?.safeDecodedType ?? ''
          : '',
    );
    _payloadController = TextEditingController(
      text: _initialPayloadValue(record),
    );
    _idController = TextEditingController(text: _hex(record?.id));
    _macController = TextEditingController(
      text: record is WifiRecord ? record.macAddress ?? '' : '',
    );
    _emailController = TextEditingController(
      text: record?.vCardField('EMAIL') ?? '',
    );
    _organizationController = TextEditingController(
      text: record?.vCardField('ORG') ?? '',
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    _secondaryController.dispose();
    _languageController.dispose();
    _typeController.dispose();
    _payloadController.dispose();
    _idController.dispose();
    _macController.dispose();
    _emailController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  @override
  Widget buildDialogContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: Spacing.all(16),
          child: CustomizedText.labelLarge(
            _editing
                ? S.of(context).ndefEditRecord
                : S.of(context).ndefAddRecord,
          ),
        ),
        const Divider(height: 0, thickness: 1),
        Flexible(
          child: SingleChildScrollView(
            padding: Spacing.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _selectionField<NdefEditableRecordType>(
                    value: _type,
                    label: S.of(context).ndefRecordType,
                    values: _typeOptions,
                    itemLabel: _recordTypeLabel,
                    onChanged: _changeType,
                  ),
                  Spacing.height(20),
                  ..._buildTypeFields(),
                  if (!(_type == NdefEditableRecordType.custom &&
                      _tnf == TypeNameFormat.empty)) ...[
                    Spacing.height(16),
                    _textField(
                      _idController,
                      S.of(context).ndefRecordId,
                      hintText: S.of(context).ndefOptionalHex,
                      validator: _validateOptionalHex,
                    ),
                  ],
                  if (_recordError != null) ...[
                    Spacing.height(12),
                    CustomizedText.bodySmall(
                      _recordError!,
                      color: contentTheme.danger,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 0, thickness: 1),
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
              Spacing.width(12),
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
    );
  }

  List<Widget> _buildTypeFields() {
    return switch (_type) {
      NdefEditableRecordType.uri => [
          _textField(
            _valueController,
            S.of(context).ndefUriValue,
            keyboardType: TextInputType.url,
            validator: _validateUri,
          ),
        ],
      NdefEditableRecordType.text => [
          _textField(
            _valueController,
            S.of(context).ndefTextValue,
            minLines: 3,
            maxLines: 6,
            validator: _validateRequired,
          ),
          Spacing.height(16),
          _textField(
            _languageController,
            S.of(context).ndefLanguage,
            hintText: 'en',
            validator: _validateLanguage,
          ),
          Spacing.height(16),
          _textEncodingField(),
        ],
      NdefEditableRecordType.phone => [
          _textField(
            _valueController,
            S.of(context).ndefPhoneNumber,
            hintText: '+86 138 0000 0000',
            keyboardType: TextInputType.phone,
            validator: (value) => _validatePhone(value, required: true),
          ),
        ],
      NdefEditableRecordType.contact => [
          _textField(
            _valueController,
            S.of(context).ndefContactName,
            validator: _validateRequired,
          ),
          Spacing.height(16),
          _textField(
            _secondaryController,
            S.of(context).ndefPhoneNumber,
            keyboardType: TextInputType.phone,
            validator: (value) => _validatePhone(value, required: false),
          ),
          Spacing.height(16),
          _textField(
            _emailController,
            S.of(context).ndefContactEmail,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          Spacing.height(16),
          _textField(
            _organizationController,
            S.of(context).ndefContactOrganization,
          ),
        ],
      NdefEditableRecordType.wifi => [
          _textField(
            _valueController,
            'SSID',
            validator: _validateRequired,
          ),
          Spacing.height(16),
          _textField(
            _secondaryController,
            S.of(context).ndefWifiPassword,
            validator: _wifiAuthentication == WifiAuthenticationType.open
                ? null
                : _validateRequired,
          ),
          Spacing.height(16),
          _selectionField<WifiAuthenticationType>(
            value: _wifiAuthentication,
            label: S.of(context).ndefWifiAuthentication,
            values: WifiAuthenticationType.values,
            itemLabel: _wifiAuthenticationLabel,
            onChanged: (value) => setState(() {
              _wifiAuthentication = value;
              if (value == WifiAuthenticationType.open) {
                _wifiEncryption = WifiEncryptionType.none;
              }
            }),
          ),
          Spacing.height(16),
          _selectionField<WifiEncryptionType>(
            value: _wifiEncryption,
            label: S.of(context).ndefWifiEncryption,
            values: WifiEncryptionType.values,
            itemLabel: _wifiEncryptionLabel,
            onChanged: (value) => setState(() => _wifiEncryption = value),
          ),
          Spacing.height(16),
          _textField(
            _macController,
            S.of(context).ndefMacAddress,
            hintText: 'AA:BB:CC:DD:EE:FF',
            validator: (value) => _validateMac(value, required: false),
          ),
        ],
      NdefEditableRecordType.androidApplication => [
          _textField(
            _valueController,
            S.of(context).ndefAndroidPackage,
            hintText: 'com.example.app',
            validator: _validatePackageName,
          ),
        ],
      NdefEditableRecordType.custom => [
          _selectionField<TypeNameFormat>(
            value: _tnf,
            label: 'TNF',
            values: const [
              TypeNameFormat.empty,
              TypeNameFormat.nfcWellKnown,
              TypeNameFormat.media,
              TypeNameFormat.absoluteURI,
              TypeNameFormat.nfcExternal,
              TypeNameFormat.unknown,
            ],
            itemLabel: _tnfLabel,
            onChanged: (value) => setState(() => _tnf = value),
          ),
          Spacing.height(16),
          _textField(
            _typeController,
            S.of(context).ndefTypeName,
            validator: _validateCustomType,
          ),
          if (_tnf != TypeNameFormat.empty &&
              _tnf != TypeNameFormat.absoluteURI) ...[
            Spacing.height(16),
            _payloadEncodingField(),
            Spacing.height(16),
            _payloadField(),
          ],
        ],
    };
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? hintText,
    int minLines = 1,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: outlineInputBorder,
      ),
      validator: validator,
    );
  }

  Widget _textEncodingField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomizedText.labelMedium(S.of(context).ndefEncoding),
        Spacing.height(8),
        SegmentedButton<TextEncoding>(
          segments: const [
            ButtonSegment(value: TextEncoding.UTF8, label: Text('UTF-8')),
            ButtonSegment(value: TextEncoding.UTF16, label: Text('UTF-16')),
          ],
          selected: {_textEncoding},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              setState(() => _textEncoding = selection.single),
        ),
      ],
    );
  }

  Widget _payloadEncodingField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomizedText.labelMedium(S.of(context).ndefPayloadEncoding),
        Spacing.height(8),
        SegmentedButton<NdefPayloadEncoding>(
          segments: [
            ButtonSegment(
              value: NdefPayloadEncoding.text,
              label: Text(S.of(context).ndefPayloadText),
            ),
            ButtonSegment(
              value: NdefPayloadEncoding.hex,
              label: Text(S.of(context).ndefPayloadHex),
            ),
          ],
          selected: {_payloadEncoding},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => setState(() {
            _convertPayload(selection.single);
            _payloadEncoding = selection.single;
          }),
        ),
      ],
    );
  }

  Widget _payloadField() {
    return _textField(
      _payloadController,
      _payloadEncoding == NdefPayloadEncoding.hex
          ? '${S.of(context).ndefPayload} (${S.of(context).ndefPayloadHex})'
          : S.of(context).ndefPayload,
      minLines: 3,
      maxLines: 7,
      validator: _payloadEncoding == NdefPayloadEncoding.hex
          ? _validateOptionalHex
          : null,
    );
  }

  Widget _selectionField<T>({
    required T value,
    required String label,
    required List<T> values,
    required String Function(T) itemLabel,
    required ValueChanged<T> onChanged,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => PopupMenuButton<T>(
        key: ValueKey('$label:$value'),
        position: PopupMenuPosition.under,
        offset: const Offset(0, 4),
        padding: EdgeInsets.zero,
        color: contentTheme.background,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.16),
          ),
        ),
        constraints: BoxConstraints(
          minWidth: constraints.maxWidth,
          maxWidth: constraints.maxWidth,
          maxHeight: 320,
        ),
        onSelected: onChanged,
        itemBuilder: (context) => values
            .map(
              (item) => PopupMenuItem<T>(
                value: item,
                height: 44,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        itemLabel(item),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item == value) ...[
                      Spacing.width(12),
                      Icon(
                        Icons.check,
                        size: 18,
                        color: contentTheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
            )
            .toList(),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: outlineInputBorder,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  itemLabel(value),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Spacing.width(12),
              const Icon(Icons.arrow_drop_down, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _changeType(NdefEditableRecordType type) {
    setState(() {
      _type = type;
      _recordError = null;
      _valueController.clear();
      _secondaryController.clear();
      _typeController.clear();
      _payloadController.clear();
      _idController.clear();
      _macController.clear();
      _emailController.clear();
      _organizationController.clear();
      _payloadEncoding = NdefPayloadEncoding.text;
      _tnf = TypeNameFormat.media;
    });
  }

  void _convertPayload(NdefPayloadEncoding next) {
    if (next == _payloadEncoding || _payloadController.text.isEmpty) return;
    try {
      if (next == NdefPayloadEncoding.hex) {
        _payloadController.text =
            _hex(Uint8List.fromList(utf8.encode(_payloadController.text)));
      } else {
        _payloadController.text = utf8.decode(
          _parseHex(_payloadController.text),
        );
      }
      _recordError = null;
    } catch (_) {
      _recordError = S.of(context).ndefPayloadConversionFailed;
    }
  }

  String? _validateRequired(String? value) {
    return (value?.trim().isEmpty ?? true)
        ? S.of(context).ndefRequiredField
        : null;
  }

  String? _validateUri(String? value) {
    final required = _validateRequired(value);
    if (required != null) return required;
    final uri = Uri.tryParse(value!.trim());
    return uri == null || !uri.hasScheme ? S.of(context).ndefInvalidUri : null;
  }

  String? _validateLanguage(String? value) {
    final language = value?.trim() ?? '';
    if (!RegExp(r'^[A-Za-z]{2,8}(-[A-Za-z0-9]{1,8})*$').hasMatch(language)) {
      return S.of(context).ndefInvalidLanguage;
    }
    return null;
  }

  String? _validatePhone(String? value, {required bool required}) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty && !required) return null;
    if (!RegExp(r'^\+?[0-9() .\-*#]{3,}$').hasMatch(phone)) {
      return S.of(context).ndefInvalidPhoneNumber;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return S.of(context).ndefInvalidEmail;
    }
    return null;
  }

  String? _validateMac(String? value, {required bool required}) {
    final mac = value?.trim() ?? '';
    if (mac.isEmpty && !required) return null;
    if (!RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$').hasMatch(mac)) {
      return S.of(context).ndefInvalidMacAddress;
    }
    return null;
  }

  String? _validatePackageName(String? value) {
    final packageName = value?.trim() ?? '';
    if (!RegExp(r'^[A-Za-z][A-Za-z0-9_]*(?:\.[A-Za-z][A-Za-z0-9_]*)+$')
        .hasMatch(packageName)) {
      return S.of(context).ndefInvalidPackageName;
    }
    return null;
  }

  String? _validateOptionalHex(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      _parseHex(value);
      return null;
    } on FormatException {
      return S.of(context).validationHexString;
    }
  }

  String? _validateCustomType(String? value) {
    final type = value?.trim() ?? '';
    if (_tnf == TypeNameFormat.empty || _tnf == TypeNameFormat.unknown) {
      return type.isEmpty ? null : S.of(context).ndefTnfRequiresEmptyType;
    }
    if (type.isEmpty) return S.of(context).ndefRequiredField;
    if (_tnf == TypeNameFormat.absoluteURI) return _validateUri(value);
    if (_tnf == TypeNameFormat.media && !type.contains('/')) {
      return S.of(context).ndefInvalidMimeType;
    }
    if (_tnf == TypeNameFormat.nfcExternal && !type.contains(':')) {
      return S.of(context).ndefInvalidExternalType;
    }
    return null;
  }

  void _submit() {
    setState(() => _recordError = null);
    if (_formKey.currentState?.validate() != true) return;
    try {
      final record = _buildRecord();
      final decoded = NdefDocument.decode(
        NdefDocument([record]).encode(),
      ).records.single;
      Navigator.pop(context, decoded);
    } catch (error) {
      setState(() {
        _recordError = S.of(context).ndefInvalidRecord(error.toString());
      });
    }
  }

  NDEFRecord _buildRecord() {
    final id = _optionalHex(_idController.text);
    final value = _valueController.text.trim();
    late final NDEFRecord record;

    switch (_type) {
      case NdefEditableRecordType.uri:
        record = NdefDocument.uriRecord(value);
      case NdefEditableRecordType.text:
        record = NdefDocument.textRecord(
          _valueController.text,
          language: _languageController.text.trim(),
          encoding: _textEncoding,
        );
      case NdefEditableRecordType.phone:
        record = NdefDocument.phoneRecord(value);
      case NdefEditableRecordType.contact:
        record = NdefDocument.contactRecord(
          name: value,
          phone: _secondaryController.text,
          email: _emailController.text,
          organization: _organizationController.text,
        );
      case NdefEditableRecordType.wifi:
        record = WifiRecord(
          ssid: value,
          networkKey: _secondaryController.text,
          authenticationType: _wifiAuthentication,
          encryptionType: _wifiEncryption,
          macAddress: _nullIfEmpty(_macController.text)?.toUpperCase(),
        );
      case NdefEditableRecordType.androidApplication:
        record = AARRecord(packageName: value);
      case NdefEditableRecordType.custom:
        final payload =
            _tnf == TypeNameFormat.empty || _tnf == TypeNameFormat.absoluteURI
                ? Uint8List(0)
                : _payloadBytes();
        record = NdefDocument.rawRecord(
          tnf: _tnf,
          type: _typeController.text.trim(),
          payload: payload,
          id: _tnf == TypeNameFormat.empty ? null : id,
        );
    }

    if (_type != NdefEditableRecordType.custom && id != null) {
      record.id = id;
    }
    return record;
  }

  Uint8List _payloadBytes() {
    if (_payloadEncoding == NdefPayloadEncoding.hex) {
      return _parseHex(_payloadController.text);
    }
    return Uint8List.fromList(utf8.encode(_payloadController.text));
  }

  Uint8List? _optionalHex(String value) {
    return value.trim().isEmpty ? null : _parseHex(value);
  }

  Uint8List _parseHex(String value) {
    final normalized = value.replaceAll(RegExp(r'[\s:]'), '');
    if (normalized.isEmpty) return Uint8List(0);
    if (normalized.length.isOdd ||
        !RegExp(r'^[0-9A-Fa-f]+$').hasMatch(normalized)) {
      throw const FormatException('Invalid hexadecimal value');
    }
    return Uint8List.fromList([
      for (var i = 0; i < normalized.length; i += 2)
        int.parse(normalized.substring(i, i + 2), radix: 16),
    ]);
  }

  String _recordTypeLabel(NdefEditableRecordType type) {
    return switch (type) {
      NdefEditableRecordType.uri => S.of(context).ndefUri,
      NdefEditableRecordType.text => S.of(context).ndefText,
      NdefEditableRecordType.phone => S.of(context).ndefPhone,
      NdefEditableRecordType.contact => S.of(context).ndefContact,
      NdefEditableRecordType.wifi => S.of(context).ndefWifi,
      NdefEditableRecordType.androidApplication =>
        S.of(context).ndefAndroidApplication,
      NdefEditableRecordType.custom => S.of(context).ndefOther,
    };
  }

  String _tnfLabel(TypeNameFormat tnf) {
    return switch (tnf) {
      TypeNameFormat.empty => S.of(context).ndefTnfEmpty,
      TypeNameFormat.nfcWellKnown => S.of(context).ndefTnfWellKnown,
      TypeNameFormat.media => S.of(context).ndefTnfMedia,
      TypeNameFormat.absoluteURI => S.of(context).ndefTnfAbsoluteUri,
      TypeNameFormat.nfcExternal => S.of(context).ndefTnfExternal,
      TypeNameFormat.unknown => S.of(context).ndefTnfUnknown,
      TypeNameFormat.unchanged => tnf.name,
    };
  }

  String _wifiAuthenticationLabel(WifiAuthenticationType value) {
    return switch (value) {
      WifiAuthenticationType.open => 'Open',
      WifiAuthenticationType.wpaPersonal => 'WPA Personal',
      WifiAuthenticationType.shared => 'Shared',
      WifiAuthenticationType.wpaEnterprise => 'WPA Enterprise',
      WifiAuthenticationType.wpa2Enterprise => 'WPA2 Enterprise',
      WifiAuthenticationType.wpa2Personal => 'WPA2 Personal',
      WifiAuthenticationType.wpaWpa2Personal => 'WPA/WPA2 Personal',
      WifiAuthenticationType.wpa3Personal => 'WPA3 Personal',
      WifiAuthenticationType.wpa3Enterprise => 'WPA3 Enterprise',
    };
  }

  String _wifiEncryptionLabel(WifiEncryptionType value) {
    return switch (value) {
      WifiEncryptionType.none => 'None',
      WifiEncryptionType.wep => 'WEP',
      WifiEncryptionType.tkip => 'TKIP',
      WifiEncryptionType.aes => 'AES',
      WifiEncryptionType.aesTkip => 'AES/TKIP',
    };
  }

  static String _initialValue(NDEFRecord? record) {
    return switch (record?.editableType) {
      NdefEditableRecordType.uri => (record as UriRecord).iriString ?? '',
      NdefEditableRecordType.text => (record as TextRecord).text ?? '',
      NdefEditableRecordType.phone =>
        (record as UriRecord).iriString?.replaceFirst('tel:', '') ?? '',
      NdefEditableRecordType.contact => record?.vCardField('FN') ?? '',
      NdefEditableRecordType.wifi => (record as WifiRecord).ssid ?? '',
      NdefEditableRecordType.androidApplication =>
        (record as AARRecord).packageName ?? '',
      _ => '',
    };
  }

  static String _initialSecondaryValue(NDEFRecord? record) {
    return switch (record?.editableType) {
      NdefEditableRecordType.contact => record?.vCardField('TEL') ?? '',
      NdefEditableRecordType.wifi => (record as WifiRecord).networkKey ?? '',
      _ => '',
    };
  }

  static String _initialPayloadValue(NDEFRecord? record) {
    if (record == null ||
        record.editableType != NdefEditableRecordType.custom) {
      return '';
    }
    try {
      return _hex(NdefDocument.payloadForEditing(record));
    } catch (_) {
      return '';
    }
  }

  static String _hex(Uint8List? bytes) {
    if (bytes == null) return '';
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }

  static String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
