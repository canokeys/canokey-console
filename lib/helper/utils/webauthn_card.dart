import 'dart:convert';
import 'dart:typed_data';

import 'package:canokey_console/helper/utils/card_client.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/src/rust/api/protocol.dart';

/// Parsed authenticatorGetInfo fields, decoded in Rust and self-delimiting
/// here: `credMgmt | clientPin | forcePinChange` tri-state bytes
/// (0 = absent, 1 = false, 2 = true), a minPinLength flag byte (0 = absent;
/// 1 = present with a big-endian u64), then `count | pinUvAuthProtocol
/// version bytes`.
class WebAuthnInfo {
  const WebAuthnInfo({
    required this.credMgmt,
    required this.clientPin,
    required this.forcePinChange,
    required this.minPinLength,
    required this.pinUvAuthProtocols,
  });

  final bool? credMgmt;
  final bool? clientPin;
  final bool? forcePinChange;
  final int? minPinLength;
  final List<int> pinUvAuthProtocols;

  /// The ClientPIN protocol to speak: prefer V2 when advertised, like the
  /// former fido2 package; fall back to V1 (the CTAP2 default).
  int get pinProtocol => pinUvAuthProtocols.contains(2) ? 2 : 1;

  factory WebAuthnInfo.decode(Uint8List data) {
    bool? tristate(int value) => switch (value) {
      0 => null,
      1 => false,
      2 => true,
      _ => throw const FormatException('Invalid WebAuthn option tri-state'),
    };

    var offset = 0;
    int take() {
      if (offset >= data.length) {
        throw const FormatException('Truncated WebAuthn getInfo data');
      }
      return data[offset++];
    }

    final credMgmt = tristate(take());
    final clientPin = tristate(take());
    final forcePinChange = tristate(take());
    int? minPinLength;
    final minPinLengthFlag = take();
    if (minPinLengthFlag == 1) {
      if (data.length - offset < 8) {
        throw const FormatException('Truncated WebAuthn minPinLength');
      }
      minPinLength = ByteData.sublistView(data).getUint64(offset);
      offset += 8;
    } else if (minPinLengthFlag != 0) {
      throw const FormatException('Invalid WebAuthn minPinLength flag');
    }
    final protocolCount = take();
    if (data.length - offset != protocolCount) {
      throw const FormatException('Truncated WebAuthn protocol list');
    }
    return WebAuthnInfo(
      credMgmt: credMgmt,
      clientPin: clientPin,
      forcePinChange: forcePinChange,
      minPinLength: minPinLength,
      pinUvAuthProtocols: List.unmodifiable(data.sublist(offset)),
    );
  }
}

/// One relying party with resident credentials.
class WebAuthnRp {
  const WebAuthnRp({required this.id, required this.name, required this.idHash});

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
  final int coseAlgorithm;
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

  int get protocolVersion => _session.protocolVersion();

  Future<void> setPin(String newPin) async =>
      _client._execute(_session.setPin(newPin: utf8.encode(newPin)));

  Future<void> changePin(String oldPin, String newPin) async =>
      _client._execute(
        _session.changePin(
            oldPin: utf8.encode(oldPin), newPin: utf8.encode(newPin)),
      );

