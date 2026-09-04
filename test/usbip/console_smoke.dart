import 'dart:convert';
import 'dart:io';

import 'package:canokey_console/helper/tlv.dart';
import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/openpgp_card.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:ccid/ccid.dart';
import 'package:fido2/fido2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _adminAid = '00A4040005F000000000';
const _defaultAdminPin = '0020000006313233343536';
const _defaultPivPin = '313233343536FFFF';
const _alternatePivPin = '363534333231FFFF';
const _defaultOpenPgpUserPin = '123456';
const _alternateOpenPgpUserPin = '654321';
const _defaultOpenPgpAdminPin = '12345678';
const _alternateOpenPgpAdminPin = '87654321';

class ApduResponse {
  ApduResponse(this.data, this.statusWord);

  factory ApduResponse.parse(String value) {
    if (value.length < 4 || value.length.isOdd) {
      throw FormatException('Invalid response APDU length: ${value.length}');
    }
    return ApduResponse(
      value.substring(0, value.length - 4),
      value.substring(value.length - 4).toUpperCase(),
    );
  }

  final String data;
  final String statusWord;
}

class ConsoleSmoke {
  ConsoleSmoke({required this.card, required this.expectedVersion}) {
    _openPgpClient = OpenPgpCardClient(
      transport: _CcidApduTransport(
        card,
        onResponse: (response) {
          checks.add({
            'name': 'openpgp.client.transceive',
            'status_word': response.statusWord,
            'response_bytes': response.data.length ~/ 2,
          });
        },
      ),
    );
  }

  final CcidCard card;
  final String expectedVersion;
  final List<Map<String, Object?>> checks = [];
  late final OpenPgpCardClient _openPgpClient;
  late FunctionSetVersion _functionSet;
  late String _adminSerial;
  late bool _initialNdefReadonly;

  Future<void> run() async {
    await _adminApplet();
    await _openPgpApplet();
    await _pivApplet();
    await _oathApplet();
    await _ndefApplet();
    await _webAuthnApplet();
    await _passApplet();
  }

  Future<ApduResponse> _send(
    String name,
    String command, {
    Set<String> acceptedStatusWords = const {'9000'},
    bool allowMoreData = false,
  }) async {
    final raw = await card.transceive(command);
    if (raw == null) {
      throw StateError('$name returned no response');
    }
    final response = ApduResponse.parse(raw);
    if (!acceptedStatusWords.contains(response.statusWord) &&
        !(allowMoreData && response.statusWord.startsWith('61'))) {
      throw StateError('$name failed with status word ${response.statusWord}');
    }
    checks.add({
      'name': name,
      'status_word': response.statusWord,
      'response_bytes': response.data.length ~/ 2,
    });
    stdout.writeln('ok: $name');
    return response;
  }

  Future<ApduResponse> _sendChained(
    String name,
    String command, {
    required String commandClass,
  }) async {
    final data = StringBuffer();
    var response = await _send(
      '$name (initial)',
      command,
      acceptedStatusWords: const {'9000'},
      allowMoreData: true,
    );

    while (true) {
      data.write(response.data);
      if (response.statusWord == '9000') {
        return ApduResponse(data.toString(), response.statusWord);
      }
      if (!response.statusWord.startsWith('61')) {
        throw StateError(
          '$name failed with status word ${response.statusWord}',
        );
      }
      final remaining = response.statusWord.substring(2);
      final raw = await card.transceive('${commandClass}C00000$remaining');
      if (raw == null) throw StateError('$name GET RESPONSE returned no data');
      response = ApduResponse.parse(raw);
    }
  }

