import 'package:canokey_console/models/piv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the recommended PIN policy for each standard PIV slot', () {
    expect(recommendedPivPinPolicy('9A'), PinPolicy.once);
    expect(recommendedPivPinPolicy('9C'), PinPolicy.always);
    expect(recommendedPivPinPolicy('9D'), PinPolicy.once);
    expect(recommendedPivPinPolicy('9E'), PinPolicy.never);
  });

  test('uses key management PIN policy for retired slots', () {
    expect(recommendedPivPinPolicy('82'), PinPolicy.once);
    expect(recommendedPivPinPolicy('95'), PinPolicy.once);
  });
}
