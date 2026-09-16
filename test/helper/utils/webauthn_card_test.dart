@Tags(['native'])
library;

import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/helper/utils/webauthn_card.dart';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:flutter_test/flutter_test.dart';

// Golden fixtures are the upstream canokey-ctap known answers
// (crates/canokey-ctap/tests/client_pin.rs, credmgmt.rs), also pinned by the
// facade tests in rust/src/api/protocol.rs. The ephemeral scalar is generated
// by the facade CSPRNG, so ClientPIN commands are asserted by shape only; the
// fixture V1 token ciphertext decrypts to a garbage but usable token.
const _select = '00A4040008A0000006472F0001';
const _peerKeyAgreement =
    'a101a5010203381820012158200d0918a04198474605615b6df90fdcb34791fb3ecb822f4b26eb6e4fc4511b9d22582019b90c1b83c0c35cfbbb31ead32bb52ae33622f57e3cc1638097ce97f430baba';
const _tokenCiphertextV1 =
    'b98cc635132fa3ea8c191b7a4aa3e093ce926c35488221b4684fce766f3b14b0';
const _rpBegin =
    'a303a26269646b6578616d706c652e636f6d646e616d65674578616d706c65045820a0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebf0502';
const _rpNext =
    'a203a1626964696f746865722e6f7267045820c0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedf';
const _credentialMeta =
    'a406a26269644405060708646e616d6565616c69636507a2626964440102030464747970656a7075626c69632d6b6579090118803830';

/// getInfo fixture: versions [FIDO_2_0, FIDO_2_1], credMgmt true, clientPin
/// false, forcePinChange true, minPinLength 4, pinUvAuthProtocols [1, 2].
const _getInfoPayload = 'a6'
    '0182684649444f5f325f30684649444f5f325f31'
    '0350244eb29ee0904e4981fe1f20f8d3b8f4'
    '04a362726bf568637265644d676d74f569636c69656e7450696ef4'
    '06820102'
    '0cf5'
    '0d04';

String _ctapOk(String payload) => '00${payload}9000';

