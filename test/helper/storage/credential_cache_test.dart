import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  test(
    'PIN invalidation reaches all page-local copies before the next attempt',
    () async {
      final settings = CredentialCache('ADMIN')..['A'] = 'old-pin';
      final pass = CredentialCache('ADMIN')..['A'] = 'old-pin';
      await LocalStorage.setPinCache('A', 'ADMIN', 'old-pin');
      await LocalStorage.setPinCache('A', 'ADMIN', null);
      expect(settings.containsKey('A'), isFalse);
      expect(pass['A'], isNull);
      expect(LocalStorage.getPinCache('A', 'ADMIN'), isNull);
      await LocalStorage.setPinCache('A', 'ADMIN', 'new-pin');
      expect(pass['A'], isNull); // Saving a value is not new verification.
      settings['A'] = 'new-pin';
      expect(settings['A'], 'new-pin');
    },
  );

  test(
    'device reset invalidates saved and unsaved credentials for only that device',
    () async {
      final admin = CredentialCache('ADMIN')
        ..['A'] = 'admin-a'
        ..['B'] = 'admin-b';
      final oath = CredentialCache('OATH')..['A'] = 'unsaved-oath';
      final webauthn = CredentialCache('webauthn')..['A'] = 'fido-a';
      await LocalStorage.setPinCache('A', 'webauthn', 'fido-a');
      await LocalStorage.setPinCache('B', 'ADMIN', 'admin-b');
      await LocalStorage.setStartPage('settings');
      await LocalStorage.clearPinCacheForDevice('A');
      expect(admin['A'], isNull);
      expect(oath['A'], isNull);
      expect(webauthn['A'], isNull);
      expect(LocalStorage.getPinCache('A', 'webauthn'), isNull);
      expect(admin['B'], 'admin-b');
      expect(LocalStorage.getPinCache('B', 'ADMIN'), 'admin-b');
      expect(LocalStorage.getStartPage(), 'settings');
    },
  );

  test(
    'global cache clearing also invalidates credentials never saved to disk',
    () async {
      final cache = CredentialCache('ADMIN')..['unsaved'] = 'pin';
      await LocalStorage.clearPinCache();
      expect(cache['unsaved'], isNull);
    },
  );
}
