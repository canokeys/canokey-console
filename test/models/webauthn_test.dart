import 'package:canokey_console/models/webauthn.dart';
import 'package:canokey_console/views/applets/webauthn/dialogs/sm2_config_dialog.dart';
import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes exact big-endian wire vectors including signed limits', () {
    for (final vector in [
      ('00000009ffffffca', 9, -54),
      ('01234567fedcba98', 0x1234567, -0x1234568),
      ('800000007fffffff', -2147483648, 2147483647),
      ('7fffffff80000000', 2147483647, -2147483648),
    ]) {
      final config = WebAuthnSm2Config.decode(hex.decode(vector.$1));
      expect(config.curveId, vector.$2);
      expect(config.algoId, vector.$3);
      expect(
          hex.encode(config.encode(
              enabled: true, curveId: vector.$2, algoId: vector.$3)),
          vector.$1);
    }
  });

  test('legacy config retains enabled state and accepts old identifiers', () {
    final config = WebAuthnSm2Config.decode(hex.decode('0000000001fffffff9'));
    expect(config.enabled, isFalse);
    expect(config.canChangeEnabled, isTrue);
    expect(hex.encode(config.encode(enabled: true, curveId: 1, algoId: -7)),
        '0100000001fffffff9');
  });

  test('rejects malformed lengths and legacy enabled flags', () {
    for (final length in [0, 7, 10, 12]) {
      expect(() => WebAuthnSm2Config.decode(List.filled(length, 0)),
          throwsFormatException);
    }
    expect(() => WebAuthnSm2Config.decode([2, ...List.filled(8, 0)]),
        throwsFormatException);
  });

  test('current UI validators enforce int32 and reserved identifiers', () {
    final curve = Sm2IdentifierValidator(curve: true, legacy: false);
    final algorithm = Sm2IdentifierValidator(curve: false, legacy: false);
    for (final id in [0, 1, 8, 256, 259, -2147483649, 2147483648]) {
      expect(curve.validate('$id', true, {}), isNotNull);
    }
    for (final id in [-7, -8, -49, -2147483649, 2147483648]) {
      expect(algorithm.validate('$id', true, {}), isNotNull);
    }
    for (final id in [-2147483648, -65537, 9, 255, 260, 2147483647]) {
      expect(curve.validate('$id', true, {}), isNull);
      expect(algorithm.validate('$id', true, {}), isNull);
    }
    expect(algorithm.validate('abc', true, {}), isNotNull);
    expect(
        Sm2IdentifierValidator(curve: true, legacy: true)
            .validate('1', true, {}),
        isNull);
  });
}
