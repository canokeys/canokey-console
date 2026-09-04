import 'package:canokey_console/helper/utils/apdu_transport.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/pass.dart';
import 'package:convert/convert.dart';

class PassCardClient {
  PassCardClient({
    ApduTransport transport = const SmartCardApduTransport(),
  }) : _transport = transport;

  final ApduTransport _transport;
  String? lastStatusWord;

  Future<List<PassSlot>> readSlots() async {
    final response = await _transport.transceive('0043000000');
    lastStatusWord = SmartCard.sw(response);
    SmartCard.assertOK(response);
    return PassSlot.fromData(SmartCard.dropSW(response));
  }

  Future<bool> setSlot(
    int index,
    PassSlotType type,
    String password,
    bool withEnter,
  ) async {
    final data = switch (type) {
      PassSlotType.none => '00',
      PassSlotType.static =>
        '02${password.length.toRadixString(16).padLeft(2, '0')}'
            '${hex.encode(password.codeUnits)}${withEnter ? '01' : '00'}',
      PassSlotType.hmacSha1 => '0314$password',
      PassSlotType.oath => throw ArgumentError.value(
          type,
          'type',
          'OATH slots are configured by the OATH applet',
        ),
    };
    final slot = index == 1 ? '01' : '02';
    final response = await _transport.transceive(
      '0044${slot}00${(data.length ~/ 2).toRadixString(16).padLeft(2, '0')}$data',
    );
    lastStatusWord = SmartCard.sw(response);
    return SmartCard.isOK(response);
  }
}