  /// Mint a pinUvAuthToken (credentialManagement permission 0x04). The token
  /// outlives this session; close the session once the token exists.
  Future<WebAuthnPinToken> getPinToken(
    String pin, {
    int permissions = WebAuthnCardClient.permissionCredentialManagement,
    String? rpId,
  }) async {
    final token = await _client._executeToken(
      _session.getPinTokenWithPermissions(
        pin: utf8.encode(pin),
        permissions: permissions,
        rpId: rpId,
      ),
    );
    return WebAuthnPinToken._(_client, token);
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

  int get protocolVersion => _token.protocolVersion();

  Future<List<WebAuthnRp>> enumerateRps() async =>
      _decodeRps(await _client._execute(_token.enumerateRps()));

  Future<List<WebAuthnCredential>> enumerateCredentials(
    Uint8List rpIdHash, {
    bool metadataOnly = true,
  }) async => _decodeCredentials(
    await _client._execute(
      _token.enumerateCredentials(
        rpIdHash: rpIdHash,
        metadataOnly: metadataOnly,
      ),
    ),
  );

  /// Permanently delete one resident credential. An unknown ID surfaces as a
  /// NotFound ProtocolException with the raw CTAP status byte; never retried.
  Future<void> deleteCredential(List<int> credentialId) async =>
      _client._execute(_token.deleteCredential(credentialId: credentialId));

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

  /// `id_len | id | name_len (0xff = absent) | name | rp_id_hash[32]` per RP.
  static List<WebAuthnRp> _decodeRps(Uint8List data) {
    final rps = <WebAuthnRp>[];
    var offset = 0;
    int take() {
      if (offset >= data.length) {
        throw const FormatException('Truncated WebAuthn RP entry');
      }
      return data[offset++];
    }

    Uint8List takeBytes(int length, String name) {
      if (length < 0 || data.length - offset < length) {
        throw FormatException('Truncated WebAuthn RP $name');
      }
      final bytes = Uint8List.sublistView(data, offset, offset + length);
      offset += length;
      return bytes;
    }

    while (offset < data.length) {
      final id = utf8.decode(takeBytes(take(), 'id'));
      final nameLength = take();
      final name = nameLength == 0xff
          ? null
          : utf8.decode(takeBytes(nameLength, 'name'));
      rps.add(WebAuthnRp(id: id, name: name, idHash: takeBytes(32, 'hash')));
    }
    return rps;
  }

  /// `cred_id_len u16BE | cred_id | user_flag | [user_id_len | user_id |
  /// name_len (0xff absent) | name | display_len (0xff absent) | display] |
  /// cred_protect (0xff absent) | key_form` per credential; key_form 0x01 is
  /// metadataOnly with a raw i64 COSE algorithm, 0x02 carries the resolved
  /// i64 algorithm plus `key_len u16BE | canonical CBOR key` pass-through.
  static List<WebAuthnCredential> _decodeCredentials(Uint8List data) {
    final credentials = <WebAuthnCredential>[];
    var offset = 0;
    int take() {
      if (offset >= data.length) {
        throw const FormatException('Truncated WebAuthn credential entry');
      }
      return data[offset++];
    }

    Uint8List takeBytes(int length, String name) {
      if (length < 0 || data.length - offset < length) {
        throw FormatException('Truncated WebAuthn credential $name');
      }
      final bytes = Uint8List.sublistView(data, offset, offset + length);
      offset += length;
      return bytes;
    }

    String? takeText(String name) {
      final length = take();
      return length == 0xff ? null : utf8.decode(takeBytes(length, name));
    }

    while (offset < data.length) {
      if (data.length - offset < 2) {
        throw const FormatException('Truncated WebAuthn credential ID length');
      }
      final idLength = (take() << 8) | take();
      final credentialId = takeBytes(idLength, 'ID');
      Uint8List? userId;
      String? userName;
      String? userDisplayName;
      if (take() case 1) {
        userId = takeBytes(take(), 'user ID');
        userName = takeText('user name');
        userDisplayName = takeText('user display name');
      }
      final credProtectByte = take();
      final credProtect = credProtectByte == 0xff ? null : credProtectByte;
      final int coseAlgorithm;
      final Uint8List? publicKey;
      switch (take()) {
        case 0x01:
          if (data.length - offset < 8) {
            throw const FormatException('Truncated WebAuthn COSE algorithm');
          }
          coseAlgorithm = ByteData.sublistView(data).getInt64(offset);
          offset += 8;
          publicKey = null;
        case 0x02:
          if (data.length - offset < 8) {
            throw const FormatException('Truncated WebAuthn COSE algorithm');
          }
          coseAlgorithm = ByteData.sublistView(data).getInt64(offset);
          offset += 8;
          publicKey = takeBytes((take() << 8) | take(), 'public key');
        default:
          throw const FormatException('Unknown WebAuthn credential key form');
      }
      credentials.add(
        WebAuthnCredential(
          credentialId: credentialId,
          userId: userId,
          userName: userName,
          userDisplayName: userDisplayName,
          credProtect: credProtect,
          coseAlgorithm: coseAlgorithm,
          publicKey: publicKey,
        ),
      );
    }
    return credentials;
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

  Future<WebAuthnInfo> getInfo() async =>
      WebAuthnInfo.decode(await _execute(ProtocolOperation.ctapGetInfo()));

  /// Start a ClientPIN session with the protocol preferred by [info]. The
  /// caller closes the returned session after its dependent operations.
  Future<WebAuthnPinSession> beginPinSession(WebAuthnInfo info) async {
    final session = await _executeSession(
      ProtocolOperation.ctapBeginPinSession(protocol: info.pinProtocol),
    );
    return WebAuthnPinSession._(this, session);
  }

  Future<Uint8List> _execute(ProtocolOperation operation) {
    cancellation.check();
    final lease = this.lease;
    // Every CTAP2 client operation selects the FIDO2 applet first.
    lease.willSelectApplet();
    return executeProtocolOperation(
      operation,
      transport,
      lease: lease,
      cancellation: cancellation,
    );
  }

  Future<CtapPinSession> _executeSession(ProtocolOperation operation) {
    cancellation.check();
    final lease = this.lease;
    lease.willSelectApplet();
    return executeCtapPinSession(
      operation,
      transport,
      lease: lease,
      cancellation: cancellation,
    );
  }

  Future<CtapPinToken> _executeToken(ProtocolOperation operation) {
    cancellation.check();
    final lease = this.lease;
    lease.willSelectApplet();
    return executeCtapPinToken(
      operation,
      transport,
      lease: lease,
      cancellation: cancellation,
    );
  }
}