void main() {
  setUpAll(() => RustLib.init());
  tearDownAll(RustLib.dispose);

  test('getInfo parses tri-states, minPinLength and protocol versions',
      () async {
    final transport = _QueueApduTransport(['9000', _ctapOk(_getInfoPayload)]);
    await _withClient(transport, (client) async {
      final info = await client.getInfo();

      expect(info.credMgmt, isTrue);
      expect(info.clientPin, isFalse);
      expect(info.forcePinChange, isTrue);
      expect(info.minPinLength, 4);
      expect(info.pinUvAuthProtocols, [1, 2]);
      expect(info.pinProtocol, 2);
      expect(transport.commands, [_select, '801000000104']);
    });
  });

  test('getInfo keeps unadvertised fields absent', () async {
    final transport = _QueueApduTransport([
      '9000',
      _ctapOk('a20181684649444f5f325f300350244eb29ee0904e4981fe1f20f8d3b8f4'),
    ]);
    await _withClient(transport, (client) async {
      final info = await client.getInfo();

      expect(info.credMgmt, isNull);
      expect(info.clientPin, isNull);
      expect(info.forcePinChange, isNull);
      expect(info.minPinLength, isNull);
      expect(info.pinUvAuthProtocols, isEmpty);
      // No advertised pinUvAuthProtocols falls back to protocol V1.
      expect(info.pinProtocol, 1);
    });
  });

  test('every operation selects the FIDO2 applet itself', () async {
    final transport = _QueueApduTransport(
        ['9000', _ctapOk(_getInfoPayload), '9000', _ctapOk(_getInfoPayload)]);
    await _withClient(transport, (client) async {
      await client.getInfo();
      await client.getInfo();

      expect(transport.commands, [
        _select,
        '801000000104',
        _select,
        '801000000104',
      ]);
    });
  });

  test('an absent FIDO2 applet surfaces as UnsupportedDevice', () async {
    final transport = _QueueApduTransport(['6A82']);
    await _withClient(transport, (client) async {
      await expectLater(
        client.getInfo(),
        throwsA(isA<ProtocolException>().having(
          (error) => error.details.kind,
          'kind',
          'UnsupportedDevice',
        )),
      );
      expect(transport.commands, [_select]);
    });
  });

  test('a CTAP-level failure keeps the raw CTAP status byte', () async {
    final transport = _QueueApduTransport(['9000', '309000']);
    await _withClient(transport, (client) async {
      await expectLater(
        client.getInfo(),
        throwsA(isA<ProtocolException>()
            .having((e) => e.details.kind, 'kind', 'ConditionsNotSatisfied')
            .having((e) => e.details.statusWord, 'statusWord', 0x30)),
      );
    });
  });

  test('a malformed getInfo response is a parsing failure', () async {
    final transport = _QueueApduTransport([
      '9000',
      _ctapOk('a10350244eb29ee0904e4981fe1f20f8d3b8f4'),
    ]);
    await _withClient(transport, (client) async {
      await expectLater(
        client.getInfo(),
        throwsA(isA<ProtocolException>()
            .having((e) => e.details.kind, 'kind', 'InvalidResponse')
            .having((e) => e.details.phase, 'phase', 'Parsing')),
      );
    });
  });

  test('beginPinSession prefers V2 and drives the key agreement', () async {
    final transport =
        _QueueApduTransport(['9000', _ctapOk(_peerKeyAgreement)]);
    await _withClient(transport, (client) async {
      final session = await client.beginPinSession(_info(protocols: [1, 2]));

      expect(session.protocolVersion, 2);
      expect(transport.commands, [
        _select,
        '801000000606A201020202',
      ]);
      session.close();
    });
  });

  test('beginPinSession falls back to V1 and rejects short PINs before I/O',
      () async {
    final transport =
        _QueueApduTransport(['9000', _ctapOk(_peerKeyAgreement)]);
    await _withClient(transport, (client) async {
      final session = await client.beginPinSession(_info(protocols: [1]));

      expect(session.protocolVersion, 1);
      expect(transport.commands, [
        _select,
        '801000000606A201010202',
      ]);

      // PIN validation happens before any I/O.
      await expectLater(
        session.setPin('ab'),
        throwsA(isA<ProtocolException>()
            .having((e) => e.details.kind, 'kind', 'InvalidPin')),
      );
      expect(transport.commands, hasLength(2));

      // A closed session is inert.
      session.close();
      session.close();
      await expectLater(session.setPin('1234'), throwsStateError);
      expect(transport.commands, hasLength(2));
    });
  });

  test('setPin and changePin complete over the upstream wire', () async {
    // V1 setPin (zero IV by specification) then a V2 changePin; both carry
    // non-deterministic ciphertext, so only success is asserted.
    final transport = _QueueApduTransport([
      '9000', _ctapOk(_peerKeyAgreement), // V1 session
      '9000', '009000', // setPin
      '9000', _ctapOk(_peerKeyAgreement), // V2 session
      '9000', '009000', // changePin
    ]);
    await _withClient(transport, (client) async {
      final v1 = await client.beginPinSession(_info(protocols: [1]));
      await v1.setPin('1234');
      v1.close();

      final v2 = await client.beginPinSession(_info(protocols: [1, 2]));
      await v2.changePin('1234', '654321');
      v2.close();

      expect(transport.commands[2], _select);
      expect(transport.commands[3], startsWith('80100000'));
      expect(transport.commands[3], contains('06A5'));
      expect(transport.commands[6], _select);
      expect(transport.commands[7], contains('06A6'));
    });
  });

  test('PIN failures keep the raw CTAP status byte', () async {
    for (final (status, kind) in [(0x31, 'InvalidPin'), (0x32, 'PinBlocked')]) {
      final transport = _QueueApduTransport([
        '9000', _ctapOk(_peerKeyAgreement), // session
        '9000', '${status.toRadixString(16).padLeft(2, '0').toUpperCase()}9000',
      ]);
      await _withClient(transport, (client) async {
        final session = await client.beginPinSession(_info(protocols: [1]));
        await expectLater(
          session.getPinToken('1234'),
          throwsA(isA<ProtocolException>()
              .having((e) => e.details.kind, 'kind', kind)
              .having((e) => e.details.statusWord, 'statusWord', status)),
        );
        session.close();
      });
    }
  });

  test('token enumeration and deletion follow the golden transcript',
      () async {
    final transport = _QueueApduTransport([
      '9000', _ctapOk(_peerKeyAgreement), // session
      '9000', _ctapOk('a1025820$_tokenCiphertextV1'), // getPinToken
      '9000', _ctapOk(_rpBegin), _ctapOk(_rpNext), // enumerateRps
      '9000', _ctapOk(_credentialMeta), // enumerateCredentials
      '9000', '009000', // deleteCredential
    ]);
    await _withClient(transport, (client) async {
      final session = await client.beginPinSession(_info(protocols: [1]));
      final token = await session.getPinToken('1234');
      session.close();
      expect(token.protocolVersion, 1);

      final rps = await token.enumerateRps();
      expect(rps, hasLength(2));
      expect(rps[0].id, 'example.com');
      expect(rps[0].name, 'Example');
      expect(rps[0].idHash,
          List.generate(32, (index) => 0xA0 + index));
      expect(rps[1].id, 'other.org');
      expect(rps[1].name, isNull);
      expect(rps[1].idHash,
          List.generate(32, (index) => 0xC0 + index));

      final credentials = await token.enumerateCredentials(rps[0].idHash);
      expect(credentials, hasLength(1));
      final credential = credentials.single;
      expect(credential.credentialId, [1, 2, 3, 4]);
      expect(credential.userId, [5, 6, 7, 8]);
      expect(credential.userName, 'alice');
      expect(credential.userDisplayName, isNull);
      expect(credential.credProtect, isNull);
      expect(credential.coseAlgorithm, -49);
      expect(credential.publicKey, isNull);

      await token.deleteCredential(credential.credentialId);
      token.close();

      expect(transport.commands, [
        _select,
        '801000000606A201010202',
        _select,
        allOf(startsWith('80100000'), contains('06A5')),
        _select,
        allOf(startsWith('80100000'), contains('0AA3')),
        allOf(startsWith('80100000'), contains('0AA2010303')),
        _select,
        allOf(startsWith('80100000'), contains('0AA4'), contains('1880F5')),
        _select,
        allOf(startsWith('80100000'), contains('0AA4'),
            contains('01020304')),
      ]);
    });
  });

  test('enumeration without credentials yields an empty list', () async {
    final transport = _QueueApduTransport([
      '9000', _ctapOk(_peerKeyAgreement), // session
      '9000', _ctapOk('a1025820$_tokenCiphertextV1'), // getPinToken
      '9000', '2E9000', // enumerateRps Begin: NO_CREDENTIALS
    ]);
    await _withClient(transport, (client) async {
      final session = await client.beginPinSession(_info(protocols: [1]));
      final token = await session.getPinToken('1234');
      session.close();

      expect(await token.enumerateRps(), isEmpty);
      token.close();
    });
  });

  test('deleting an unknown credential surfaces NotFound', () async {
    final transport = _QueueApduTransport([
      '9000', _ctapOk(_peerKeyAgreement), // session
      '9000', _ctapOk('a1025820$_tokenCiphertextV1'), // getPinToken
      '9000', '2E9000', // deleteCredential
    ]);
    await _withClient(transport, (client) async {
      final session = await client.beginPinSession(_info(protocols: [1]));
      final token = await session.getPinToken('1234');
      session.close();

      await expectLater(
        token.deleteCredential([1, 2, 3, 4]),
        throwsA(isA<ProtocolException>()
            .having((e) => e.details.kind, 'kind', 'NotFound')
            .having((e) => e.details.statusWord, 'statusWord', 0x2E)),
      );
      token.close();
    });
  });

  test('a closed token rejects further operations without I/O', () async {
    final transport = _QueueApduTransport([
      '9000', _ctapOk(_peerKeyAgreement), // session
      '9000', _ctapOk('a1025820$_tokenCiphertextV1'), // getPinToken
    ]);
    await _withClient(transport, (client) async {
      final session = await client.beginPinSession(_info(protocols: [1]));
      final token = await session.getPinToken('1234');
      session.close();
      token.close();
      token.close();

      await expectLater(token.enumerateRps(), throwsStateError);
      expect(transport.commands, hasLength(4));
    });
  });

  test('injected transports require an explicit session', () async {
    final client = WebAuthnCardClient(transport: _QueueApduTransport([]));
    await expectLater(client.getInfo(), throwsStateError);
  });
}

WebAuthnInfo _info({required List<int> protocols}) => WebAuthnInfo(
      credMgmt: true,
      clientPin: true,
      forcePinChange: false,
      minPinLength: 4,
      pinUvAuthProtocols: protocols,
    );

Future<T> _withClient<T>(
  _QueueApduTransport transport,
  Future<T> Function(WebAuthnCardClient) action,
) {
  final client = WebAuthnCardClient(transport: transport);
  return client.withSession(() => action(client));
}

class _QueueApduTransport implements ApduTransport {
  _QueueApduTransport(List<String> responses) : responses = List.of(responses);

  final List<String> responses;
  final List<String> commands = [];
  int _responseIndex = 0;

  @override
  Future<String> transceive(String capdu) async {
    commands.add(capdu);
    return responses[_responseIndex++];
  }
}
