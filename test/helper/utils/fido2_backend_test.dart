import 'package:canokey_console/helper/utils/fido2_backend.dart';
import 'package:cbor/cbor.dart';
import 'package:convert/convert.dart';
import 'package:fido2/fido2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(initializeFido2Backend);

  test('initializes the packaged ABI and computes SHA-256', () async {
    await initializeFido2Backend();
    expect(
      hex.encode(RustCrypto.sha256([97, 98, 99])),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  for (final protocol in [PinProtocolV1(), PinProtocolV2()]) {
    test(
      'credential enumeration and deletion use PIN v${protocol.version}',
      () async {
        final device = _CredentialDevice();
        final ctap = await Ctap2.create(device);
        expect(ctap.info.algorithms!.single['type'], 'public-key');
        final manager = CredentialManagement(
          ctap,
          protocol,
          List.filled(32, 7),
        );
        final credentials = await manager.enumerateCredentialsMetadataOnly(
          List.filled(32, 1),
        );
        expect(credentials.single.user.name, 'alice');
        expect(credentials.single.coseAlgorithm, -49);
        await manager.deleteCredential(credentials.single.credentialId);
        expect(device.requests.map((r) => r[1]), [4, 6]);
        for (final request in device.requests) {
          expect(request[3], protocol.version);
          expect(request[4], hasLength(protocol.version == 1 ? 16 : 32));
        }
      },
    );
    test(
      'PIN v${protocol.version} encrypts, decrypts and uses the correct wire MAC',
      () async {
        final key = List<int>.generate(
          protocol.version == 1 ? 32 : 64,
          (i) => i,
        );
        final message = List<int>.generate(32, (i) => 255 - i);
        final encrypted = await protocol.encrypt(key, message);
        expect(await protocol.decrypt(key, encrypted), message);
        final mac = await protocol.authenticate(key, message);
        expect(mac, hasLength(32));
        final wire = await protocol.authenticateParam(key, message);
        expect(wire, protocol.version == 1 ? mac.sublist(0, 16) : mac);
      },
    );
  }
}

class _CredentialDevice extends CtapDevice {
  final requests = <Map<dynamic, dynamic>>[];

  @override
  Future<CtapResponse<List<int>>> transceive(List<int> command) async {
    if (command.first == 4) {
      return CtapResponse(
        0,
        cbor.encode(
          CborValue({
            1: ['FIDO_2_1'],
            3: CborBytes(List.filled(16, 0)),
            4: {'credMgmt': true, 'clientPin': true},
            6: [1, 2],
            10: [
              {'alg': -7, 'type': 'public-key'},
            ],
          }),
        ),
      );
    }
    expect(command.first, 0x0a);
    final request = cbor.decode(command.sublist(1)).toObject() as Map;
    requests.add(request);
    if (request[1] == 6) return CtapResponse(0, []);
    return CtapResponse(
      0,
      cbor.encode(
        CborValue({
          6: {
            'id': CborBytes([1]),
            'name': 'alice',
          },
          7: {
            'id': CborBytes([2]),
            'type': 'public-key',
          },
          9: 1,
          10: 1,
          0x80: -49,
        }),
      ),
    );
  }
}
