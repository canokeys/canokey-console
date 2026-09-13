import 'package:canokey_console/src/rust/api/crypto.dart';
import 'package:canokey_console/src/rust/frb_generated.dart';
import 'package:canokey_console/controller/applets/piv/piv_controller.dart';
import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/piv_card.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/piv_certificate_api.dart';

class CertificateTransport implements ApduTransport {
  CertificateTransport(this.responses);
  final List<String> responses;
  final commands = <String>[];

  @override
  Future<String> transceive(String capdu) async {
    commands.add(capdu);
    return responses.removeAt(0);
  }
}

class InvalidCertificateApi implements RustLibApi {
  @override
  X509CertData crateApiCryptoParseX509CertFromDer({required List<int> der}) {
    // Match the generated bridge's Result<_, String> error representation.
    // ignore: only_throw_errors
    throw 'failed to decode X.509 certificate';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SmartCard.connectionType = ConnectionType.ccid);
  tearDown(() => SmartCard.connectionType = ConnectionType.none);

  test(
    'legacy certificate loading exposes SPKI without inventing key metadata',
    () async {
      final api = PivCertificateApi();
      RustLib.initMock(api: api);
      addTearDown(RustLib.dispose);
      final transport = CertificateTransport(['9000', '530570033001009000']);
      final controller = PivController(
        client: PivCardClient(transport: transport),
      );
      controller.certificateSlots.add(0x9a);

      await controller.loadSlotDetails(0x9a);

      expect(controller.supportsMetadata, isFalse);
      expect(
        controller.publicKeyDerForSlot(0x9a),
        api.certificate.subjectPublicKeyInfo,
      );
      expect(controller.publicKeyDerForSlot(0x9d), isNull);
      expect(controller.slots, isEmpty);
      expect(transport.commands, [
        '00A4040005A000000308',
        '00CB3FFF055C035FC10500',
      ]);
    },
  );

  test(
    'unreadable certificate stays occupied and does not block the next slot',
    () async {
      for (final response in [
        '5301709000', // Truncated certificate object.
        '530a7003300100710101fe009000', // Compressed certificate.
      ]) {
        final transport = CertificateTransport([
          '9000',
          response,
          '9000',
          '6A82',
        ]);
        final controller = PivController(
          client: PivCardClient(transport: transport),
        );
        controller.certificateSlots.addAll([0x9a, 0x9d]);

        await controller.loadSlotDetails(0x9a);
        expect(controller.hasCertificate(0x9a), isTrue);
        expect(controller.certificates.containsKey(0x9a), isFalse);
        expect(controller.certificateBytes.containsKey(0x9a), isFalse);
        await controller.loadSlotDetails(0x9d);
        expect(transport.responses, isEmpty);
        expect(transport.commands, [
          '00A4040005A000000308',
          '00CB3FFF055C035FC10500',
          '00A4040005A000000308',
          '00CB3FFF055C035FC10b00',
        ]);
      }
    },
  );
  test(
    'invalid DER remains available without interrupting slot loading',
    () async {
      RustLib.initMock(api: InvalidCertificateApi());
      addTearDown(RustLib.dispose);
      final transport = CertificateTransport(['9000', '530570033001009000']);
      final controller = PivController(
        client: PivCardClient(transport: transport),
      );
      controller.certificateSlots.add(0x9a);

      await controller.loadSlotDetails(0x9a);

      expect(controller.hasCertificate(0x9a), isTrue);
      expect(controller.certificateBytes[0x9a], [0x30, 0x01, 0x00]);
      expect(controller.certificates.containsKey(0x9a), isFalse);
      expect(controller.publicKeyDerForSlot(0x9a), isNull);
    },
  );
}