  Future<void> _adminApplet() async {
    await _send('admin.select', _adminAid);

    final version = await _send('admin.firmware_version', '0031000000');
    final actualVersion = _decodeText(version.data, 'firmware version');
    _expect(
      actualVersion == expectedVersion,
      'Expected firmware $expectedVersion, got $actualVersion',
    );

    final model = await _send('admin.model', '0031010000');
    _expect(_decodeText(model.data, 'model').isNotEmpty, 'Empty model');

    final serial = await _send('admin.serial', '0032000000');
    _expect(serial.data.length == 8, 'Serial number must contain four bytes');
    _adminSerial = serial.data;

    final chipId = await _send('admin.chip_id', '0032010000');
    _expect(chipId.data.isNotEmpty, 'Empty chip ID');

    await _send('admin.verify_default_pin', _defaultAdminPin);
    final config = await _send('admin.config', '0042000000');
    _functionSet = CanoKey.functionSetFromFirmwareVersion(actualVersion);
    final minimumConfigBytes = switch (_functionSet) {
      FunctionSetVersion.v1 => 7,
      FunctionSetVersion.v2 => 5,
      FunctionSetVersion.v3 => 6,
      FunctionSetVersion.v4 => 5,
      FunctionSetVersion.v5 => 6,
    };
    _expect(
      config.data.length >= minimumConfigBytes * 2,
      'Config for ${_functionSet.name} is shorter than $minimumConfigBytes bytes',
    );
    final configBytes = _decodeHex(config.data, 'admin config');
    final booleanIndexes = switch (_functionSet) {
      FunctionSetVersion.v1 => const [0, 1, 2, 3, 4, 5],
      FunctionSetVersion.v2 => const [0, 1, 2, 3, 4],
      FunctionSetVersion.v3 => const [0, 1, 2, 3, 4, 5],
      FunctionSetVersion.v4 => const [0, 2, 3, 4],
      FunctionSetVersion.v5 => const [0, 2, 3, 4],
    };
    for (final index in booleanIndexes) {
      _expect(
        configBytes[index] == 0 || configBytes[index] == 1,
        'Admin config byte $index is not boolean: ${configBytes[index]}',
      );
    }
    _initialNdefReadonly = configBytes[2] == 1;

    final initialLed = configBytes[0];
    final toggledLed = initialLed == 0 ? 1 : 0;
    await _send('admin.led.toggle', '004001${_hexByte(toggledLed)}');
    var changedConfig = await _send('admin.config_after_led_toggle', '0042000000');
    _expect(
      _decodeHex(changedConfig.data, 'admin config after LED toggle')[0] ==
          toggledLed,
      'LED configuration did not change',
    );
    await _send('admin.led.restore', '004001${_hexByte(initialLed)}');
    changedConfig = await _send('admin.config_after_led_restore', '0042000000');
    _expect(
      _decodeHex(changedConfig.data, 'admin config after LED restore')[0] ==
          initialLed,
      'LED configuration was not restored',
    );

    if (_functionSet.index >= FunctionSetVersion.v4.index) {
      final nfc = await _send('admin.nfc_enabled', '0014000000');
      _expect(nfc.data.length == 2, 'NFC state must contain one byte');
      final initialNfc = int.parse(nfc.data, radix: 16);
      _expect(initialNfc == 0 || initialNfc == 1, 'Invalid NFC state');
      final toggledNfc = initialNfc == 0 ? 1 : 0;
      await _send('admin.nfc_toggle', '001401${_hexByte(toggledNfc)}');
      final changedNfc = await _send(
        'admin.nfc_after_toggle',
        '0014000000',
      );
      _expect(
        int.parse(changedNfc.data, radix: 16) == toggledNfc,
        'NFC state did not change',
      );
      await _send('admin.nfc_restore', '001401${_hexByte(initialNfc)}');
      final restoredNfc = await _send(
        'admin.nfc_after_restore',
        '0014000000',
      );
      _expect(
        int.parse(restoredNfc.data, radix: 16) == initialNfc,
        'NFC state was not restored',
      );
    }
    if (_functionSet == FunctionSetVersion.v5) {
      final storage = await _send('admin.storage_usage', '0041000002');
      _expect(storage.data.length == 4, 'Storage usage must contain two bytes');
      final storageBytes = _decodeHex(storage.data, 'storage usage');
      _expect(
        storageBytes[0] <= storageBytes[1],
        'Used storage exceeds total storage',
      );

      final featureMask = configBytes[5];
      final toggledMask = featureMask ^ 0x01;
      await _send(
        'admin.pass_switch.toggle',
        '004006${_hexByte(toggledMask)}',
      );
      changedConfig = await _send(
        'admin.config_after_pass_switch_toggle',
        '0042000000',
      );
      _expect(
        _decodeHex(changedConfig.data, 'config after Pass toggle')[5] ==
            toggledMask,
        'Pass feature switch did not change',
      );
      await _send(
        'admin.pass_switch.restore',
        '004006${_hexByte(featureMask)}',
      );
      changedConfig = await _send(
        'admin.config_after_pass_switch_restore',
        '0042000000',
      );
      _expect(
        _decodeHex(changedConfig.data, 'config after Pass restore')[5] ==
            featureMask,
        'Pass feature switch was not restored',
      );
    }
  }

