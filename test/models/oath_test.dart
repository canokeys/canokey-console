import 'package:canokey_console/controller/applets/oath/oath_controller.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Steam TOTP', () {
    test('formats raw OATH response with Steam alphabet', () {
      expect(formatSteamCode(0), '22222');
      expect(formatSteamCode(1), '32222');
      expect(formatSteamCode(26), '23222');
      expect(formatSteamCode(27), '33222');
    });

    test('detects Steam format from issuer only', () {
      expect(OathCodeFormat.fromIssuer('Steam'), OathCodeFormat.steam);
      expect(OathCodeFormat.fromIssuer('steam'), OathCodeFormat.steam);
      expect(OathCodeFormat.fromIssuer('Steam Guard'), OathCodeFormat.decimal);
    });

    test('parses Steam otpauth URI without duplicating issuer in account', () {
      final controller = OathController();

      controller.parseUri(
          'otpauth://totp/Steam:alice?secret=JBSWY3DPEHPK3PXP&issuer=Steam&digits=5');

      final result = controller.qrScanResult.value;
      expect(result, isNotNull);
      expect(result!.issuer, 'Steam');
      expect(result.account, 'alice');
      expect(result.type, OathType.totp);
      expect(result.algo, OathAlgorithm.sha1);
      expect(result.digits, 6);
    });

    test('keeps non-Steam 5 digit otpauth URI rejected', () {
      final controller = OathController();

      controller.parseUri(
          'otpauth://totp/Example:alice?secret=JBSWY3DPEHPK3PXP&issuer=Example&digits=5');

      expect(controller.qrScanResult.value, isNull);
    });
  });
}
