import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/views/applets/settings/widgets/action_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile factory reset is allowed only over CCID', () {
    expect(
      shouldBlockFactoryReset(
        mobile: true,
        connectionType: ConnectionType.ccid,
      ),
      isFalse,
    );
    expect(
      shouldBlockFactoryReset(
        mobile: true,
        connectionType: ConnectionType.nfc,
      ),
      isTrue,
    );
    expect(
      shouldBlockFactoryReset(
        mobile: true,
        connectionType: ConnectionType.none,
      ),
      isTrue,
    );
  });

  test('desktop factory reset is not restricted by mobile transport policy',
      () {
    for (final connectionType in ConnectionType.values) {
      expect(
        shouldBlockFactoryReset(
          mobile: false,
          connectionType: connectionType,
        ),
        isFalse,
        reason: connectionType.name,
      );
    }
  });
}
