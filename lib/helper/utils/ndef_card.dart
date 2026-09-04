import 'dart:math';
import 'dart:typed_data';

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:convert/convert.dart';

class NdefCardData {
  const NdefCardData({
    required this.maxMessageLength,
    required this.readOnly,
    required this.message,
  });

  final int maxMessageLength;
  final bool readOnly;
  final Uint8List message;
}

class NdefReadOnlyException implements Exception {
  const NdefReadOnlyException();
}

class NdefCardClient {
  NdefCardClient({
    ApduTransport transport = const SmartCardApduTransport(),
  }) : _transport = transport;

  static const int _chunkSize = 240;
  static const String _selectApplet = '00A4040007D2760000850101';
  static const String _selectCapabilityContainer = '00A4000C02E103';
  static const String _selectNdefFile = '00A4000C020001';

  final ApduTransport _transport;

  Future<NdefCardData?> read() async {
    if (!await _select()) return null;

    _assertOK(await _transport.transceive(_selectCapabilityContainer));
    final capability = await _readBytes(0, 15);
    if (capability.length != 15 ||
        capability[7] != 0x04 ||
        capability[8] != 0x06) {
      throw const FormatException('Invalid NDEF capability container');
    }
    final fileLength = (capability[11] << 8) | capability[12];
    if (fileLength < 2) {
      throw const FormatException('Invalid NDEF file capacity');
    }

    _assertOK(await _transport.transceive(_selectNdefFile));
    final lengthData = await _readBytes(0, 2);
    final messageLength = (lengthData[0] << 8) | lengthData[1];
    final maxMessageLength = fileLength - 2;
    if (messageLength > maxMessageLength) {
      throw FormatException(
        'NDEF message length $messageLength exceeds $maxMessageLength',
      );
    }

    return NdefCardData(
      maxMessageLength: maxMessageLength,
      readOnly: capability[14] != 0,
      message: await _readBytes(2, messageLength),
    );
  }

  Future<bool> write(Uint8List message) async {
    if (!await _select()) return false;

    _assertOK(await _transport.transceive(_selectNdefFile));
    await _updateBytes(0, Uint8List.fromList([0, 0]));
    for (var offset = 0; offset < message.length; offset += _chunkSize) {
      final end = min(offset + _chunkSize, message.length);
      await _updateBytes(2 + offset, message.sublist(offset, end));
    }
    await _updateBytes(
      0,
      Uint8List.fromList([message.length >> 8, message.length & 0xff]),
    );
    return true;
  }

  Future<bool> _select() async {
    final response = await _transport.transceive(_selectApplet);
    if (SmartCard.sw(response) == '6A82') return false;
    _assertOK(response);
    return true;
  }

  Future<Uint8List> _readBytes(int offset, int length) async {
    final result = <int>[];
    for (var cursor = 0; cursor < length; cursor += _chunkSize) {
      final count = min(_chunkSize, length - cursor);
      final response = await _transport.transceive(
        readBinaryApdu(offset + cursor, count),
      );
      _assertOK(response);
      result.addAll(hex.decode(SmartCard.dropSW(response)));
    }
    return Uint8List.fromList(result);
  }

  Future<void> _updateBytes(int offset, Uint8List data) async {
    if (data.isEmpty) return;
    final response =
        await _transport.transceive(updateBinaryApdu(offset, data));
    if (SmartCard.sw(response) == '6982') {
      throw const NdefReadOnlyException();
    }
    _assertOK(response);
  }

  static String readBinaryApdu(int offset, int length) {
    if (offset < 0 || offset > 0xffff || length < 1 || length > 0xff) {
      throw RangeError('Invalid READ BINARY range');
    }
    return '00B0${offset.toRadixString(16).padLeft(4, '0')}'
            '${length.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  static String updateBinaryApdu(int offset, Uint8List data) {
    if (offset < 0 || offset > 0xffff || data.isEmpty || data.length > 0xff) {
      throw RangeError('Invalid UPDATE BINARY range');
    }
    return '00D6${offset.toRadixString(16).padLeft(4, '0')}'
            '${data.length.toRadixString(16).padLeft(2, '0')}'
            '${hex.encode(data)}'
        .toUpperCase();
  }

  void _assertOK(String response) {
    SmartCard.assertOK(response);
  }
}