  Future<void> _openPgpApplet() async {
    await _send('openpgp.select', '00A4040006D27600012401');
    final application = await _sendChained(
      'openpgp.application_data',
      '00CA006E00',
      commandClass: '00',
    );
    _expect(application.data.isNotEmpty, 'OpenPGP application data is empty');

    final aid = await _send('openpgp.aid', '00CA004F00');
    _expect(aid.data.length == 32, 'OpenPGP AID must contain 16 bytes');
    _expect(
      aid.data.toUpperCase().startsWith('D27600012401'),
      'Unexpected OpenPGP AID',
    );

    final pinStatus = await _send('openpgp.pin_status', '00CA00C400');
    _expect(
      pinStatus.data.length == 14,
      'OpenPGP PIN status must contain seven bytes',
    );
    final fingerprints = await _send(
      'openpgp.fingerprints',
      '00CA00C500',
      acceptedStatusWords: const {'9000', '6A88'},
    );
    if (fingerprints.statusWord == '9000') {
      _expect(
        fingerprints.data.length == 120,
        'OpenPGP fingerprints must contain 60 bytes',
      );
    }
    final generationTimes = await _send(
      'openpgp.generation_times',
      '00CA00CD00',
      acceptedStatusWords: const {'9000', '6A88'},
    );
    if (generationTimes.statusWord == '9000') {
      _expect(
        generationTimes.data.length == 24,
        'OpenPGP generation times must contain 12 bytes',
      );
    }

    if (_functionSet.index >= FunctionSetVersion.v4.index) {
      final challenge = await _send('openpgp.challenge', '0084000008');
      _expect(challenge.data.length == 16, 'OpenPGP challenge must be 8 bytes');
    }

    final cardInfo = await _openPgpClient.readCardInfo();
    _expect(
      cardInfo.version.isNotEmpty,
      'Console parsed an empty OpenPGP version',
    );
    _expect(
      cardInfo.serialNumber.length == 8,
      'Console parsed an invalid OpenPGP serial number',
    );
    _expect(
      cardInfo.pinState.userRetries != null &&
          cardInfo.pinState.adminRetries != null,
      'Console did not parse OpenPGP PIN retries',
    );
    _expect(
      cardInfo.keySlots.length == OpenPgpKeyType.values.length,
      'Console did not parse every OpenPGP key slot',
    );
    stdout.writeln('ok: openpgp.client.read_card_info');

    _expect(
      await _openPgpClient.changeUserPin(
        _defaultOpenPgpUserPin,
        _alternateOpenPgpUserPin,
      ),
      'Console failed to change the OpenPGP user PIN',
    );
    _expect(
      await _openPgpClient.changeUserPin(
        _alternateOpenPgpUserPin,
        _defaultOpenPgpUserPin,
      ),
      'Console failed to restore the OpenPGP user PIN',
    );
    _expect(
      await _openPgpClient.changeAdminPin(
        _defaultOpenPgpAdminPin,
        _alternateOpenPgpAdminPin,
      ),
      'Console failed to change the OpenPGP admin PIN',
    );
    _expect(
      await _openPgpClient.changeAdminPin(
        _alternateOpenPgpAdminPin,
        _defaultOpenPgpAdminPin,
      ),
      'Console failed to restore the OpenPGP admin PIN',
    );
    stdout.writeln('ok: openpgp.client.change_and_restore_pins');
  }

