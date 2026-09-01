import 'dart:math';
import 'dart:typed_data';

import 'package:canokey_console/controller/base/polling_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/applet_switches.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/screenshot_mode.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/ndef.dart';
import 'package:convert/convert.dart';
import 'package:logger/logger.dart';
import 'package:ndef/ndef.dart';

class NdefController extends PollingController {
  static const int defaultMaxMessageLength = 1022;
  static const int _chunkSize = 240;
  static const String _selectApplet = '00A4040007D2760000850101';
  static const String _selectCapabilityContainer = '00A4000C02E103';
  static const String _selectNdefFile = '00A4000C020001';

  List<NDEFRecord> records = [];
  int maxMessageLength = defaultMaxMessageLength;
  bool readOnly = false;
  bool dirty = false;
  bool writing = false;
  String? disabledMessage;
  String? decodeError;

  @override
  Logger get log => Logging.logger('NDEF:Controller');

  int get messageLength {
    try {
      return NdefDocument(records).encodedLength;
    } catch (_) {
      return maxMessageLength + 1;
    }
  }

  bool get exceedsCapacity => messageLength > maxMessageLength;

  bool get canEdit => polled && !readOnly && decodeError == null && !writing;

  bool get canSave => canEdit && dirty && !exceedsCapacity;

  @override
  Future<void> doRefreshData() async {
    if (ScreenshotMode.enabled) {
      records = ScreenshotMode.ndefRecords();
      maxMessageLength = defaultMaxMessageLength;
      readOnly = false;
      dirty = false;
      writing = false;
      disabledMessage = null;
      decodeError = null;
      polled = true;
      update();
      return;
    }

    await SmartCard.process((_) async {
      if (!await _selectNdefApplet()) return;

      final cc = await _readCapabilityContainer();
      final fileLength = (cc[11] << 8) | cc[12];
      if (fileLength < 2) {
        throw const FormatException('Invalid NDEF file capacity');
      }
      maxMessageLength = fileLength - 2;
      readOnly = cc[14] != 0x00;

      SmartCard.assertOK(await SmartCard.transceive(_selectNdefFile));
      final lengthData = await _readBytes(0, 2);
      final ndefLength = (lengthData[0] << 8) | lengthData[1];
      if (ndefLength > maxMessageLength) {
        throw FormatException(
            'NDEF message length $ndefLength exceeds $maxMessageLength');
      }

      final message = await _readBytes(2, ndefLength);
      try {
        records = NdefDocument.decode(message).records;
        decodeError = null;
      } catch (error, stackTrace) {
        records = [];
        decodeError = S.current.ndefInvalidMessage;
        log.w('Failed to decode NDEF message',
            error: error, stackTrace: stackTrace);
      }

      disabledMessage = null;
      dirty = false;
      polled = true;
      update();
    });
  }

  void addRecord(NDEFRecord record) {
    records.add(record);
    _markDirty();
  }

  void updateRecord(int index, NDEFRecord record) {
    records[index] = record;
    _markDirty();
  }

  void removeRecord(int index) {
    records.removeAt(index);
    _markDirty();
  }

  void moveRecord(int from, int to) {
    if (from == to || from < 0 || from >= records.length) return;
    if (to < 0 || to >= records.length) return;
    final record = records.removeAt(from);
    records.insert(to, record);
    _markDirty();
  }

  Future<void> save() async {
    if (!canSave) return;

    final message = NdefDocument(records).encode();
    if (message.length > maxMessageLength) {
      Prompts.showPrompt(
          S.current.ndefCapacityExceeded, ContentThemeColor.danger);
      return;
    }

    writing = true;
    update();
    try {
      await SmartCard.process((_) async {
        if (!await _selectNdefApplet()) return;
        SmartCard.assertOK(await SmartCard.transceive(_selectNdefFile));

        // NLEN is committed last so readers never observe a partial message.
        await _updateBytes(0, Uint8List.fromList([0, 0]));
        for (var offset = 0; offset < message.length; offset += _chunkSize) {
          final end = min(offset + _chunkSize, message.length);
          await _updateBytes(2 + offset, message.sublist(offset, end));
        }
        await _updateBytes(
          0,
          Uint8List.fromList([message.length >> 8, message.length & 0xff]),
        );

        dirty = false;
        Prompts.showPrompt(S.current.ndefSaved, ContentThemeColor.success,
            forceSnackBar: true);
        log.i('Successfully wrote ${message.length} bytes of NDEF data');
      });
    } finally {
      writing = false;
      update();
    }
  }

  void _markDirty() {
    dirty = true;
    update();
  }

  Future<bool> _selectNdefApplet() async {
    final response = await SmartCard.transceive(_selectApplet);
    if (SmartCard.sw(response) == '6A82') {
      disabledMessage = AppletSwitches.disabledMessage('NDEF');
      polled = false;
      update();
      return false;
    }
    SmartCard.assertOK(response);
    return true;
  }

  Future<Uint8List> _readCapabilityContainer() async {
    SmartCard.assertOK(await SmartCard.transceive(_selectCapabilityContainer));
    final cc = await _readBytes(0, 15);
    if (cc.length != 15 || cc[7] != 0x04 || cc[8] != 0x06) {
      throw const FormatException('Invalid NDEF capability container');
    }
    return cc;
  }

  Future<Uint8List> _readBytes(int offset, int length) async {
    final result = <int>[];
    for (var cursor = 0; cursor < length; cursor += _chunkSize) {
      final count = min(_chunkSize, length - cursor);
      final response =
          await SmartCard.transceive(readBinaryApdu(offset + cursor, count));
      SmartCard.assertOK(response);
      result.addAll(hex.decode(SmartCard.dropSW(response)));
    }
    return Uint8List.fromList(result);
  }

  Future<void> _updateBytes(int offset, Uint8List data) async {
    if (data.isEmpty) return;
    final response = await SmartCard.transceive(updateBinaryApdu(offset, data));
    if (SmartCard.sw(response) == '6982') {
      Prompts.showPrompt(S.current.ndefReadOnly, ContentThemeColor.danger);
      throw StateError('NDEF file is read-only');
    }
    SmartCard.assertOK(response);
  }

  static String readBinaryApdu(int offset, int length) {
    if (offset < 0 || offset > 0xffff || length < 1 || length > 0xff) {
      throw RangeError('Invalid READ BINARY range');
    }
    return '00B0${offset.toRadixString(16).padLeft(4, '0')}'
            '${length.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  static String updateBinaryApdu(int offset, Uint8List data) {
    if (offset < 0 || offset > 0xffff || data.isEmpty || data.length > 0xff) {
      throw RangeError('Invalid UPDATE BINARY range');
    }
    return '00D6${offset.toRadixString(16).padLeft(4, '0')}'
            '${data.length.toRadixString(16).padLeft(2, '0')}'
            '${hex.encode(data)}'
        .toUpperCase();
  }
}
