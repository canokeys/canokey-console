import 'dart:convert';
import 'dart:typed_data';

import 'package:canokey_console/helper/utils/card_client.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/src/rust/api/protocol.dart';

/// Authenticator information decoded by libcanokey.
class WebAuthnInfo {
  const WebAuthnInfo({
    required this.credMgmt,
    required this.clientPin,
    required this.forcePinChange,
    required this.minPinLength,
    required this.alwaysUv,
    required this.pinUvAuthProtocols,
  });

  final bool? credMgmt;
  final bool? clientPin;
  final bool? forcePinChange;
  final int? minPinLength;
  final bool? alwaysUv;
  final List<int> pinUvAuthProtocols;

  /// The ClientPIN protocol to speak: prefer V2 when advertised, like the
  /// former fido2 package; fall back to V1 (the CTAP2 default).
  int get pinProtocol => pinUvAuthProtocols.contains(2) ? 2 : 1;

  factory WebAuthnInfo.fromResult(CtapInfo info) => WebAuthnInfo(
    credMgmt: info.credMgmt,
    clientPin: info.clientPin,
    forcePinChange: info.forcePinChange,
    minPinLength: info.minPinLength?.toInt(),
    alwaysUv: info.alwaysUv,
    pinUvAuthProtocols: List.unmodifiable(info.pinUvAuthProtocols),
  );
}

/// One relying party with resident credentials.
class WebAuthnRp {
  const WebAuthnRp({
    required this.id,
    required this.name,
    required this.idHash,
  });

  final String id;
  final String? name;
  final Uint8List idHash;
}

/// One resident credential. In metadataOnly mode [publicKey] is absent and
/// [coseAlgorithm] carries the raw CanoKey extension value.
class WebAuthnCredential {
  const WebAuthnCredential({
    required this.credentialId,
    required this.userId,
    required this.userName,
    required this.userDisplayName,
    required this.credProtect,
    required this.coseAlgorithm,
    required this.publicKey,
  });

  final Uint8List credentialId;
  final Uint8List? userId;
  final String? userName;
  final String? userDisplayName;
  final int? credProtect;
  final int? coseAlgorithm;
  final Uint8List? publicKey;
}

/// A ClientPIN key-agreement session. The shared secret lives only in the
/// zeroizing Rust handle; [close] is idempotent local cleanup. Obtain a
/// fresh session per use case instead of caching this wrapper.
class WebAuthnPinSession {
  WebAuthnPinSession._(this._client, this._handle);

  final WebAuthnCardClient _client;
  CtapPinSession? _handle;

  CtapPinSession get _session =>
      _handle ?? (throw StateError('WebAuthn PIN session is closed'));

  Future<void> setPin(String newPin) async {
    final newPinBytes = utf8.encode(newPin);
    try {
      await _client._execute(_session.setPin(newPin: newPinBytes));
    } finally {
      newPinBytes.fillRange(0, newPinBytes.length, 0);
    }
  }

  Future<void> changePin(String oldPin, String newPin) async {
    final oldPinBytes = utf8.encode(oldPin);
    final newPinBytes = utf8.encode(newPin);
    try {
      await _client._execute(
        _session.changePin(oldPin: oldPinBytes, newPin: newPinBytes),
      );
    } finally {
      oldPinBytes.fillRange(0, oldPinBytes.length, 0);
      newPinBytes.fillRange(0, newPinBytes.length, 0);
    }
  }

  /// Mint a pinUvAuthToken (credentialManagement permission 0x04 by default;
  /// pass [permissions] for other scopes such as authenticatorConfig 0x20).
  /// The token outlives this session; close the session once the token exists.
  Future<WebAuthnPinToken> getPinToken(
    String pin, {
    int permissions = WebAuthnCardClient.permissionCredentialManagement,
    String? rpId,
  }) async {
    final pinBytes = utf8.encode(pin);
    try {
      final token = await _client._executeToken(
        _session.getPinTokenWithPermissions(
          pin: pinBytes,
          permissions: permissions,
          rpId: rpId,
        ),
      );
      return WebAuthnPinToken._(_client, token);
    } finally {
      pinBytes.fillRange(0, pinBytes.length, 0);
    }
  }

  void close() {
    final handle = _handle;
    _handle = null;
    if (handle != null) {
      try {
        handle.close();
      } finally {
        handle.dispose();
      }
    }
  }
}

/// A decrypted pinUvAuthToken held only in zeroizing Rust memory. Per CTAP
/// 2.1 tokens are ceremony-scoped: never cache this wrapper across use cases.
class WebAuthnPinToken {
  WebAuthnPinToken._(this._client, this._handle);

  final WebAuthnCardClient _client;
  CtapPinToken? _handle;

