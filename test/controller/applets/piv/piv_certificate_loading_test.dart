import 'dart:typed_data';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/src/rust/api/protocol.dart';
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
      final transport = CertificateTransport(['9000']);
      final controller = PivController(
        client: PivCardClient(
          transport: transport,
          certificateExecutor: (objectId) async {
            expect(objectId, 0x05);
            return Uint8List.fromList([0x30, 1, 0]);
          },
          prepareExecutor: () async {
            expect(
              await transport.transceive('00A4040005A00000030800'),
              '9000',
            );
          },
        ),
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
      expect(transport.commands, ['00A4040005A00000030800']);
    },
  );

  test(
    'unreadable certificate stays occupied and does not block the next slot',
    () async {
      for (final kind in [
        'InvalidResponse',
        'UnsupportedProtocolVersion',
        'LimitExceeded',
      ]) {
        final transport = CertificateTransport(['9000', '9000']);
        final controller = PivController(
          client: PivCardClient(
            transport: transport,
            certificateExecutor: (objectId) async {
              throw ProtocolException(
                ProtocolError(
                  kind: objectId == 0x05 ? kind : 'NotFound',
                  phase: objectId == 0x05 ? 'Parsing' : 'Command',
                  statusWord: objectId == 0x05 ? null : 0x6a82,
                ),
              );
            },
            prepareExecutor: () async {
              expect(
                await transport.transceive('00A4040005A00000030800'),
                '9000',
              );
            },
          ),
        );
        controller.certificateSlots.addAll([0x9a, 0x9d]);

        await controller.loadSlotDetails(0x9a);
        expect(controller.hasCertificate(0x9a), isTrue);
        expect(controller.certificates.containsKey(0x9a), isFalse);
        expect(controller.certificateBytes.containsKey(0x9a), isFalse);
        await controller.loadSlotDetails(0x9d);
        expect(transport.responses, isEmpty);
        expect(transport.commands, [
          '00A4040005A00000030800',
          '00A4040005A00000030800',
        ]);
      }
    },
  );
  test(
    'invalid DER remains available without interrupting slot loading',
    () async {
      RustLib.initMock(api: InvalidCertificateApi());
      addTearDown(RustLib.dispose);
      final transport = CertificateTransport(['9000']);
      final controller = PivController(
        client: PivCardClient(
          transport: transport,
          certificateExecutor: (objectId) async {
            expect(objectId, 0x05);
            return Uint8List.fromList([0x30, 1, 0]);
          },
          prepareExecutor: () async {
            expect(
              await transport.transceive('00A4040005A00000030800'),
              '9000',
            );
          },
        ),
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
