import 'dart:convert';

import 'package:canokey_console/helper/tlv.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:convert/convert.dart';

class OpenPgpCardClient {
  static const String _aid = 'D27600012401';
  String? lastStatusWord;

  Future<void> select() async {
    SmartCard.assertOK(await _transceive('00A4040006$_aid'));
  }

  Future<OpenPgpCardInfo> readCardInfo() async {
    await select();
    final applicationData = await _readDataObject(0x6E);
    final application = _parseApplicationRelatedData(applicationData);
    final discretionary = _parseDiscretionaryData(application);
    final aid = _bytes(application[0x4F]);
    final version = _versionFromAid(aid);
    final manufacturer = _manufacturerFromAid(aid);
    final serial = _serialFromAid(aid);
    final holder = _decodeCardholder(await _tryReadDataObject(0x65));
    final url = _decodeText(await _tryReadDataObject(0x5F50));
    final pinState = _parsePinState(_bytes(discretionary[0xC4]));
    final fingerprints = _splitFixed(_bytes(discretionary[0xC5]), 20);
    final generationTimes = _splitFixed(_bytes(discretionary[0xCD]), 4);
    final uif = _parseUif(discretionary);
    final touchCacheTime = await _readTouchCacheTime();

    final slots = <OpenPgpKeyType, OpenPgpKeySlotInfo>{};
    for (final type in OpenPgpKeyType.values) {
      final index = type.index;
      final touch = uif[type] ?? (OpenPgpTouchPolicy.off, false);
      slots[type] = OpenPgpKeySlotInfo(
        type: type,
        fingerprint: _fingerprintAt(fingerprints, index),
        generatedAt: _generationTimeAt(generationTimes, index),
        touchPolicy: touch.$1,
        touchFixed: touch.$2,
      );
    }

    return OpenPgpCardInfo(
      version: version,
      manufacturer: manufacturer,
      serialNumber: serial,
      cardHolder: holder,
      publicKeyUrl: url,
      pinState: pinState,
      keySlots: slots,
      touchCacheTime: touchCacheTime,
    );
  }

  Future<bool> changeUserPin(String oldPin, String newPin) async {
    await select();
    final data = hex.encode([...utf8.encode(oldPin), ...utf8.encode(newPin)]);
    return SmartCard.isOK(await _transceive(_capdu('00240081', data)));
  }

  Future<bool> changeAdminPin(String oldPin, String newPin) async {
    await select();
    final data = hex.encode([...utf8.encode(oldPin), ...utf8.encode(newPin)]);
    return SmartCard.isOK(await _transceive(_capdu('00240083', data)));
  }

  Future<bool> setResetCode(String adminPin, String resetCode) async {
    await select();
    if (!await verifyAdminPin(adminPin)) {
      return false;
    }
    final data = hex.encode(utf8.encode(resetCode));
    return SmartCard.isOK(await _putDataObject(0xD3, data));
  }

  Future<bool> setPinRetries(String adminPin, int userRetries, int resetRetries,
      int adminRetries) async {
    await select();
    if (!await verifyAdminPin(adminPin)) {
      return false;
    }
    final data = hex.encode([userRetries, resetRetries, adminRetries]);
    return SmartCard.isOK(await _transceive(_capdu('00F20000', data)));
  }

  Future<bool> setSignaturePinPolicy(
      String adminPin, bool verifyForEverySignature) async {
    await select();
    if (!await verifyAdminPin(adminPin)) {
      return false;
    }
    final data = hex.encode([verifyForEverySignature ? 0x00 : 0x01]);
    return SmartCard.isOK(await _putDataObject(0xC4, data));
  }

  Future<bool> unblockUserPinWithAdmin(String adminPin, String newPin) async {
    await select();
    if (!await verifyAdminPin(adminPin)) {
      return false;
    }
    final data = hex.encode(utf8.encode(newPin));
    return SmartCard.isOK(await _transceive(_capdu('002C0281', data)));
  }

  Future<bool> unblockUserPinWithResetCode(
      String resetCode, String newPin) async {
    await select();
    final data =
        hex.encode([...utf8.encode(resetCode), ...utf8.encode(newPin)]);
    return SmartCard.isOK(await _transceive(_capdu('002C0081', data)));
  }

  Future<bool> verifyAdminPin(String adminPin) async {
    final data = hex.encode(utf8.encode(adminPin));
    return SmartCard.isOK(await _transceive(_capdu('00200083', data)));
  }

  Future<bool> setTouchPolicy(OpenPgpKeyType keyType, OpenPgpTouchPolicy policy,
      String adminPin) async {
    await select();
    if (!await verifyAdminPin(adminPin)) {
      return false;
    }
    final data = hex.encode([policy.value, 0x20]);
    return SmartCard.isOK(await _putDataObject(keyType.uifTag, data));
  }

  Future<bool> setTouchCacheTime(String adminPin, int seconds) async {
    await select();
    if (!await verifyAdminPin(adminPin)) {
      return false;
    }
    final data = hex.encode([seconds]);
    return SmartCard.isOK(await _putDataObject(0x0102, data));
  }

  Future<List<int>> _readDataObject(int tag) async {
    final resp = await _getDataObject(tag);
    SmartCard.assertOK(resp);
    return hex.decode(SmartCard.dropSW(resp));
  }

  Future<List<int>?> _tryReadDataObject(int tag) async {
    final resp = await _getDataObject(tag);
    if (!SmartCard.isOK(resp)) {
      return null;
    }
    return hex.decode(SmartCard.dropSW(resp));
  }

  Future<String> _getDataObject(int tag) {
    return _transceive('00CA${tag.toRadixString(16).padLeft(4, '0')}00');
  }