  Future<void> _pivApplet() async {
    await _send('piv.select', '00A4040005A000000308');

    final version = await _send('piv.version', '00FD000000');
    _expect(version.data.length == 6, 'PIV version must contain three bytes');
    final serial = await _send('piv.serial', '00F8000000');
    _expect(
      serial.data.toUpperCase() == _adminSerial.toUpperCase(),
      'PIV and Admin serial numbers differ',
    );

    await _send(
      'piv.pin_retries_before_verify',
      '0020008000',
      acceptedStatusWords: const {'63C3'},
    );
    await _send('piv.verify_default_pin', '0020008008$_defaultPivPin');
    await _send('piv.pin_verified', '0020008000');

    await _send(
      'piv.change_pin',
      '0024008010$_defaultPivPin$_alternatePivPin',
    );
    await _send('piv.verify_alternate_pin', '0020008008$_alternatePivPin');
    await _send(
      'piv.restore_pin',
      '0024008010$_alternatePivPin$_defaultPivPin',
    );
    await _send('piv.logout', '0020FF8000');
    await _send(
      'piv.pin_retries_after_logout',
      '0020008000',
      acceptedStatusWords: const {'63C3'},
    );

    final firmware = FirmwareVersion.parse(expectedVersion);
    if (firmware.compareTo(const FirmwareVersion(2, 0, 0)) >= 0) {
      for (final slot in const [0x80, 0x81, 0x9B]) {
        final metadata = await _send(
          'piv.metadata_${slot.toRadixString(16)}',
          '00F700${_hexByte(slot)}00',
        );
        final info = SlotInfo.parse(
          slot,
          _decodeHex(metadata.data, 'PIV metadata for slot $slot'),
        );
        _expect(info.number == slot, 'PIV metadata returned the wrong slot');
        if (slot == 0x80 || slot == 0x81) {
          _expect(info.retriesCount > 0, 'PIV slot $slot has no retry limit');
          _expect(
            info.remainingCount <= info.retriesCount,
            'PIV slot $slot remaining retries exceed its limit',
          );
        }
      }
    }

    final algorithmExtensions = await _send(
      'piv.algorithm_extensions',
      '00EE010000',
      acceptedStatusWords: const {'9000', '6982', '6D00'},
    );
    if (algorithmExtensions.statusWord == '9000') {
      PivAlgorithmExtensionConfig.decode(
        _decodeHex(algorithmExtensions.data, 'PIV algorithm extensions'),
      );
    }
  }

  Future<void> _oathApplet() async {
    final select = await _send('oath.select', '00A4040007A0000005272101');
    final legacy = select.data.isEmpty;
    if (!legacy) {
      final selectData = TLV.parse(_decodeHex(select.data, 'OATH select'));
      _expect(selectData.containsKey(0x79), 'OATH select has no version');
      _expect(selectData.containsKey(0x71), 'OATH select has no device ID');
    }

    const account = 'Console:USBIP';
    final accountBytes = utf8.encode(account);
    final name = _tlv(0x71, accountBytes);
    final secret = List<int>.generate(20, (index) => index + 1);
    final credential = [
      ...name,
      ..._tlv(0x73, [0x21, 0x06, ...secret]),
    ];
    await _send('oath.put', _command('00010000', credential));
    await _send(
      'oath.reject_duplicate',
      _command('00010000', credential),
      acceptedStatusWords: const {'6985'},
    );

    const challenge = [0, 0, 0, 0, 0, 0, 0, 1];
    final calculateData = [...name, ..._tlv(0x74, challenge)];
    final calculation = await _send(
      'oath.calculate',
      _command(legacy ? '00040000' : '00A20001', calculateData),
    );
    final calculationBytes = _decodeHex(calculation.data, 'OATH calculation');
    _expect(
      calculationBytes.length == 7 &&
          calculationBytes[0] == 0x76 &&
          calculationBytes[1] == 5,
      'Unexpected OATH calculation response',
    );

    final listed = await _sendOathCalculateAll(legacy, challenge);
    _expect(
      _containsBytes(listed, name),
      'OATH calculation list does not contain the added account',
    );

    await _send('oath.delete', _command('00020000', name));
    final empty = await _sendOathCalculateAll(legacy, challenge);
    _expect(
      !_containsBytes(empty, name),
      'OATH account was not deleted',
    );
  }