  CtapPinToken get _token =>
      _handle ?? (throw StateError('WebAuthn PIN token is closed'));

  Future<List<WebAuthnRp>> enumerateRps() async =>
      (await _client._executeResult(
            _token.enumerateRps(),
            (step) => step.ctapRps!,
          ))
          .map(
            (entry) => WebAuthnRp(
              id: entry.id,
              name: entry.name,
              idHash: entry.idHash,
            ),
          )
          .toList();

  Future<List<WebAuthnCredential>> enumerateCredentials(
    Uint8List rpIdHash, {
    bool metadataOnly = true,
  }) async =>
      (await _client._executeResult(
            _token.enumerateCredentials(
              rpIdHash: rpIdHash,
              metadataOnly: metadataOnly,
            ),
            (step) => step.ctapCredentials!,
          ))
          .map(
            (entry) => WebAuthnCredential(
              credentialId: entry.credentialId,
              userId: entry.userId,
              userName: entry.userName,
              userDisplayName: entry.userDisplayName,
              credProtect: entry.credProtect,
              coseAlgorithm: entry.coseAlgorithm?.toInt(),
              publicKey: entry.publicKey,
            ),
          )
          .toList();

  /// Permanently delete one resident credential. An unknown ID surfaces as a
  /// NotFound ProtocolException with the raw CTAP status byte; never retried.
  Future<void> deleteCredential(List<int> credentialId) async =>
      _client._execute(_token.deleteCredential(credentialId: credentialId));

  /// Toggle the device-global alwaysUv option. Requires the
  /// authenticatorConfig permission (0x20).
  Future<void> toggleAlwaysUv() async =>
      _client._execute(_token.toggleAlwaysUv());

  /// Raise the device-global minimum PIN length. The value can only grow, so
  /// a lower value is rejected with PIN_POLICY_VIOLATION (0x37). The RP
  /// allowlist (minPinLengthRPIDs) is not exposed: it stays empty, disclosing
  /// the value to no relying party. Requires the authenticatorConfig
  /// permission (0x20).
  Future<void> setMinPinLength(int newMinPinLength, {bool? forcePinChange}) =>
      _client._execute(
        _token.setMinPinLength(
          newMinPinLength: newMinPinLength,
          forcePinChange: forcePinChange,
          rpIds: const [],
        ),
      );

  /// Require a 30-second long touch for authenticatorReset. Irreversible;
  /// only a full authenticatorReset clears it. Requires the
  /// authenticatorConfig permission (0x20).
  Future<void> enableLongTouchForReset() async =>
      _client._execute(_token.enableLongTouchForReset());

  void close() {
    final handle = _handle;
    _handle = null;
    if (handle != null) {
      try {
        handle.close();
      } finally {
        handle.dispose();
      }
    }
  }
}

/// libcanokey-backed WebAuthn (CTAP2) client. Every operation is profile-free
/// and SELECTs the FIDO2 applet itself, so consecutive operations in one use
/// case never assume a residual selection. CTAP-level failures surface as
/// [ProtocolException] whose `details.statusWord` carries the raw CTAP status
/// byte (for example 0x31 PIN_INVALID), not an ISO 7816 status word.
class WebAuthnCardClient extends CardClientBase {
  WebAuthnCardClient({super.transport, super.lease});

  static const int permissionCredentialManagement = 0x04;
  static const int permissionAuthenticatorConfig = 0x20;

  Future<WebAuthnInfo> getInfo() async => WebAuthnInfo.fromResult(
    await _executeResult(
      ProtocolOperation.ctapGetInfo(),
      (step) => step.ctapInfo!,
    ),
  );

  /// Start a ClientPIN session with the protocol preferred by [info]. The
  /// caller closes the returned session after its dependent operations.
  Future<WebAuthnPinSession> beginPinSession(WebAuthnInfo info) async {
    final session = await _executeSession(
      ProtocolOperation.ctapBeginPinSession(protocol: info.pinProtocol),
    );
    return WebAuthnPinSession._(this, session);
  }

  Future<Uint8List> _execute(ProtocolOperation operation) =>
      _executeResult(operation, (step) => step.data!);

  Future<CtapPinSession> _executeSession(ProtocolOperation operation) =>
      _executeResult(operation, (step) => step.pinSession!);

  Future<CtapPinToken> _executeToken(ProtocolOperation operation) =>
      _executeResult(operation, (step) => step.pinToken!);

  Future<T> _executeResult<T>(
    ProtocolOperation operation,
    T Function(ProtocolStep) result,
  ) {
    cancellation.check();
    final lease = this.lease;
    lease.willSelectApplet();
    return executeProtocolResult(
      operation,
      transport,
      lease: lease,
      cancellation: cancellation,
      result: result,
    );
  }
}
