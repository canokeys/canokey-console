import 'package:canokey_console/helper/utils/piv_pin_retries.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'reauthenticates after reset before updating protected metadata',
    () async {
      var authenticated = true;
      final calls = <String>[];
      final result = await resetPivPinRetries(
        reset: () async {
          calls.add('reset');
          authenticated = false;
          return true;
        },
        authenticateManagementKey: () async {
          calls.add('authenticate');
          authenticated = true;
          return true;
        },
        updateMetadata: () async {
          calls.add('metadata');
          expect(authenticated, isTrue);
          return true;
        },
      );
      expect(result, PivPinRetryResetResult.success);
      expect(calls, ['reset', 'authenticate', 'metadata']);
    },
  );

  test('failed reset never proceeds to authentication or metadata', () async {
    expect(
      await resetPivPinRetries(
        reset: () async => false,
        authenticateManagementKey: () async =>
            throw StateError('unexpected auth'),
        updateMetadata: () async => throw StateError('unexpected write'),
      ),
      PivPinRetryResetResult.failed,
    );
  });

  test(
    'post-reset failures preserve the successful credential reset result',
    () async {
      for (final failAuth in [true, false]) {
        for (final throws in [true, false]) {
          var metadataCalled = false;
          final result = await resetPivPinRetries(
            reset: () async => true,
            authenticateManagementKey: () async {
              if (!failAuth) return true;
              if (throws) throw StateError('transport failed');
              return false;
            },
            updateMetadata: () async {
              metadataCalled = true;
              if (throws) throw StateError('transport failed');
              return false;
            },
          );
          expect(result, PivPinRetryResetResult.metadataUpdateFailed);
          expect(metadataCalled, !failAuth);
        }
      }
    },
  );
}