  Future<List<int>> _sendOathCalculateAll(
    bool legacy,
    List<int> challenge,
  ) async {
    final command = _command(
      legacy ? '00050000' : '00A40001',
      _tlv(0x74, challenge),
    );
    final getRemaining = legacy ? '00060000FF' : '00A50000FF';
    final data = <int>[];
    var response = await _send(
      'oath.calculate_all',
      command,
      allowMoreData: true,
    );

    while (response.statusWord == '9000' ||
        response.statusWord.startsWith('61')) {
      data.addAll(_decodeHex(response.data, 'OATH calculation list'));
      response = await _send(
        'oath.calculate_all.remaining',
        getRemaining,
        acceptedStatusWords: const {'9000', '6985'},
        allowMoreData: true,
      );
      if (response.statusWord == '6985') return data;
    }
    throw StateError(
      'OATH calculation list failed with ${response.statusWord}',
    );
  }

  Future<void> _ndefApplet() async {
    await _send('ndef.select', '00A4040007D2760000850101');
    await _send('ndef.select_capability_container', '00A4000C02E103');
    final capability = await _send(
      'ndef.read_capability_container',
      '00B000000F',
    );
    final bytes = _decodeHex(capability.data, 'NDEF capability container');
    _expect(bytes.length == 15, 'NDEF capability container must be 15 bytes');
    _expect(
      bytes[7] == 0x04 && bytes[8] == 0x06,
      'NDEF capability container has an unexpected file descriptor',
    );
    _expect(bytes[14] == 0, 'Fresh NDEF file should be writable');

    await _send('ndef.select_data_file', '00A4000C020001');
    final length = await _send('ndef.read_length', '00B0000002');
    _expect(length.data.length == 4, 'NDEF length must contain two bytes');

    const payload = [
      0xD1,
      0x01,
      0x0B,
      0x55,
      0x04,
      0x74,
      0x65,
      0x73,
      0x74,
      0x2E,
      0x6C,
      0x6F,
      0x63,
      0x61,
      0x6C,
    ];
    await _send(
      'ndef.clear_length_before_write',
      _command('00D60000', const [0, 0]),
    );
    await _send('ndef.write_payload', _command('00D60002', payload));
    await _send(
      'ndef.commit_length',
      _command('00D60000', [payload.length >> 8, payload.length & 0xff]),
    );
    final writtenLength = await _send('ndef.read_written_length', '00B0000002');
    _expect(
      writtenLength.data.toUpperCase() == '000F',
      'NDEF length did not match the written payload',
    );
    final writtenPayload = await _send(
      'ndef.read_written_payload',
      '00B00002${_hexByte(payload.length)}',
    );
    final writtenBytes = _decodeHex(
      writtenPayload.data,
      'written NDEF payload',
    );
    _expect(
      writtenBytes.length == payload.length &&
          writtenBytes
              .asMap()
              .entries
              .every((entry) => payload[entry.key] == entry.value),
      'NDEF payload did not round-trip',
    );

    await _selectAdminAndVerify();
    await _send('admin.ndef_readonly.enable', '00080100');
    await _send('ndef.select_for_readonly_test', '00A4040007D2760000850101');
    await _send('ndef.select_data_for_readonly_test', '00A4000C020001');
    await _send(
      'ndef.reject_write_when_readonly',
      _command('00D60000', const [0, 0]),
      acceptedStatusWords: const {'6982'},
    );

    await _selectAdminAndVerify();
    await _send(
      'admin.ndef_readonly.restore',
      _initialNdefReadonly ? '00080100' : '00080000',
    );
    await _send('admin.reset_ndef', '00070000');
    await _send('ndef.select_after_reset', '00A4040007D2760000850101');
    await _send('ndef.select_data_after_reset', '00A4000C020001');
    final resetLength = await _send('ndef.read_length_after_reset', '00B0000002');
    _expect(
      resetLength.data.length == 4,
      'Reset NDEF length must contain two bytes',
    );
  }

