import 'dart:typed_data';

import 'package:canokey_console/controller/base/polling_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/applet_switches.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/ndef_card.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/screenshot_mode.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/models/ndef.dart';
import 'package:logger/logger.dart';
import 'package:ndef/ndef.dart';

class NdefController extends PollingController {
  static const int defaultMaxMessageLength = 1022;
  final NdefCardClient _client = NdefCardClient();

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
      final cardData = await _client.read();
      if (cardData == null) {
        disabledMessage = AppletSwitches.disabledMessage('NDEF');
        polled = false;
        update();
        return;
      }
      maxMessageLength = cardData.maxMessageLength;
      readOnly = cardData.readOnly;
      try {
        records = NdefDocument.decode(cardData.message).records;
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
        if (!await _client.write(message)) {
          disabledMessage = AppletSwitches.disabledMessage('NDEF');
          polled = false;
          update();
          return;
        }

        dirty = false;
        Prompts.showPrompt(S.current.ndefSaved, ContentThemeColor.success,
            forceSnackBar: true);
        log.i('Successfully wrote ${message.length} bytes of NDEF data');
      });
    } on NdefReadOnlyException {
      Prompts.showPrompt(S.current.ndefReadOnly, ContentThemeColor.danger);
      throw StateError('NDEF file is read-only');
    } finally {
      writing = false;
      update();
    }
  }

  void _markDirty() {
    dirty = true;
    update();
  }

  static String readBinaryApdu(int offset, int length) {
    return NdefCardClient.readBinaryApdu(offset, length);
  }

  static String updateBinaryApdu(int offset, Uint8List data) {
    return NdefCardClient.updateBinaryApdu(offset, data);
  }
}
