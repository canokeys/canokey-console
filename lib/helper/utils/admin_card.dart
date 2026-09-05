import 'dart:convert';
import 'dart:typed_data';

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:convert/convert.dart';

class AdminStorageUsage {
  const AdminStorageUsage({required this.usedKiB, required this.totalKiB});

  final int usedKiB;
  final int totalKiB;
}

class AdminCardClient {
  AdminCardClient({
    ApduTransport transport = const SmartCardApduTransport(),
  }) : _transport = transport;

  final ApduTransport _transport;
  String? lastResponse;

  Future<void> select() async {
    SmartCard.assertOK(await _transport.transceive('00A4040005F000000000'));
  }

  Future<bool> verifyPin(String pin) async {
    final data = _encodePin(pin);
    final response = lastResponse = await _transport.transceive(
      '00200000${data.length.toRadixString(16).padLeft(2, '0')}'
      '${hex.encode(data)}',
    );
    return SmartCard.isOK(response);
  }

  Future<void> changePin(String pin) async {
    final data = _encodePin(pin);
    SmartCard.assertOK(await _transport.transceive(
      '00210000${data.length.toRadixString(16).padLeft(2, '0')}'
      '${hex.encode(data)}',
    ));
  }

  List<int> _encodePin(String pin) {
    final data = utf8.encode(pin);
    if (data.length > 0xff) {
      throw ArgumentError.value(
        data.length,
        'encodedPinLength',
        'UTF-8 encoded PIN must fit in a short APDU',
      );
    }
    return data;
  }

  Future<String> readFirmwareVersion() => _readText('0031000000');

  Future<String> readModel() => _readText('0031010000');

  Future<String> readSerial() => _readHex('0032000000');

  Future<String> readChipId() => _readHex('0032010000');

  Future<Uint8List> readConfig() async {
    final response = await _transport.transceive('0042000000');
    SmartCard.assertOK(response);
    return Uint8List.fromList(hex.decode(SmartCard.dropSW(response)));
  }

  Future<void> writeConfigByte(int index, int value) async {
    if (index < 0 || index > 0xff || value < 0 || value > 0xff) {
      throw RangeError('Invalid admin configuration byte');
    }
    final response = await _transport.transceive(
      '0040${index.toRadixString(16).padLeft(2, '0')}'
      '${value.toRadixString(16).padLeft(2, '0')}',
    );
    SmartCard.assertOK(response);
  }

  Future<bool> readNfcEnabled() async {
    final response = await _transport.transceive('0014000000');
    SmartCard.assertOK(response);
    final data = SmartCard.dropSW(response);
    if (data.length != 2 || (data != '00' && data != '01')) {
      throw const FormatException('Invalid NFC state');
    }
    return data == '01';
  }

  Future<void> setNfcEnabled(bool enabled) async {
    SmartCard.assertOK(
      await _transport.transceive(enabled ? '00140101' : '00140100'),
    );
  }

  Future<AdminStorageUsage> readStorageUsage() async {
    final response = await _transport.transceive('0041000002');
    SmartCard.assertOK(response);
    final data = hex.decode(SmartCard.dropSW(response));
    if (data.length != 2) {
      throw const FormatException('Invalid storage usage');
    }
    return AdminStorageUsage(usedKiB: data[0], totalKiB: data[1]);
  }

  Future<String?> readCoreCommit() async {
    final response = await _transport.transceive('0031020000');
    if (!SmartCard.isOK(response)) return null;
    final data = SmartCard.dropSW(response);
    return data.isEmpty ? null : utf8.decode(hex.decode(data));
  }

  Future<void> setNdefReadOnly(bool readOnly) async {
    SmartCard.assertOK(
      await _transport.transceive(readOnly ? '00080100' : '00080000'),
    );
  }

  Future<void> resetNdef() async {
    SmartCard.assertOK(await _transport.transceive('00070000'));
  }

  Future<String> _readText(String command) async {
    final data = await _readHex(command);
    return utf8.decode(hex.decode(data));
  }

  Future<String> _readHex(String command) async {
    final response = await _transport.transceive(command);
    SmartCard.assertOK(response);
    return SmartCard.dropSW(response).toUpperCase();
  }
}
