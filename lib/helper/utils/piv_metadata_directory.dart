import 'package:canokey_console/models/piv.dart';

class PivMetadataDirectoryEntry {
  static const int keyFlag = 0x01;
  static const int certificateFlag = 0x02;

  final int slot;
  final int flags;
  final int algorithmId;
  final Origin? origin;
  final PinPolicy? pinPolicy;
  final TouchPolicy? touchPolicy;

  const PivMetadataDirectoryEntry({
    required this.slot,
    required this.flags,
    required this.algorithmId,
    required this.origin,
    required this.pinPolicy,
    required this.touchPolicy,
  });

  bool get hasKey => flags & keyFlag != 0;
  bool get hasCertificate => flags & certificateFlag != 0;

  SlotInfo toSlotInfo(PivAlgorithmExtensionConfig config) {
    if (!hasKey || origin == null || pinPolicy == null || touchPolicy == null) {
      throw StateError('PIV directory entry does not contain a key');
    }
    final algorithm = config.enabled
        ? (config.toAlgorithmMap()[algorithmId] ??
            AlgorithmType.fromValue(algorithmId))
        : AlgorithmType.fromValue(algorithmId);
    return SlotInfo(
      slot,
      algorithm,
      pinPolicy!,
      touchPolicy!,
      origin!,
      const [],
      false,
      0,
      0,
    );
  }
}

class PivMetadataDirectory {
  static const int supportedVersion = 1;
  static const int _headerLength = 5;
  static const int _entryLength = 6;

  final int version;
  final List<PivMetadataDirectoryEntry> entries;

  const PivMetadataDirectory({
    required this.version,
    required this.entries,
  });

  factory PivMetadataDirectory.parse(List<int> data) {
    if (data.length < _headerLength ||
        data[0] != 0x01 ||
        data[1] != 0x01 ||
        data[3] != 0x02) {
      throw const FormatException('Invalid PIV metadata directory header');
    }

    final version = data[2];
    if (version != supportedVersion) {
      throw UnsupportedError(
          'Unsupported PIV metadata directory version: $version');
    }

    final payloadLength = data[4];
    if (payloadLength % _entryLength != 0 ||
        data.length != _headerLength + payloadLength) {
      throw const FormatException('Invalid PIV metadata directory length');
    }

    final entries = <PivMetadataDirectoryEntry>[];
    final slots = <int>{};
    for (var offset = _headerLength;
        offset < data.length;
        offset += _entryLength) {
      final slot = data[offset];
      final flags = data[offset + 1];
      if (!_isKeySlot(slot) ||
          flags == 0 ||
          flags &
                  ~(PivMetadataDirectoryEntry.keyFlag |
                      PivMetadataDirectoryEntry.certificateFlag) !=
              0 ||
          !slots.add(slot)) {
        throw const FormatException('Invalid PIV metadata directory entry');
      }

      final hasKey = flags & PivMetadataDirectoryEntry.keyFlag != 0;
      final algorithmId = data[offset + 2];
      final origin = data[offset + 3];
      final pinPolicy = data[offset + 4];
      final touchPolicy = data[offset + 5];
      if (!hasKey &&
          (algorithmId != 0 ||
              origin != 0 ||
              pinPolicy != 0 ||
              touchPolicy != 0)) {
        throw const FormatException(
            'Certificate-only PIV directory entry contains key metadata');
      }

      entries.add(PivMetadataDirectoryEntry(
        slot: slot,
        flags: flags,
        algorithmId: algorithmId,
        origin: hasKey ? Origin.fromValue(origin) : null,
        pinPolicy: hasKey ? PinPolicy.fromValue(pinPolicy) : null,
        touchPolicy: hasKey ? TouchPolicy.fromValue(touchPolicy) : null,
      ));
    }

    return PivMetadataDirectory(version: version, entries: entries);
  }

  static bool _isKeySlot(int slot) =>
      slot == 0x9A ||
      slot == 0x9C ||
      slot == 0x9D ||
      slot == 0x9E ||
      (slot >= 0x82 && slot <= 0x95);
}
