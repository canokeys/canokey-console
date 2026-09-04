import 'dart:convert';

import 'package:canokey_console/helper/tlv.dart';
import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:convert/convert.dart';

class OathSelection {
  const OathSelection({
    required this.response,
    required this.version,
    required this.info,
  });

  final String response;
  final OathVersion version;
  final Map info;
}

class OathCardClient {
  OathCardClient({
    ApduTransport transport = const SmartCardApduTransport(),
  }) : _transport = transport;

  final ApduTransport _transport;
  OathVersion version = OathVersion.v1;

  Future<OathSelection> select() async {
    final response = await _transport.transceive(
      '00A4040007A0000005272101',
    );
    SmartCard.assertOK(response);
    if (response.toUpperCase() == '9000') {
      version = OathVersion.legacy;
      return OathSelection(
          response: response, version: version, info: const {});
    }

    final info = TLV.parse(hex.decode(SmartCard.dropSW(response)));
    final versionData = info[0x79];
    if (versionData is List<int>) {
      final encoded = hex.encode(versionData);
      if (encoded == '050505') {
        version = OathVersion.v1;
      } else if (encoded == '060000') {
        version = OathVersion.v2;
      }
    }
    return OathSelection(response: response, version: version, info: info);
  }

  Future<String> put({
    required String name,
    required String secretHex,
    required OathType type,
    required OathAlgorithm algorithm,
    required int digits,
    bool requireTouch = false,
    int initialValue = 0,
  }) {
    final nameData = _nameData(name);
    final credential = StringBuffer(nameData)
      ..write('73')
      ..write((secretHex.length ~/ 2 + 2).toRadixString(16).padLeft(2, '0'))
      ..write((type.value | algorithm.value).toRadixString(16).padLeft(2, '0'))
      ..write(digits.toRadixString(16).padLeft(2, '0'))
      ..write(secretHex);
    if (requireTouch) {
      credential.write(version == OathVersion.legacy ? '780102' : '7802');
    }
    if (initialValue > 0) {
      credential.write(
        '7A04${initialValue.toRadixString(16).padLeft(4, '0')}',
      );
    }
    return transceive(_command('00010000', credential.toString()));
  }

  Future<String> calculate({
    required String name,
    required OathType type,
    String? challengeHex,
  }) {
    final data = StringBuffer(_nameData(name));
    if (type == OathType.totp) {
      if (challengeHex == null || challengeHex.length != 16) {
        throw ArgumentError.value(
          challengeHex,
          'challengeHex',
          'TOTP challenges must contain eight bytes',
        );
      }
      data.write('7408$challengeHex');
    }
    final header = version == OathVersion.legacy ? '00040000' : '00A20001';
    return transceive(_command(header, data.toString()));
  }

  Future<String> calculateAll(String challengeHex) {
    if (challengeHex.length != 16) {
      throw ArgumentError.value(
        challengeHex,
        'challengeHex',
        'OATH challenges must contain eight bytes',
      );
    }
    final header = version == OathVersion.legacy ? '00050000' : '00A40001';
    return transceive(_command(header, '7408$challengeHex'));
  }

  Future<String> delete(String name) {
    return transceive(_command('00020000', _nameData(name)));
  }

  Future<String> transceive(String capdu) async {
    final isListCommand =
        (version == OathVersion.legacy && capdu.startsWith('000500')) ||
            (version != OathVersion.legacy && capdu.startsWith('00A400'));
    if (!isListCommand) {
      return _transport.transceive(capdu);
    }

    var response = await _transport.transceive(capdu);
    final result = StringBuffer();
    while (true) {
      final statusWord = SmartCard.sw(response);
      result.write(SmartCard.dropSW(response));
      if (statusWord.startsWith('61') || statusWord == '9000') {
        final getResponse =
            version == OathVersion.legacy ? '00060000FF' : '00A50000FF';
        response = await _transport.transceive(getResponse);
        if (SmartCard.sw(response) == '6985') {
          return '${result}9000';
        }
      } else {
        return '$result$statusWord';
      }
    }
  }

  String _nameData(String name) {
    final bytes = utf8.encode(name);
    return '71${bytes.length.toRadixString(16).padLeft(2, '0')}'
        '${hex.encode(bytes)}';
  }

  String _command(String header, String data) {
    return '$header${(data.length ~/ 2).toRadixString(16).padLeft(2, '0')}$data';
  }
}
