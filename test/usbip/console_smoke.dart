import 'dart:convert';
import 'dart:io';

import 'package:canokey_console/helper/utils/admin_card.dart';
import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/ctap_transmitter.dart';
import 'package:canokey_console/helper/utils/ndef_card.dart';
import 'package:canokey_console/helper/utils/oath_card.dart';
import 'package:canokey_console/helper/utils/openpgp_card.dart';
import 'package:canokey_console/helper/utils/pass_card.dart';
import 'package:canokey_console/helper/utils/piv_card.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:canokey_console/models/openpgp.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:ccid/ccid.dart';
import 'package:fido2/fido2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _defaultAdminPin = '123456';
const _defaultPivPin = '123456';
const _alternatePivPin = '654321';
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
    _adminClient = AdminCardClient(
      transport: _clientTransport('admin'),
    );
    _openPgpClient = OpenPgpCardClient(
      transport: _clientTransport('openpgp'),
    );
    _ndefClient = NdefCardClient(
      transport: _clientTransport('ndef'),
    );
    _oathClient = OathCardClient(
      transport: _clientTransport('oath'),
    );
    _passClient = PassCardClient(
      transport: _clientTransport('pass'),
    );
    _pivClient = PivCardClient(
      transport: _clientTransport('piv'),
    );
    _webAuthnTransmitter = CtapTransmitter(
      transport: _clientTransport('webauthn'),
    );
  }

  final CcidCard card;
  final String expectedVersion;
  final List<Map<String, Object?>> checks = [];
  late final AdminCardClient _adminClient;
  late final OpenPgpCardClient _openPgpClient;
  late final NdefCardClient _ndefClient;
  late final OathCardClient _oathClient;
  late final PassCardClient _passClient;
  late final PivCardClient _pivClient;
  late final CtapTransmitter _webAuthnTransmitter;
  late FunctionSetVersion _functionSet;
  late String _adminSerial;
  late bool _initialNdefReadonly;

  ApduTransport _clientTransport(String applet) {
    return _CcidApduTransport(
      card,
      onResponse: (response) {
        checks.add({
          'name': '$applet.client.transceive',
          'status_word': response.statusWord,
          'response_bytes': response.data.length ~/ 2,
        });
      },
    );
  }

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
    await _adminClient.select();
    final actualVersion = await _adminClient.readFirmwareVersion();
    _expect(
      actualVersion == expectedVersion,
      'Expected firmware $expectedVersion, got $actualVersion',
    );

    _expect((await _adminClient.readModel()).isNotEmpty, 'Empty model');

    _adminSerial = await _adminClient.readSerial();
    _expect(_adminSerial.length == 8, 'Serial number must contain four bytes');

    _expect((await _adminClient.readChipId()).isNotEmpty, 'Empty chip ID');

    _expect(
      await _adminClient.verifyPin(_defaultAdminPin),
      'Console failed to verify the default admin PIN',
    );
    _functionSet = CanoKey.functionSetFromFirmwareVersion(actualVersion);
    final minimumConfigBytes = switch (_functionSet) {
      FunctionSetVersion.v1 => 7,
      FunctionSetVersion.v2 => 5,
      FunctionSetVersion.v3 => 6,
      FunctionSetVersion.v4 => 5,
      FunctionSetVersion.v5 => 6,
    };
    final configBytes = await _adminClient.readConfig();
    _expect(
      configBytes.length >= minimumConfigBytes,
      'Config for ${_functionSet.name} is shorter than $minimumConfigBytes bytes',
    );
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
    await _adminClient.writeConfigByte(1, toggledLed);
    var changedConfig = await _adminClient.readConfig();
    _expect(
      changedConfig[0] == toggledLed,
      'LED configuration did not change',
    );
    await _adminClient.writeConfigByte(1, initialLed);
    changedConfig = await _adminClient.readConfig();
    _expect(
      changedConfig[0] == initialLed,
      'LED configuration was not restored',
    );

    if (_functionSet.index >= FunctionSetVersion.v4.index) {
      final initialNfc = await _adminClient.readNfcEnabled();
      await _adminClient.setNfcEnabled(!initialNfc);
      _expect(
        await _adminClient.readNfcEnabled() == !initialNfc,
        'NFC state did not change',
      );
      await _adminClient.setNfcEnabled(initialNfc);
      _expect(
        await _adminClient.readNfcEnabled() == initialNfc,
        'NFC state was not restored',
      );
    }
    if (_functionSet == FunctionSetVersion.v5) {
      final storage = await _adminClient.readStorageUsage();
      _expect(
        storage.usedKiB <= storage.totalKiB,
        'Used storage exceeds total storage',
      );

      final featureMask = configBytes[5];
      final toggledMask = featureMask ^ 0x01;
      await _adminClient.writeConfigByte(6, toggledMask);
      changedConfig = await _adminClient.readConfig();
      _expect(
        changedConfig[5] == toggledMask,
        'Pass feature switch did not change',
      );
      await _adminClient.writeConfigByte(6, featureMask);
      changedConfig = await _adminClient.readConfig();
      _expect(
        changedConfig[5] == featureMask,
        'Pass feature switch was not restored',
      );
    }
    stdout.writeln('ok: admin.client.read_and_restore_config');
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
    await _pivClient.select();
    _expect(
      (await _pivClient.readVersion()).length == 3,
      'PIV version must contain three bytes',
    );
    _expect(
      await _pivClient.readSerial() == _adminSerial.toUpperCase(),
      'PIV and Admin serial numbers differ',
    );

    var response = ApduResponse.parse(await _pivClient.readPinRetries());
    _expect(
      response.statusWord == '63C3',
      'Console parsed unexpected PIV PIN retries',
    );
    _expect(
      await _pivClient.verifyPin(_defaultPivPin),
      'Console failed to verify the default PIV PIN',
    );
    response = ApduResponse.parse(await _pivClient.readPinRetries());
    _expect(response.statusWord == '9000',
        'Console did not retain PIV PIN verification');

    _expect(
      await _pivClient.changePin(_defaultPivPin, _alternatePivPin),
      'Console failed to change the PIV PIN',
    );
    _expect(
      await _pivClient.verifyPin(_alternatePivPin),
      'Console failed to verify the alternate PIV PIN',
    );
    _expect(
      await _pivClient.changePin(_alternatePivPin, _defaultPivPin),
      'Console failed to restore the PIV PIN',
    );
    await _pivClient.logout();
    response = ApduResponse.parse(await _pivClient.readPinRetries());
    _expect(
      response.statusWord == '63C3',
      'Console did not observe PIV logout',
    );

    final firmware = FirmwareVersion.parse(expectedVersion);
    if (firmware.compareTo(const FirmwareVersion(2, 0, 0)) >= 0) {
      for (final slot in const [0x80, 0x81, 0x9B]) {
        final metadata = await _pivClient.readMetadata(slot);
        _expect(
          metadata != null,
          'Console could not parse PIV metadata for $slot',
        );
        final info = metadata!;
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

    await _pivClient.readAlgorithmExtensions();
    stdout.writeln('ok: piv.client.read_change_and_restore');
  }

  Future<void> _oathApplet() async {
    final selection = await _oathClient.select();
    if (selection.version != OathVersion.legacy) {
      _expect(selection.info.containsKey(0x79), 'OATH select has no version');
      _expect(selection.info.containsKey(0x71), 'OATH select has no device ID');
    }

    const account = 'Console:USBIP';
    final secret = _encodeHex(
      List<int>.generate(20, (index) => index + 1),
    );
    var response = ApduResponse.parse(
      await _oathClient.put(
        name: account,
        secretHex: secret,
        type: OathType.totp,
        algorithm: OathAlgorithm.sha1,
        digits: 6,
      ),
    );
    _expect(
        response.statusWord == '9000', 'Console failed to add OATH account');
    response = ApduResponse.parse(
      await _oathClient.put(
        name: account,
        secretHex: secret,
        type: OathType.totp,
        algorithm: OathAlgorithm.sha1,
        digits: 6,
      ),
    );
    _expect(
      response.statusWord == '6985',
      'Console did not detect a duplicate OATH account',
    );

    const challenge = '0000000000000001';
    final calculation = ApduResponse.parse(
      await _oathClient.calculate(
        name: account,
        type: OathType.totp,
        challengeHex: challenge,
      ),
    );
    final calculationBytes = _decodeHex(calculation.data, 'OATH calculation');
    _expect(
      calculationBytes.length == 7 &&
          calculationBytes[0] == 0x76 &&
          calculationBytes[1] == 5,
      'Unexpected OATH calculation response',
    );

    final listed = ApduResponse.parse(
      await _oathClient.calculateAll(challenge),
    );
    final accountTlv = _tlv(0x71, utf8.encode(account));
    _expect(
      _containsBytes(
        _decodeHex(listed.data, 'OATH calculation list'),
        accountTlv,
      ),
      'OATH calculation list does not contain the added account',
    );

    response = ApduResponse.parse(await _oathClient.delete(account));
    _expect(
        response.statusWord == '9000', 'Console failed to delete OATH account');
    final empty = ApduResponse.parse(
      await _oathClient.calculateAll(challenge),
    );
    _expect(
      !_containsBytes(
        _decodeHex(empty.data, 'empty OATH calculation list'),
        accountTlv,
      ),
      'OATH account was not deleted',
    );
    stdout.writeln('ok: oath.client.add_calculate_delete');
  }

  Future<void> _ndefApplet() async {
    final initial = await _ndefClient.read();
    _expect(initial != null, 'Console could not select the NDEF applet');
    _expect(
      initial!.maxMessageLength > 0,
      'Console parsed an invalid NDEF capacity',
    );
    _expect(!initial.readOnly, 'Fresh NDEF file should be writable');
    final initialMessage = Uint8List.fromList(initial.message);

    final payload = Uint8List.fromList(const [
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
    ]);
    _expect(
      await _ndefClient.write(payload),
      'Console could not write the NDEF applet',
    );
    final written = await _ndefClient.read();
    _expect(
      written != null && _bytesEqual(written.message, payload),
      'NDEF payload did not round-trip',
    );
    stdout.writeln('ok: ndef.client.read_write');

    await _selectAdminAndVerify();
    await _adminClient.setNdefReadOnly(true);
    var rejectedReadOnlyWrite = false;
    try {
      await _ndefClient.write(payload);
    } on NdefReadOnlyException {
      rejectedReadOnlyWrite = true;
    }
    _expect(rejectedReadOnlyWrite, 'Console accepted a read-only NDEF write');

    await _selectAdminAndVerify();
    await _adminClient.setNdefReadOnly(_initialNdefReadonly);
    await _adminClient.resetNdef();
    final reset = await _ndefClient.read();
    _expect(
      reset != null && _bytesEqual(reset.message, initialMessage),
      'Console did not observe the initial NDEF content after reset',
    );
    stdout.writeln('ok: ndef.client.readonly_and_reset');
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

    final clientResponse = await _webAuthnTransmitter.transceive([0x04]);
    _expect(
      clientResponse.status == 0,
      'Console WebAuthn transmitter returned CTAP status '
      '${clientResponse.status}',
    );
    final clientInfo = AuthenticatorInfo.decode(clientResponse.data);
    _expect(
      clientInfo.versions.contains('FIDO_2_0'),
      'Console WebAuthn transmitter did not parse FIDO_2_0',
    );
    stdout.writeln('ok: webauthn.client.get_info');
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

    await _selectAdminAndVerify();
    var slots = await _passClient.readSlots();
    _expect(slots.length == 2, 'Expected two Pass slots');

    const password = 'console-usbip';
    _expect(
      await _passClient.setSlot(1, PassSlotType.static, password, true),
      'Console failed to configure the short Pass slot',
    );
    slots = await _passClient.readSlots();
    _expect(
      slots[0].type == PassSlotType.static && slots[0].withEnter,
      'Pass short slot did not store the static password configuration',
    );

    _expect(
      await _passClient.setSlot(2, PassSlotType.static, password, false),
      'Console failed to configure the long Pass slot',
    );
    slots = await _passClient.readSlots();
    _expect(
      slots[1].type == PassSlotType.static && !slots[1].withEnter,
      'Pass long slot did not store the static password configuration',
    );

    if (_functionSet == FunctionSetVersion.v5) {
      final secret = _encodeHex(
        List<int>.generate(20, (index) => 0xA0 + index),
      );
      _expect(
        await _passClient.setSlot(1, PassSlotType.hmacSha1, secret, false),
        'Console failed to configure the HMAC-SHA1 Pass slot',
      );
      slots = await _passClient.readSlots();
      _expect(
        slots[0].type == PassSlotType.hmacSha1,
        'Pass short slot did not store the HMAC-SHA1 configuration',
      );
    }

    _expect(
      await _passClient.setSlot(1, PassSlotType.none, '', false),
      'Console failed to clear the short Pass slot',
    );
    _expect(
      await _passClient.setSlot(2, PassSlotType.none, '', false),
      'Console failed to clear the long Pass slot',
    );
    slots = await _passClient.readSlots();
    _expect(
      slots.every((slot) => slot.type == PassSlotType.none),
      'Pass slots were not cleared',
    );
    stdout.writeln('ok: pass.client.configure_and_clear');
  }

  Future<void> _selectAdminAndVerify() async {
    await _adminClient.select();
    _expect(
      await _adminClient.verifyPin(_defaultAdminPin),
      'Console failed to verify the admin PIN',
    );
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
      throw StateError('Client APDU returned no response');
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

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
