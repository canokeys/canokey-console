import 'dart:convert';
import 'dart:io';

import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:ccid/ccid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _adminAid = '00A4040005F000000000';
const _defaultAdminPin = '0020000006313233343536';

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
  ConsoleSmoke({required this.card, required this.expectedVersion});

  final CcidCard card;
  final String expectedVersion;
  final List<Map<String, Object?>> checks = [];

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

    final chipId = await _send('admin.chip_id', '0032010000');
    _expect(chipId.data.isNotEmpty, 'Empty chip ID');

    await _send('admin.verify_default_pin', _defaultAdminPin);
    final config = await _send('admin.config', '0042000000');
    final functionSet = CanoKey.functionSetFromFirmwareVersion(actualVersion);
    final minimumConfigBytes = switch (functionSet) {
      FunctionSetVersion.v1 => 7,
      FunctionSetVersion.v2 => 5,
      FunctionSetVersion.v3 => 6,
      FunctionSetVersion.v4 => 5,
      FunctionSetVersion.v5 => 5,
    };
    _expect(
      config.data.length >= minimumConfigBytes * 2,
      'Config for ${functionSet.name} is shorter than $minimumConfigBytes bytes',
    );

    if (functionSet.index >= FunctionSetVersion.v4.index) {
      final nfc = await _send('admin.nfc_enabled', '0014000000');
      _expect(
        nfc.data.isEmpty || nfc.data.length == 2,
        'NFC state must contain at most one byte',
      );
    }
    if (functionSet == FunctionSetVersion.v5) {
      final storage = await _send('admin.storage_usage', '0041000002');
      _expect(storage.data.length == 4, 'Storage usage must contain two bytes');
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
  }

  Future<void> _pivApplet() async {
    await _send('piv.select', '00A4040005A000000308');
  }

  Future<void> _oathApplet() async {
    await _send('oath.select', '00A4040007A0000005272101');
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

    await _send('ndef.select_data_file', '00A4000C020001');
    final length = await _send('ndef.read_length', '00B0000002');
    _expect(length.data.length == 4, 'NDEF length must contain two bytes');
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
    final slots = await _send('pass.read_slots', '0043000000');
    _expect(
      PassSlot.fromData(slots.data).length == 2,
      'Expected two Pass slots',
    );
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

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
