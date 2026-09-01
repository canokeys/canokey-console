import 'package:canokey_console/helper/utils/screenshot_mode.dart';
import 'package:canokey_console/models/ndef.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('provides deterministic populated screenshot data', () {
    final slots = ScreenshotMode.passSlots();
    final records = ScreenshotMode.ndefRecords();
    final key = ScreenshotMode.canoKey();

    expect(slots.map((slot) => slot.type), [
      PassSlotType.static,
      PassSlotType.hmacSha1,
    ]);
    expect(records, hasLength(3));
    expect(NdefDocument(records).encodedLength, lessThanOrEqualTo(1022));
    expect(key.model, 'CanoKey Canary');
    expect(key.storageUsage?.usedKiB, 14);
    expect(key.storageUsage?.totalKiB, 124);
  });
}
