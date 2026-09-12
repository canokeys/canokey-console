import 'dart:io';
import 'package:convert/convert.dart';
import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/piv_card.dart';
import 'package:canokey_console/models/piv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'PUK change and PIN unblock share PIN encoding and report failures',
    () async {
      final transport = _QueueApduTransport(['63C2', '9000']);
      final client = PivCardClient(transport: transport);

      expect(await client.changePuk('12345678', '87654321'), isFalse);
      expect(client.lastStatusWord, '63C2');
      expect(await client.unblockPin('87654321', '123456'), isTrue);
      expect(client.lastStatusWord, '9000');
      expect(transport.commands, [
        '002400811031323334353637383837363534333231',
        '002C0080103837363534333231313233343536FFFF',
      ]);

      await expectLater(
        client.changePuk('123456789', '87654321'),
        throwsArgumentError,
      );
      await expectLater(
        client.unblockPin('87654321', '123456789'),
        throwsArgumentError,
      );
      expect(transport.commands, hasLength(2));
    },
  );

  test(
    'reads the reported four-part certificate without PIV metadata',
    () async {
      final responses = File(
        'test/fixtures/piv/certificate_response.txt',
      ).readAsLinesSync();
      final transport = _QueueApduTransport(responses);
      final certificate = await PivCardClient(
        transport: transport,
      ).readCertificate(0x05);
      expect(
        certificate,
        File('test/fixtures/piv/certificate.der').readAsBytesSync(),
      );
      expect(certificate, hasLength(867));
      expect(transport.commands, [
        '00CB3FFF055C035FC10500',
        '00C00000ff',
        '00C00000ff',
        '00C0000072',
      ]);
    },
  );

  test(
    'reads short and one-byte long lengths and reordered metadata',
    () async {
      for (final response in [
        '530a7003300100710100fe009000',
        '530a7101007003300100fe009000',
        '530570033001009000',
      ]) {
        final client = PivCardClient(
          transport: _QueueApduTransport([response]),
        );
        expect(await client.readCertificate(0x0a), [0x30, 0x01, 0x00]);
      }
      final bytes = [0x30, 0x7e, ...List.filled(126, 0)];
      final response = hex.encode([
        0x53,
        0x81,
        0x88,
        0x70,
        0x81,
        0x80,
        ...bytes,
        0x71,
        0x01,
        0x00,
        0xfe,
        0x00,
        0x90,
        0x00,
      ]);
      final client = PivCardClient(transport: _QueueApduTransport([response]));
      expect(await client.readCertificate(0x0a), bytes);
    },
  );

  test(
    'returns null for a missing certificate and rejects invalid objects',
    () async {
      for (final sw in ['6A82', '6A88']) {
        final missing = PivCardClient(transport: _QueueApduTransport([sw]));
        expect(await missing.readCertificate(0x05), isNull);
        expect(missing.lastStatusWord, sw);
      }
      for (final response in [
        '70033001009000', // no outer object
        '53037101009000', // no certificate
        '530270009000', // empty certificate
        '5382019000', // truncated length
        '530a700330019000', // truncated value
        '530970033001007100fe009000', // empty certificate information
      ]) {
        final client = PivCardClient(
          transport: _QueueApduTransport([response]),
        );
        await expectLater(client.readCertificate(0x05), throwsFormatException);
      }
      final compressed = PivCardClient(
        transport: _QueueApduTransport(['530a7003300100710101fe009000']),
      );
      await expectLater(
        compressed.readCertificate(0x05),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Compressed'),
          ),
        ),
      );
    },
  );

  test(
    'runs PIV metadata and PIN operations through the injected transport',
    () async {
      final transport = _QueueApduTransport([
        '9000',
        '0102039000',
        '010203049000',
        '63C3',
        '9000',
        '9000',
        '9000',
        '0101FF050101060203039000',
      ]);
      final client = PivCardClient(transport: transport);

      await client.select();
      expect(await client.readVersion(), [1, 2, 3]);
      expect(await client.readSerial(), '01020304');
      expect(await client.readPinRetries(), '63C3');
      expect(await client.verifyPin('123456'), isTrue);
      expect(await client.changePin('123456', '654321'), isTrue);
      await client.logout();
      final metadata = await client.readMetadata(0x80);

      expect(metadata, isNotNull);
      expect(metadata!.retriesCount, 3);
      expect(metadata.remainingCount, 3);
      expect(transport.commands, [
        '00A4040005A000000308',
        '00FD000000',
        '00F8000000',
        '0020008000',
        '0020008008313233343536FFFF',
        '0024008010313233343536FFFF363534333231FFFF',
        '0020FF8000',
        '00F7008000',
      ]);
    },
  );

  test(
    'blocks PUK through CHANGE REFERENCE DATA until confirmed blocked',
    () async {
      final transport = _QueueApduTransport(['63C2', '63C1', '63C0', '6983']);
      expect(await PivCardClient(transport: transport).blockPuk(), isTrue);
      expect(transport.commands, hasLength(4));
      for (final command in transport.commands) {
        expect(command, startsWith('0024008110'));
        expect(command.length, 42);
        expect(command.substring(10, 26), command.substring(26));
      }
    },
  );

  test(
    'accepts an already blocked PUK and retries an accidental match',
    () async {
      for (final responses in [
        ['6983'],
        ['9000', '63C0', '6983'],
      ]) {
        final transport = _QueueApduTransport(responses);
        expect(await PivCardClient(transport: transport).blockPuk(), isTrue);
        expect(transport.commands, hasLength(responses.length));
      }
    },
  );

  test(
    'does not report PUK blocked on unexpected status or endless retries',
    () async {
      for (final responses in [
        ['6982'],
        ['6A80'],
        ['63C0', '6F00'],
        List.filled(257, '9000'),
        List.filled(257, '63C1'),
      ]) {
        final transport = _QueueApduTransport(responses);
        expect(await PivCardClient(transport: transport).blockPuk(), isFalse);
        expect(transport.commands, hasLength(responses.length));
      }
    },
  );

  test('reads optional algorithm extensions and missing metadata', () async {
    final config = await PivCardClient(
      transport: _QueueApduTransport(['9000', '01E00516E1531554E2E39000']),
    ).readAlgorithmExtensions();
    expect(config, isNotNull);
    expect(config!.enabled, isTrue);

    expect(
      await PivCardClient(
        transport: _QueueApduTransport(['9000', '6D00']),
      ).readAlgorithmExtensions(),
      isNull,
    );
    expect(
      await PivCardClient(
        transport: _QueueApduTransport(['6A88']),
      ).readMetadata(0x80),
      isNull,
    );
  });

  test('follows metadata GET RESPONSE and validates PIN length', () async {
    final transport = _QueueApduTransport(['0101FF6104', '050101060203039000']);
    final client = PivCardClient(transport: transport);

    final metadata = await client.readMetadata(0x80);

    expect(metadata, isNotNull);
    expect(transport.commands, ['00F7008000', '00C0000004']);
    expect(() => client.verifyPin('123456789'), throwsArgumentError);
  });

  test('maps metadata with firmware-specific algorithm extensions', () async {
    final metadata =
        await PivCardClient(
          transport: _QueueApduTransport(['010122050101060203039000']),
        ).readMetadata(
          0x80,
          algorithmExtensionConfig: PivAlgorithmExtensionConfig.legacyV2,
        );

    expect(metadata, isNotNull);
    expect(metadata!.algorithm, AlgorithmType.ed25519);
  });
}

class _QueueApduTransport implements ApduTransport {
  _QueueApduTransport(this.responses);

  final List<String> responses;
  final List<String> commands = [];
  int _responseIndex = 0;

  @override
  Future<String> transceive(String capdu) async {
    commands.add(capdu);
    return responses[_responseIndex++];
  }
}