  Future<void> _webAuthnApplet() async {
    await _send('webauthn.select', '00A4040008A0000006472F0001');
    final getInfo = await _sendChained(
      'webauthn.get_info',
      '801000000104',
      commandClass: '80',
    );
    final bytes = _decodeHex(getInfo.data, 'WebAuthn getInfo');
    _expect(bytes.isNotEmpty, 'WebAuthn getInfo response is empty');
    _expect(
      bytes.first == 0,
      'WebAuthn getInfo returned CTAP status ${bytes.first}',
    );
    _expect(bytes.length > 1, 'WebAuthn getInfo returned no CBOR payload');
    final info = AuthenticatorInfo.decode(bytes.sublist(1));
    _expect(info.versions.isNotEmpty, 'WebAuthn reports no protocol versions');
    _expect(
      info.versions.contains('FIDO_2_0'),
      'WebAuthn does not advertise FIDO_2_0',
    );
    _expect(info.aaguid.length == 16, 'WebAuthn AAGUID must be 16 bytes');
    _expect(
      info.maxMsgSize == null || info.maxMsgSize! > 0,
      'WebAuthn max message size is invalid',
    );
    _expect(
      info.algorithms == null || info.algorithms!.isNotEmpty,
      'WebAuthn algorithms list is empty',
    );
  }

  Future<void> _passApplet() async {
    final functionSet = CanoKey.functionSetFromFirmwareVersion(expectedVersion);
    if (!CanoKey.functionSet(functionSet).contains(Func.pass)) {
      checks.add({'name': 'pass.read_slots', 'skipped': true});
      stdout.writeln(
        'skip: pass.read_slots (not supported by $expectedVersion)',
      );
      return;
    }

    await _send('pass.select_admin', _adminAid);
    await _send('pass.verify_default_pin', _defaultAdminPin);
    var slots = await _send('pass.read_slots', '0043000000');
    _expect(
      PassSlot.fromData(slots.data).length == 2,
      'Expected two Pass slots',
    );

    const password = 'console-usbip';
    final staticSlot = [
      0x02,
      password.length,
      ...utf8.encode(password),
      0x01,
    ];
    await _send('pass.write_short_static', _command('00440100', staticSlot));
    slots = await _send('pass.read_short_static', '0043000000');
    var parsedSlots = PassSlot.fromData(slots.data);
    _expect(
      parsedSlots[0].type == PassSlotType.static && parsedSlots[0].withEnter,
      'Pass short slot did not store the static password configuration',
    );

    await _send(
      'pass.write_long_static',
      _command('00440200', [
        0x02,
        password.length,
        ...utf8.encode(password),
        0x00,
      ]),
    );
    slots = await _send('pass.read_long_static', '0043000000');
    parsedSlots = PassSlot.fromData(slots.data);
    _expect(
      parsedSlots[1].type == PassSlotType.static &&
          !parsedSlots[1].withEnter,
      'Pass long slot did not store the static password configuration',
    );

    if (_functionSet == FunctionSetVersion.v5) {
      await _send(
        'pass.write_short_hmac_sha1',
        _command('00440100', [
          0x03,
          0x14,
          ...List<int>.generate(20, (index) => 0xA0 + index),
        ]),
      );
      slots = await _send('pass.read_short_hmac_sha1', '0043000000');
      parsedSlots = PassSlot.fromData(slots.data);
      _expect(
        parsedSlots[0].type == PassSlotType.hmacSha1,
        'Pass short slot did not store the HMAC-SHA1 configuration',
      );
    }

    await _send(
      'pass.clear_short',
      _command('00440100', const [0x00]),
    );
    await _send('pass.clear_long', _command('00440200', const [0x00]));
    slots = await _send('pass.read_cleared_slots', '0043000000');
    parsedSlots = PassSlot.fromData(slots.data);
    _expect(
      parsedSlots.every((slot) => slot.type == PassSlotType.none),
      'Pass slots were not cleared',
    );
  }

  Future<void> _selectAdminAndVerify() async {
    await _send('admin.select_for_operation', _adminAid);
    await _send('admin.verify_for_operation', _defaultAdminPin);
  }
}

class _CcidApduTransport implements ApduTransport {
  _CcidApduTransport(this.card, {required this.onResponse});

  final CcidCard card;
  final void Function(ApduResponse response) onResponse;

