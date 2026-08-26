import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/ndef.dart';

enum NdefEditableRecordType {
  uri,
  text,
  phone,
  contact,
  wifi,
  androidApplication,
  custom,
}

enum NdefPayloadEncoding { text, hex }

class NdefDocument {
  final List<NDEFRecord> records;

  NdefDocument(Iterable<NDEFRecord> records)
      : records = List<NDEFRecord>.from(records);

  factory NdefDocument.decode(Uint8List data) {
    return NdefDocument(data.isEmpty ? const [] : decodeRawNdefMessage(data));
  }

  Uint8List encode() => encodeNdefMessage(
        records.map(_encodableRecord).toList(),
      );

  int get encodedLength => encode().length;

  static UriRecord uriRecord(String uri) => UriRecord.fromString(uri);

  static UriRecord phoneRecord(String phone) {
    final value = phone.trim();
    return UriRecord.fromString(
      value.startsWith('tel:') ? value : 'tel:$value',
    );
  }

  static TextRecord textRecord(
    String text, {
    String language = 'en',
    TextEncoding encoding = TextEncoding.UTF8,
  }) {
    return TextRecord(
      text: text,
      language: language,
      encoding: encoding,
    );
  }

  static MimeRecord contactRecord({
    required String name,
    String? phone,
    String? email,
    String? organization,
  }) {
    final escapedName = _escapeVCard(name.trim());
    final lines = <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      'N:$escapedName;;;;',
      'FN:$escapedName',
    ];
    if (phone?.trim().isNotEmpty == true) {
      lines.add('TEL;TYPE=CELL:${_escapeVCard(phone!.trim())}');
    }
    if (email?.trim().isNotEmpty == true) {
      lines.add('EMAIL:${_escapeVCard(email!.trim())}');
    }
    if (organization?.trim().isNotEmpty == true) {
      lines.add('ORG:${_escapeVCard(organization!.trim())}');
    }
    lines
      ..add('END:VCARD')
      ..add('');
    return MimeRecord(
      decodedType: 'text/vcard',
      payload: Uint8List.fromList(utf8.encode(lines.join('\r\n'))),
    );
  }

  static NDEFRecord rawRecord({
    required TypeNameFormat tnf,
    required String type,
    required Uint8List payload,
    Uint8List? id,
  }) {
    return NDEFRecord(
      tnf: tnf,
      type: Uint8List.fromList(utf8.encode(type)),
      payload: payload,
      id: id,
    );
  }

  static Uint8List payloadForEditing(NDEFRecord record) {
    return _encodableRecord(record).payload ?? Uint8List(0);
  }

  static NDEFRecord _encodableRecord(NDEFRecord record) {
    if (record is! BluetoothLowEnergyRecord) return record;

    // ndef 0.4.0 casts List<int?> directly to Uint8List in this getter.
    final payload = <int>[];
    for (final entry in record.attributes.entries) {
      final type = entry.key == null ? null : EIR.typeNumMap[entry.key!];
      if (type == null) {
        throw ArgumentError('Unsupported Bluetooth LE EIR type: ${entry.key}');
      }
      payload
        ..add(entry.value.length + 1)
        ..add(type)
        ..addAll(entry.value);
    }
    return NDEFRecord(
      tnf: TypeNameFormat.media,
      type: Uint8List.fromList(utf8.encode(BluetoothLowEnergyRecord.classType)),
      payload: Uint8List.fromList(payload),
      id: record.id,
    );
  }

  static String _escapeVCard(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('\n', r'\n')
        .replaceAll(',', r'\,')
        .replaceAll(';', r'\;');
  }
}

extension NdefRecordDetails on NDEFRecord {
  NdefEditableRecordType? get editableType {
    if (this is UriRecord &&
        (this as UriRecord).iriString?.startsWith('tel:') == true) {
      return NdefEditableRecordType.phone;
    }
    if (this is UriRecord) return NdefEditableRecordType.uri;
    if (this is TextRecord) return NdefEditableRecordType.text;
    if (this is WifiRecord) return NdefEditableRecordType.wifi;
    if (this is MimeRecord &&
        const {'text/vcard', 'text/x-vcard'}
            .contains(safeDecodedType?.toLowerCase())) {
      return NdefEditableRecordType.contact;
    }
    if (this is AARRecord) return NdefEditableRecordType.androidApplication;
    return NdefEditableRecordType.custom;
  }

