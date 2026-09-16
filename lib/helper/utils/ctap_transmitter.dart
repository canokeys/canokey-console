import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/card_session.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/src/rust/api/protocol.dart';
import 'package:fido2/fido2.dart';

/// libcanokey-backed CTAP transport. The facade owns the APDU envelope
/// (extended Lc or CLA chaining) and GET RESPONSE continuation; this layer
/// only selects the FIDO2 applet once per lease and forwards raw CTAP
/// messages. A non-zero CTAP status byte is data for the fido2 package,
/// never a transport error.
class CtapTransmitter extends CtapDevice {
  CtapTransmitter({
    ApduTransport transport = const SmartCardApduTransport(),
    CardLease? lease,
  }) : _transport = transport,
       _injectedLease = lease {
    if (lease != null && transport is SmartCardApduTransport) {
      throw ArgumentError('Production transport uses SmartCard.currentLease');
    }
  }

  final ApduTransport _transport;
  final CardLease? _injectedLease;

  /// The card's selected applet is global to the physical lease, so the
  /// selection evidence is shared by every transmitter on that lease.
  static CardLease? _selectedLease;
  bool _selectedWithoutLease = false;

  CardLease? get _lease => _transport is SmartCardApduTransport
      ? SmartCard.currentLease
      : _injectedLease;

  bool get _isSelected {
    final lease = _lease;
    return lease != null
        ? identical(_selectedLease, lease)
        : _selectedWithoutLease;
  }

  /// Explicit FIDO2 selection through libcanokey; an absent applet surfaces
  /// as UnsupportedDevice instead of a raw 6A82 status word.
  Future<void> selectApplication() async {
    final lease = _lease;
    lease?.willSelectApplet();
    await executeProtocolOperation(
      ProtocolOperation.ctapSelectApplication(),
      _transport,
      lease: lease,
    );
    if (lease != null) {
      _selectedLease = lease;
    } else {
      _selectedWithoutLease = true;
    }
  }

  @override
  Future<CtapResponse<List<int>>> transceive(List<int> command) async {
    if (!_isSelected) {
      await selectApplication();
    }
    final data = await executeProtocolOperation(
      ProtocolOperation.ctapTransceiveSelected(message: command),
      _transport,
      lease: _lease,
    );
    return CtapResponse(data.first, data.sublist(1));
  }
}
