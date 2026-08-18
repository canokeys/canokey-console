import 'dart:convert';
import 'dart:typed_data';

import 'package:canokey_console/models/ndef.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndef/ndef.dart';

void main() {
  group('NdefDocument', () {
    test('round trips URI and text records through nfcim/ndef', () {
      final document = NdefDocument([
        NdefDocument.uriRecord('https://canokeys.org/docs'),
        NdefDocument.textRecord('Hello, CanoKey', language: 'en'),
      ]);

      final decoded = NdefDocument.decode(document.encode());

      expect(decoded.records, hasLength(2));
      expect(decoded.records[0], isA<UriRecord>());
      expect((decoded.records[0] as UriRecord).iriString,
          'https://canokeys.org/docs');
      expect(decoded.records[1], isA<TextRecord>());
      expect((decoded.records[1] as TextRecord).text, 'Hello, CanoKey');
      expect((decoded.records[1] as TextRecord).language, 'en');
    });

    test('preserves an unsupported record while re-encoding', () {
      final custom = NDEFRecord(
        tnf: TypeNameFormat.media,
        type: Uint8List.fromList(utf8.encode('application/example')),
        payload: Uint8List.fromList([1, 2, 3, 4]),
      );

      final encoded = NdefDocument([custom]).encode();
      final decoded = NdefDocument.decode(encoded).records.single;

      expect(decoded.fullType, 'application/example');
      expect(decoded.payload, [1, 2, 3, 4]);
      expect(NdefDocument([decoded]).encode(), encoded);
    });

    test('decodes an empty NDEF file as an empty document', () {
      final document = NdefDocument.decode(Uint8List(0));

      expect(document.records, isEmpty);
      expect(document.encodedLength, 0);
    });

    test('round trips phone and contact records', () {
      final document = NdefDocument([
        NdefDocument.phoneRecord('+86 138 0000 0000'),
        NdefDocument.contactRecord(
          name: 'CanoKey User',
          phone: '+86 138 0000 0000',
          email: 'user@canokeys.org',
          organization: 'CanoKey',
        ),
      ]);

      final decoded = NdefDocument.decode(document.encode());

      expect(decoded.records[0].editableType, NdefEditableRecordType.phone);
      expect(decoded.records[0].summary, '+86 138 0000 0000');
      expect(decoded.records[1].editableType, NdefEditableRecordType.contact);
      expect(decoded.records[1].vCardField('FN'), 'CanoKey User');
      expect(decoded.records[1].vCardField('TEL'), '+86 138 0000 0000');
      expect(decoded.records[1].vCardField('EMAIL'), 'user@canokeys.org');
      expect(decoded.records[1].vCardField('ORG'), 'CanoKey');
    });

    test('maps advanced nfcim/ndef records to Other without data loss', () {
      final bluetoothClassic = BluetoothEasyPairingRecord(
        address: EPAddress(address: 'AA:BB:CC:DD:EE:FF'),
      )..deviceName = 'CanoKey';
      final bluetoothLowEnergy = BluetoothLowEnergyRecord()
        ..address = LEAddress(
          type: LEAddressType.public,
          address: '11:22:33:44:55:66',
        )
        ..deviceName = 'CanoKey LE';
      final records = <NDEFRecord>[
        SmartPosterRecord(
          uri: 'https://canokeys.org',
          title: 'CanoKey',
          action: Action.exec,
        ),
        MimeRecord(
          decodedType: 'application/json',
          payload: Uint8List.fromList(utf8.encode('{}')),
        ),
        bluetoothClassic,
        bluetoothLowEnergy,
        NdefDocument.rawRecord(
          tnf: TypeNameFormat.absoluteURI,
          type: 'https://canokeys.org/absolute',
          payload: Uint8List(0),
        ),
        ExternalRecord(
          decodedType: 'canokeys.org:record',
          payload: Uint8List.fromList([1]),
        ),
        DeviceInformationRecord(
          vendorName: 'CanoKey',
          modelName: 'CanoKey 3',
          uuid: '00000000-0000-0000-0000-000000000000',
        ),
        SignatureRecord(),
        HandoverSelectRecord(),
        NdefDocument.rawRecord(
          tnf: TypeNameFormat.unknown,
          type: '',
          payload: Uint8List.fromList([0xCA, 0xFE]),
        ),
      ];

      final decoded = NdefDocument.decode(NdefDocument(records).encode());

      expect(
        decoded.records.map((record) => record.editableType),
        everyElement(NdefEditableRecordType.custom),
      );
      expect(NdefDocument(decoded.records).encode(), isNotEmpty);
    });

    test('raw record preserves TNF, type, payload and id', () {
      final record = NdefDocument.rawRecord(
        tnf: TypeNameFormat.nfcExternal,
        type: 'canokeys.org:test',
        payload: Uint8List.fromList([0x01, 0x02]),
        id: Uint8List.fromList([0xA0]),
      );

      final decoded =
          NdefDocument.decode(NdefDocument([record]).encode()).records.single;

      expect(decoded.tnf, TypeNameFormat.nfcExternal);
      expect(decoded.safeDecodedType, 'canokeys.org:test');
      expect(decoded.payload, [0x01, 0x02]);
      expect(decoded.id, [0xA0]);
    });
  });
}