  String get displayType {
    if (editableType == NdefEditableRecordType.phone) return 'Phone';
    if (editableType == NdefEditableRecordType.contact) return 'Contact';
    if (this is UriRecord) return 'URI';
    if (this is TextRecord) return 'Text';
    if (this is SmartPosterRecord) return 'Smart Poster';
    if (this is WifiRecord) return 'Wi-Fi';
    if (this is BluetoothEasyPairingRecord) return 'Bluetooth';
    if (this is BluetoothLowEnergyRecord) return 'Bluetooth LE';
    if (this is AbsoluteUriRecord || tnf == TypeNameFormat.absoluteURI) {
      return 'Absolute URI';
    }
    if (this is AARRecord) return 'AAR';
    if (this is DeviceInformationRecord) return 'Device Information';
    if (this is SignatureRecord) return 'Signature';
    if (this is HandoverRecord) return 'Connection Handover';
    final type = safeDecodedType;
    if (type == null || type.isEmpty) return tnf.name;
    return switch (tnf) {
      TypeNameFormat.nfcWellKnown => 'urn:nfc:wkt:$type',
      TypeNameFormat.nfcExternal => 'urn:nfc:ext:$type',
      _ => type,
    };
  }

  String? get safeDecodedType {
    final value = encodedType;
    if (value == null) return null;
    return utf8.decode(value, allowMalformed: true);
  }

  String get summary {
    if (editableType == NdefEditableRecordType.phone && this is UriRecord) {
      return (this as UriRecord).iriString?.replaceFirst('tel:', '') ?? '';
    }
    if (editableType == NdefEditableRecordType.contact) {
      final name = vCardField('FN') ?? '';
      final phone = vCardField('TEL') ?? '';
      return [name, phone].where((value) => value.isNotEmpty).join(' - ');
    }
    if (this case UriRecord record) {
      return record.iriString ?? '';
    }
    if (this case TextRecord record) {
      return record.text ?? '';
    }
    if (this case SmartPosterRecord record) {
      final uri = record.uri?.toString() ?? '';
      final title = record.title ?? '';
      return [title, uri].where((value) => value.isNotEmpty).join(' - ');
    }
    if (this case WifiRecord record) {
      return [record.ssid ?? '', record.authenticationType.name]
          .where((value) => value.isNotEmpty)
          .join(' - ');
    }
    if (this case BluetoothEasyPairingRecord record) {
      return [record.deviceName, record.address?.address ?? '']
          .where((value) => value.isNotEmpty)
          .join(' - ');
    }
    if (this case BluetoothLowEnergyRecord record) {
      return [record.deviceName, record.address?.address ?? '']
          .where((value) => value.isNotEmpty)
          .join(' - ');
    }
    if (this case AARRecord record) return record.packageName ?? '';
    if (this case DeviceInformationRecord record) {
      return [record.vendorName ?? '', record.modelName ?? '']
          .where((value) => value.isNotEmpty)
          .join(' - ');
    }
    if (tnf == TypeNameFormat.absoluteURI) return safeDecodedType ?? '';

    final value = payload;
    if (value == null || value.isEmpty) return '';
    try {
      return utf8.decode(value);
    } on FormatException {
      const hexDigits = '0123456789ABCDEF';
      return value
          .take(24)
          .map((byte) =>
              '${hexDigits[(byte >> 4) & 0x0f]}${hexDigits[byte & 0x0f]}')
          .join(' ');
    }
  }

  String? vCardField(String field) {
    if (editableType != NdefEditableRecordType.contact) return null;
    final bytes = payload;
    if (bytes == null) return null;
    final prefix = field.toUpperCase();
    final text = utf8.decode(bytes, allowMalformed: true);
    for (final line in text.split(RegExp(r'\r?\n'))) {
      final separator = line.indexOf(':');
      if (separator < 0) continue;
      final name = line.substring(0, separator).split(';').first.toUpperCase();
      if (name == prefix) {
        return line
            .substring(separator + 1)
            .replaceAll(r'\n', '\n')
            .replaceAll(r'\,', ',')
            .replaceAll(r'\;', ';')
            .replaceAll(r'\\', r'\');
      }
    }
    return null;
  }
}
