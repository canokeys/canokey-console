import 'dart:typed_data';

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:convert/convert.dart';

class PivCardClient {
  PivCardClient({
    ApduTransport transport = const SmartCardApduTransport(),
  }) : _transport = transport;

  final ApduTransport _transport;
  String? lastStatusWord;

  Future<void> select() async {
    SmartCard.assertOK(await _transport.transceive('00A4040005A000000308'));
  }

  Future<Uint8List> readVersion() async {
    final response = await _transport.transceive('00FD000000');
    SmartCard.assertOK(response);
    return Uint8List.fromList(hex.decode(SmartCard.dropSW(response)));
  }

  Future<String> readSerial() async {
    final response = await _transport.transceive('00F8000000');
    SmartCard.assertOK(response);
    return SmartCard.dropSW(response).toUpperCase();
  }

  Future<String> readPinRetries() async {
    final response = await _transport.transceive('0020008000');
    lastStatusWord = SmartCard.sw(response);
    return response;
  }

  Future<bool> verifyPin(String pin) async {
    final response = await _transport.transceive(
      '0020008008${_padPin(pin)}',
    );
    lastStatusWord = SmartCard.sw(response);
    return SmartCard.isOK(response);
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    final response = await _transport.transceive(
      '0024008010${_padPin(oldPin)}${_padPin(newPin)}',
    );
    lastStatusWord = SmartCard.sw(response);
    return SmartCard.isOK(response);
  }

  Future<void> logout() async {
    SmartCard.assertOK(await _transport.transceive('0020FF8000'));
  }

  Future<PivAlgorithmExtensionConfig?> readAlgorithmExtensions() async {
    await select();
    final response = await _transport.transceive('00EE010000');
    if (!SmartCard.isOK(response)) return null;
    return PivAlgorithmExtensionConfig.decode(
      hex.decode(SmartCard.dropSW(response)),
    );
  }

  Future<SlotInfo?> readMetadata(
    int slot, {
    PivAlgorithmExtensionConfig? algorithmExtensionConfig,
  }) async {
    final response = await transceive(
      '00F700${slot.toRadixString(16).padLeft(2, '0')}00',
    );
    final statusWord = SmartCard.sw(response);
    if (!SmartCard.isOK(response) ||
        statusWord == '6A88' ||
        statusWord == '6700') {
      return null;
    }
    final data = hex.decode(SmartCard.dropSW(response));
    if (algorithmExtensionConfig == null) {
      return SlotInfo.parse(slot, data);
    }
    return SlotInfo.parse(
      slot,
      data,
      algorithmExtensionConfig: algorithmExtensionConfig,
    );
  }

  Future<String> transceive(String capdu) async {
    var response = '';
    do {
      if (response.length >= 4) {
        final remaining = response.substring(response.length - 2);
        capdu = '00C00000$remaining';
        response = response.substring(0, response.length - 4);
      }
      response += await _transport.transceive(capdu);
    } while (
        response.substring(response.length - 4, response.length - 2) == '61');
    lastStatusWord = SmartCard.sw(response);
    return response;
  }

  String _padPin(String pin) {
    final bytes = Uint8List(8)..fillRange(0, 8, 0xff);
    final pinBytes = pin.codeUnits;
    if (pinBytes.length > bytes.length) {
      throw ArgumentError.value(pin, 'pin', 'PIV PIN must not exceed 8 bytes');
    }
    bytes.setRange(0, pinBytes.length, pinBytes);
    return hex.encode(bytes).toUpperCase();
  }
}