  @override
  Future<String> transceive(String capdu) async {
    final raw = await card.transceive(capdu);
    if (raw == null) {
      throw StateError('OpenPGP client returned no response');
    }
    onResponse(ApduResponse.parse(raw));
    return raw;
  }
}

void main() {
  debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Console communicates with the virtual CanoKey over CCID', _runSmoke);
}

Future<void> _runSmoke() async {
  final environment = Platform.environment;
  _expect(environment['CANOKEY_USBIP'] == '1', 'CANOKEY_USBIP must be 1');
  final expectedVersion = _requiredEnvironment('CANOKEY_FIRMWARE_VERSION');
  final expectedReader = _requiredEnvironment('CANOKEY_PCSC_READER');
  final outputDirectory = Directory(
    _requiredEnvironment('CANOKEY_TEST_OUTPUT'),
  );

  final report = <String, Object?>{
    'firmware_version': expectedVersion,
    'core_ref': environment['CANOKEY_CORE_REF'],
    'core_sha': environment['CANOKEY_CORE_SHA'],
    'usbip_sha': environment['CANOKEY_USBIP_SHA'],
    'reader': expectedReader,
  };

  CcidCard? card;
  ConsoleSmoke? smoke;
  Object? failure;
  StackTrace? failureStack;
  try {
    final ccid = Ccid();
    final readers = await ccid.listReaders();
    _expect(
      readers.contains(expectedReader),
      'Expected reader "$expectedReader"; found ${readers.join(', ')}',
    );
    card = await ccid.connect(expectedReader);
    smoke = ConsoleSmoke(card: card, expectedVersion: expectedVersion);
    await smoke.run();
    report['result'] = 'passed';
    stdout.writeln('Console USB/IP smoke passed for firmware $expectedVersion');
  } catch (error, stackTrace) {
    failure = error;
    failureStack = stackTrace;
    report['result'] = 'failed';
    report['error'] = error.toString();
  } finally {
    report['checks'] = smoke?.checks ?? const [];
    report['check_count'] = smoke?.checks.length ?? 0;
    if (card != null) {
      try {
        await card.disconnect();
      } catch (error) {
        report['disconnect_error'] = error.toString();
        failure ??= error;
        failureStack ??= StackTrace.current;
        report['result'] = 'failed';
      }
    }
    outputDirectory.createSync(recursive: true);
    File('${outputDirectory.path}/console-smoke.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(report)}\n',
    );
  }

  if (failure != null) {
    Error.throwWithStackTrace(failure, failureStack!);
  }
}

String _requiredEnvironment(String name) {
  final value = Platform.environment[name];
  if (value == null || value.isEmpty) {
    throw StateError('$name is required');
  }
  return value;
}

String _decodeText(String value, String name) {
  try {
    return utf8.decode(_decodeHex(value, name));
  } on FormatException catch (error) {
    throw FormatException('Invalid $name: $error');
  }
}

List<int> _decodeHex(String value, String name) {
  if (value.length.isOdd || !RegExp(r'^[0-9a-fA-F]*$').hasMatch(value)) {
    throw FormatException('Invalid hexadecimal $name');
  }
  return [
    for (var offset = 0; offset < value.length; offset += 2)
      int.parse(value.substring(offset, offset + 2), radix: 16),
  ];
}

String _hexByte(int value) {
  if (value < 0 || value > 0xff) {
    throw RangeError.range(value, 0, 0xff, 'value');
  }
  return value.toRadixString(16).padLeft(2, '0').toUpperCase();
}

String _encodeHex(Iterable<int> values) {
  return values.map(_hexByte).join();
}

String _command(String header, List<int> data) {
  if (header.length != 8) {
    throw ArgumentError.value(header, 'header', 'APDU header must be 4 bytes');
  }
  return '${header.toUpperCase()}${_hexByte(data.length)}${_encodeHex(data)}';
}

List<int> _tlv(int tag, List<int> value) {
  return [tag, value.length, ...value];
}

bool _containsBytes(List<int> data, List<int> needle) {
  if (needle.isEmpty) return true;
  for (var offset = 0; offset <= data.length - needle.length; offset++) {
    var matches = true;
    for (var index = 0; index < needle.length; index++) {
      if (data[offset + index] != needle[index]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
