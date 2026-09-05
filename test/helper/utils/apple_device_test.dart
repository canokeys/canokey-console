import 'package:canokey_console/helper/utils/apple_device.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recognizes iPad device identifiers', () {
    expect(AppleDevice.looksLikeIPad('iPad', 'iPad14,5'), isTrue);
    expect(AppleDevice.looksLikeIPad('iPhone', 'iPad14,5'), isTrue);
    expect(AppleDevice.looksLikeIPad('iPhone', 'iPhone16,2'), isFalse);
  });
}
