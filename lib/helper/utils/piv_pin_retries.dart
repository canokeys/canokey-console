enum PivPinRetryResetResult { failed, success, metadataUpdateFailed }

/// A successful reset clears card authentication and changes the credentials.
/// Later failures must not be reported as if the reset never happened.
Future<PivPinRetryResetResult> resetPivPinRetries({
  required Future<bool> Function() reset,
  required Future<bool> Function() authenticateManagementKey,
  required Future<bool> Function() updateMetadata,
}) async {
  if (!await reset()) return PivPinRetryResetResult.failed;
  try {
    if (!await authenticateManagementKey() || !await updateMetadata()) {
      return PivPinRetryResetResult.metadataUpdateFailed;
    }
    return PivPinRetryResetResult.success;
  } catch (_) {
    return PivPinRetryResetResult.metadataUpdateFailed;
  }
}
