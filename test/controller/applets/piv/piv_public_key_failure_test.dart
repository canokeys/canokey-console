import 'dart:typed_data';

import 'package:canokey_console/controller/applets/piv/piv_controller.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:canokey_console/src/rust/api/crypto.dart';
import 'package:canokey_console/src/rust/api/piv_crypto.dart';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:flutter_test/flutter_test.dart';

class InvalidPublicKeyApi implements RustLibApi {
  int parseCalls = 0;

  @override
  PivPublicKeyData crateApiPivCryptoBuildPivPublicKey({
    required int algorithm,
    required List<int> cardData,
    required bool generatedResponse,
  }) {
    parseCalls++;
    // Match the synchronous bridge's Result<_, String> error representation.
    // ignore: only_throw_errors
    throw 'invalid RSA public key: invalid modulus';
  }

  @override
  X509CertData crateApiCryptoParseX509CertFromDer({required List<int> der}) {
    parseCalls++;
    // ignore: only_throw_errors
    throw 'failed to decode X.509 certificate';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InvalidPublicKeyApi api;
  setUp(() {
    api = InvalidPublicKeyApi();
    RustLib.initMock(api: api);
  });
  tearDown(RustLib.dispose);

  for (final source in ['metadata', 'certificate']) {
    test(
      'invalid $source fails export, signing and verification gracefully',
      () async {
        final controller = PivController();
        final slot = SlotInfo(
          0x9c,
          AlgorithmType.rsa2048,
          PinPolicy.defaultPolicy,
          TouchPolicy.defaultPolicy,
          Origin.generated,
          source == 'metadata' ? [0x81, 0] : [],
          false,
          0,
          0,
        );
        if (source == 'certificate') {
          slot.certBytes = [0x30, 0];
        }
        final data = Uint8List.fromList([1, 2, 3]);

        expect(controller.publicKeyForSlot(slot), isNull);
        expect(await controller.signData('9c', slot, '123456', data), isNull);
        expect(await controller.verifySignature(slot, data, data), isFalse);
        expect(api.parseCalls, 3);
      },
    );
  }
}