  Future<String> _putDataObject(int tag, String data) {
    return _transceive(
      '00DA${tag.toRadixString(16).padLeft(4, '0')}${_hexLength(data.length ~/ 2)}$data',
    );
  }

  Map<OpenPgpKeyType, (OpenPgpTouchPolicy, bool)> _parseUif(Map discretionary) {
    final result = <OpenPgpKeyType, (OpenPgpTouchPolicy, bool)>{};
    for (final type in OpenPgpKeyType.values) {
      final data = _bytes(discretionary[type.uifTag]);
      result[type] = _parseUifValue(data);
    }
    return result;
  }

  (OpenPgpTouchPolicy, bool) _parseUifValue(List<int> data) {
    if (data.isEmpty) {
      return (OpenPgpTouchPolicy.off, false);
    }
    final policy = OpenPgpTouchPolicy.fromValue(data[0]);
    final fixed = policy == OpenPgpTouchPolicy.permanent ||
        policy == OpenPgpTouchPolicy.cachedPermanent;
    return (policy, fixed);
  }

  Future<int?> _readTouchCacheTime() async {
    final resp = await _transceive('00CA010201');
    if (!SmartCard.isOK(resp)) {
      return null;
    }
    final data = hex.decode(SmartCard.dropSW(resp));
    if (data.isEmpty) {
      return null;
    }
    return data[0];
  }

  Map _parseApplicationRelatedData(List<int> data) {
    final parsed = TLV.parse(data);
    final wrapped = _bytes(parsed[0x6E]);
    if (wrapped.isEmpty) {
      return parsed;
    }
    return TLV.parse(wrapped);
  }

  Map _parseDiscretionaryData(Map application) {
    final parsed = application[0x73];
    if (parsed is Map) {
      return parsed;
    }
    final raw = _bytes(parsed);
    if (raw.isNotEmpty) {
      return TLV.parse(raw);
    }
    return application;
  }

  OpenPgpPinState _parsePinState(List<int> data) {
    return OpenPgpPinState(
      signaturePinForced: data.isNotEmpty && data[0] == 0,
      userRetries: data.length > 4 ? data[4] : null,
      resetRetries: data.length > 5 ? data[5] : null,
      adminRetries: data.length > 6 ? data[6] : null,
    );
  }

  String _versionFromAid(List<int> aid) {
    if (aid.length < 8) {
      return '';
    }
    return '${_bcd(aid[6])}.${_bcd(aid[7])}';
  }

  String _manufacturerFromAid(List<int> aid) {
    if (aid.length < 10) {
      return '';
    }
    final id = (aid[8] << 8) + aid[9];
    if (id == 0x0006) {
      return 'Yubico';
    }
    if (id == 0x0000) {
      return '';
    }
    return '0x${id.toRadixString(16).padLeft(4, '0').toUpperCase()}';
  }

  String _serialFromAid(List<int> aid) {
    if (aid.length < 14) {
      return '';
    }
    return hex.encode(aid.sublist(10, 14)).toUpperCase();
  }

  int _bcd(int value) {
    return 10 * (value >> 4) + (value & 0x0F);
  }

  String _decodeCardholder(List<int>? data) {
    if (data == null || data.isEmpty) {
      return '';
    }
    try {
      final parsed = TLV.parse(data);
      return _decodeText(_bytes(parsed[0x5B]));
    } catch (_) {
      return _decodeText(data);
    }
  }

  String _decodeText(List<int>? data) {
    if (data == null || data.isEmpty) {
      return '';
    }
    try {
      return utf8.decode(data);
    } catch (_) {
      return latin1.decode(data);
    }
  }

  List<int> _bytes(dynamic value) {
    if (value is List<int>) {
      return value;
    }
    return [];
  }

  List<List<int>> _splitFixed(List<int> data, int width) {
    if (data.isEmpty || width <= 0) {
      return [];
    }
    final result = <List<int>>[];
    for (var offset = 0; offset + width <= data.length; offset += width) {
      result.add(data.sublist(offset, offset + width));
    }
    return result;
  }

  String? _fingerprintAt(List<List<int>> fingerprints, int index) {
    if (index >= fingerprints.length) {
      return null;
    }
    final fingerprint = fingerprints[index];
    if (fingerprint.every((byte) => byte == 0)) {
      return null;
    }
    return hex.encode(fingerprint).toUpperCase();
  }

  DateTime? _generationTimeAt(List<List<int>> generationTimes, int index) {
    if (index >= generationTimes.length) {
      return null;
    }
    final bytes = generationTimes[index];
    if (bytes.length != 4 || bytes.every((byte) => byte == 0)) {
      return null;
    }
    final seconds =
        (bytes[0] << 24) + (bytes[1] << 16) + (bytes[2] << 8) + bytes[3];
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }

  String _capdu(String header, String data) {
    return '$header${_hexLength(data.length ~/ 2)}$data';
  }

  String _hexLength(int length) {
    if (length <= 0xFF) {
      return length.toRadixString(16).padLeft(2, '0');
    }
    return '00${length.toRadixString(16).padLeft(4, '0')}';
  }

  Future<String> _transceive(String capdu) async {
    String rapdu = '';
    do {
      if (rapdu.length >= 4) {
        final remain = rapdu.substring(rapdu.length - 2);
        capdu = '00C00000$remain';
        rapdu = rapdu.substring(0, rapdu.length - 4);
      }
      rapdu += await SmartCard.transceive(capdu);
    } while (rapdu.substring(rapdu.length - 4, rapdu.length - 2) == '61');
    lastStatusWord = SmartCard.sw(rapdu);
    return rapdu;
  }
}
