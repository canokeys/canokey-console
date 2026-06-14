import 'dart:typed_data';

class KeyboardKeymapPreset {
  final int? id;
  final String name;
  final String localeTag;
  final String description;
  final Uint8List? entries;

  const KeyboardKeymapPreset({
    required this.id,
    required this.name,
    required this.localeTag,
    required this.description,
    required this.entries,
  });

  bool get isDefault => id == null;
}

class KeyboardKeymapState {
  final int? layoutId;
  final Uint8List? entries;
  final KeyboardKeymapPreset? preset;
  final bool isDefault;

  const KeyboardKeymapState({
    required this.layoutId,
    required this.entries,
    required this.preset,
    required this.isDefault,
  });

  bool get isKnownPreset => preset != null;

  String displayName(String defaultLabel, String customLabel) {
    if (isDefault) {
      return defaultLabel;
    }
    if (preset != null) {
      return preset!.name;
    }
    if (layoutId != null) {
      return '$customLabel 0x${layoutId!.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    }
    return customLabel;
  }
}

class KeyboardKeymapPresets {
  static const defaultPreset = KeyboardKeymapPreset(
    id: null,
    name: 'Default / US QWERTY',
    localeTag: 'en-US',
    description: 'Use CanoKey built-in keyboard mapping.',
    entries: null,
  );

  static final presets = <KeyboardKeymapPreset>[
    defaultPreset,
    KeyboardKeymapPreset(
      id: 0x11,
      name: 'UK QWERTY',
      localeTag: 'en-GB',
      description: 'United Kingdom keyboard layout.',
      entries: _buildKeymap(_ukOverrides),
    ),
    KeyboardKeymapPreset(
      id: 0x21,
      name: 'German QWERTZ',
      localeTag: 'de-DE',
      description: 'German keyboard layout.',
      entries: _buildKeymap(_deOverrides),
    ),
    KeyboardKeymapPreset(
      id: 0x22,
      name: 'French AZERTY',
      localeTag: 'fr-FR',
      description: 'French keyboard layout.',
      entries: _buildKeymap(_frOverrides),
    ),
    KeyboardKeymapPreset(
      id: 0x23,
      name: 'Spanish',
      localeTag: 'es-ES',
      description: 'Spanish keyboard layout.',
      entries: _buildKeymap(_esOverrides),
    ),
    KeyboardKeymapPreset(
      id: 0x24,
      name: 'Italian',
      localeTag: 'it-IT',
      description: 'Italian keyboard layout.',
      entries: _buildKeymap(_itOverrides),
    ),
    KeyboardKeymapPreset(
      id: 0x25,
      name: 'Portuguese',
      localeTag: 'pt-PT',
      description: 'Portuguese keyboard layout.',
      entries: _buildKeymap(_ptOverrides),
    ),
    KeyboardKeymapPreset(
      id: 0x31,
      name: 'Swedish',
      localeTag: 'sv-SE',
      description: 'Swedish keyboard layout.',
      entries: _buildKeymap(_seOverrides),
    ),
    KeyboardKeymapPreset(
      id: 0x32,
      name: 'Finnish',
      localeTag: 'fi-FI',
      description: 'Finnish keyboard layout.',
      entries: _buildKeymap(_fiOverrides),
    ),
    KeyboardKeymapPreset(
      id: 0x33,
      name: 'Danish',
      localeTag: 'da-DK',
      description: 'Danish keyboard layout.',
      entries: _buildKeymap(_dkOverrides),
    ),
    KeyboardKeymapPreset(
      id: 0x34,
      name: 'Norwegian',
      localeTag: 'nb-NO',
      description: 'Norwegian keyboard layout.',
      entries: _buildKeymap(_noOverrides),
    ),
    KeyboardKeymapPreset(
      id: 0x41,
      name: 'Belgian AZERTY',
      localeTag: 'fr-BE',
      description: 'Belgian keyboard layout.',
      entries: _buildKeymap(_beOverrides),
    ),
    KeyboardKeymapPreset(
      id: 0x42,
      name: 'Swiss German',
      localeTag: 'de-CH',
      description: 'Swiss German keyboard layout.',
      entries: _buildKeymap(_chDeOverrides),
    ),
    KeyboardKeymapPreset(
      id: 0x43,
      name: 'Swiss French',
      localeTag: 'fr-CH',
      description: 'Swiss French keyboard layout.',
      entries: _buildKeymap(_chFrOverrides),
    ),
  ];

  static KeyboardKeymapPreset? findById(int id) {
    for (final preset in presets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }

  static KeyboardKeymapPreset? findMatching(int id, Uint8List entries) {
    final preset = findById(id);
    if (preset == null || preset.entries == null) {
      return null;
    }
    return _listEquals(preset.entries!, entries) ? preset : null;
  }

  static String? validateEntries(Uint8List entries) {
    if (entries.length != 256) {
      return 'Keyboard keymap must contain 256 bytes.';
    }
    for (var ascii = 32; ascii <= 126; ascii++) {
      if (entries[ascii * 2 + 1] == 0) {
        return 'Keyboard keymap is missing ASCII 0x${ascii.toRadixString(16).padLeft(2, '0').toUpperCase()}.';
      }
    }
    return null;
  }

  static Uint8List _buildKeymap(Map<int, _Key> overrides) {
    final entries = Uint8List(256);
    for (final item in _usEntries.entries) {
      entries[item.key * 2] = item.value.modifier;
      entries[item.key * 2 + 1] = item.value.usage;
    }
    for (final item in overrides.entries) {
      entries[item.key * 2] = item.value.modifier;
      entries[item.key * 2 + 1] = item.value.usage;
    }
    return entries;
  }

  static bool _listEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  static final Map<int, _Key> _usEntries = _buildUsEntries();

  static Map<int, _Key> _buildUsEntries() {
    final map = <int, _Key>{};
    for (var ch = 0x31; ch <= 0x39; ch++) {
      map[ch] = _Key(0, 0x1E + ch - 0x31);
    }
    map[0x30] = const _Key(0, 0x27);
    for (var ch = 0x61; ch <= 0x7A; ch++) {
      map[ch] = _Key(0, 0x04 + ch - 0x61);
      map[ch - 0x20] = _Key(_shift, 0x04 + ch - 0x61);
    }
    map.addAll({
      0x0D: const _Key(0, 0x28),
      0x20: const _Key(0, 0x2C),
      0x21: const _Key(_shift, 0x1E),
      0x22: const _Key(_shift, 0x34),
      0x23: const _Key(_shift, 0x20),
      0x24: const _Key(_shift, 0x21),
      0x25: const _Key(_shift, 0x22),
      0x26: const _Key(_shift, 0x24),
      0x27: const _Key(0, 0x34),
      0x28: const _Key(_shift, 0x26),
      0x29: const _Key(_shift, 0x27),
      0x2A: const _Key(_shift, 0x25),
      0x2B: const _Key(_shift, 0x2E),
      0x2C: const _Key(0, 0x36),
      0x2D: const _Key(0, 0x2D),
      0x2E: const _Key(0, 0x37),
      0x2F: const _Key(0, 0x38),
      0x3A: const _Key(_shift, 0x33),
      0x3B: const _Key(0, 0x33),
      0x3C: const _Key(_shift, 0x36),
      0x3D: const _Key(0, 0x2E),
      0x3E: const _Key(_shift, 0x37),
      0x3F: const _Key(_shift, 0x38),
      0x40: const _Key(_shift, 0x1F),
      0x5B: const _Key(0, 0x2F),
      0x5C: const _Key(0, 0x31),
      0x5D: const _Key(0, 0x30),
      0x5E: const _Key(_shift, 0x23),
      0x5F: const _Key(_shift, 0x2D),
      0x60: const _Key(0, 0x35),
      0x7B: const _Key(_shift, 0x2F),
      0x7C: const _Key(_shift, 0x31),
      0x7D: const _Key(_shift, 0x30),
      0x7E: const _Key(_shift, 0x35),
    });
    return map;
  }

  static const int _shift = 0x02;
  static const int _altGr = 0x40;
  static const int _shiftAltGr = 0x42;

  static const Map<int, _Key> _ukOverrides = {
    0x22: _Key(_shift, 0x1F), // "
    0x23: _Key(0, 0x32), // #
    0x40: _Key(_shift, 0x34), // @
    0x5C: _Key(0, 0x64), // backslash
    0x7C: _Key(_shift, 0x64), // |
    0x7E: _Key(_shift, 0x32), // ~
  };

  static const Map<int, _Key> _deOverrides = {
    0x22: _Key(_shift, 0x1F), // "
    0x23: _Key(0, 0x31), // #
    0x26: _Key(_shift, 0x23), // &
    0x27: _Key(_shift, 0x31), // '
    0x28: _Key(_shift, 0x25), // (
    0x29: _Key(_shift, 0x26), // )
    0x2A: _Key(_shift, 0x30), // *
    0x2B: _Key(0, 0x30), // +
    0x2D: _Key(0, 0x38), // -
    0x2F: _Key(_shift, 0x24), // /
    0x3A: _Key(_shift, 0x37), // :
    0x3B: _Key(_shift, 0x36), // ;
    0x3C: _Key(0, 0x64), // <
    0x3D: _Key(_shift, 0x27), // =
    0x3E: _Key(_shift, 0x64), // >
    0x3F: _Key(_shift, 0x2D), // ?
    0x40: _Key(_altGr, 0x14), // @
    0x59: _Key(_shift, 0x1D), // Y
    0x5A: _Key(_shift, 0x1C), // Z
    0x5B: _Key(_altGr, 0x25), // [
    0x5C: _Key(_altGr, 0x2D), // backslash
    0x5D: _Key(_altGr, 0x26), // ]
    0x5E: _Key(0, 0x35), // ^
    0x5F: _Key(_shift, 0x38), // _
    0x60: _Key(_shift, 0x2E), // `
    0x79: _Key(0, 0x1D), // y
    0x7A: _Key(0, 0x1C), // z
    0x7B: _Key(_altGr, 0x24), // {
    0x7C: _Key(_altGr, 0x64), // |
    0x7D: _Key(_altGr, 0x27), // }
    0x7E: _Key(_altGr, 0x30), // ~
  };

  static const Map<int, _Key> _frOverrides = {
    0x21: _Key(0, 0x38), // !
    0x22: _Key(0, 0x20), // "
    0x23: _Key(_altGr, 0x20), // #
    0x24: _Key(0, 0x30), // $
    0x25: _Key(_shift, 0x34), // %
    0x26: _Key(0, 0x1E), // &
    0x27: _Key(0, 0x21), // '
    0x28: _Key(0, 0x22), // (
    0x29: _Key(0, 0x2D), // )
    0x2A: _Key(0, 0x31), // *
    0x2B: _Key(_shift, 0x2E), // +
    0x2C: _Key(0, 0x10), // ,
    0x2D: _Key(0, 0x23), // -
    0x2E: _Key(_shift, 0x36), // .
    0x2F: _Key(_shift, 0x37), // /
    0x30: _Key(_shift, 0x27), // 0
    0x31: _Key(_shift, 0x1E), // 1
    0x32: _Key(_shift, 0x1F), // 2
    0x33: _Key(_shift, 0x20), // 3
    0x34: _Key(_shift, 0x21), // 4
    0x35: _Key(_shift, 0x22), // 5
    0x36: _Key(_shift, 0x23), // 6
    0x37: _Key(_shift, 0x24), // 7
    0x38: _Key(_shift, 0x25), // 8
    0x39: _Key(_shift, 0x26), // 9
    0x3A: _Key(0, 0x37), // :
    0x3B: _Key(0, 0x36), // ;
    0x3C: _Key(0, 0x64), // <
    0x3D: _Key(0, 0x2E), // =
    0x3E: _Key(_shift, 0x64), // >
    0x3F: _Key(_shift, 0x10), // ?
    0x40: _Key(_altGr, 0x27), // @
    0x41: _Key(_shift, 0x14), // A
    0x4D: _Key(_shift, 0x33), // M
    0x51: _Key(_shift, 0x04), // Q
    0x57: _Key(_shift, 0x1D), // W
    0x5A: _Key(_shift, 0x1A), // Z
    0x5B: _Key(_altGr, 0x22), // [
    0x5C: _Key(_altGr, 0x25), // backslash
    0x5D: _Key(_altGr, 0x2D), // ]
    0x5E: _Key(_altGr, 0x26), // ^
    0x5F: _Key(0, 0x25), // _
    0x60: _Key(_altGr, 0x24), // `
    0x61: _Key(0, 0x14), // a
    0x6D: _Key(0, 0x33), // m
    0x71: _Key(0, 0x04), // q
    0x77: _Key(0, 0x1D), // w
    0x7A: _Key(0, 0x1A), // z
    0x7B: _Key(_altGr, 0x21), // {
    0x7C: _Key(_altGr, 0x23), // |
    0x7D: _Key(_altGr, 0x2E), // }
    0x7E: _Key(_altGr, 0x1F), // ~
  };

  static const Map<int, _Key> _esOverrides = {
    0x22: _Key(_shift, 0x1F), // "
    0x23: _Key(_altGr, 0x20), // #
    0x26: _Key(_shift, 0x23), // &
    0x27: _Key(0, 0x2D), // '
    0x28: _Key(_shift, 0x25), // (
    0x29: _Key(_shift, 0x26), // )
    0x2A: _Key(_shift, 0x30), // *
    0x2B: _Key(0, 0x30), // +
    0x2D: _Key(0, 0x38), // -
    0x2F: _Key(_shift, 0x24), // /
    0x3A: _Key(_shift, 0x37), // :
    0x3B: _Key(_shift, 0x36), // ;
    0x3D: _Key(_shift, 0x27), // =
    0x3F: _Key(_shift, 0x2D), // ?
    0x40: _Key(_altGr, 0x1F), // @
    0x5B: _Key(_altGr, 0x2F), // [
    0x5C: _Key(_altGr, 0x2D), // backslash
    0x5D: _Key(_altGr, 0x30), // ]
    0x5E: _Key(_shift, 0x2F), // ^
    0x5F: _Key(_shift, 0x38), // _
    0x60: _Key(0, 0x2F), // `
    0x7B: _Key(_altGr, 0x34), // {
    0x7C: _Key(_altGr, 0x1E), // |
    0x7D: _Key(_altGr, 0x31), // }
    0x7E: _Key(_altGr, 0x33), // ~
  };

  static const Map<int, _Key> _itOverrides = {
    0x22: _Key(_shift, 0x1F), // "
    0x23: _Key(_altGr, 0x34), // #
    0x26: _Key(_shift, 0x23), // &
    0x27: _Key(0, 0x2D), // '
    0x28: _Key(_shift, 0x25), // (
    0x29: _Key(_shift, 0x26), // )
    0x2A: _Key(_shift, 0x30), // *
    0x2B: _Key(0, 0x30), // +
    0x2D: _Key(0, 0x38), // -
    0x2F: _Key(_shift, 0x24), // /
    0x3A: _Key(_shift, 0x37), // :
    0x3B: _Key(_shift, 0x36), // ;
    0x3C: _Key(0, 0x64), // <
    0x3D: _Key(_shift, 0x27), // =
    0x3E: _Key(_shift, 0x64), // >
    0x3F: _Key(_shift, 0x2D), // ?
    0x40: _Key(_altGr, 0x33), // @
    0x5B: _Key(_altGr, 0x2F), // [
    0x5C: _Key(0, 0x35), // backslash
    0x5D: _Key(_altGr, 0x30), // ]
    0x5E: _Key(_shift, 0x2E), // ^
    0x5F: _Key(_shift, 0x38), // _
    0x60: _Key(_altGr, 0x31), // `
    0x7B: _Key(_shiftAltGr, 0x2F), // {
    0x7C: _Key(_shift, 0x35), // |
    0x7D: _Key(_altGr, 0x27), // }
    0x7E: _Key(_altGr, 0x2E), // ~
  };

  static const Map<int, _Key> _ptOverrides = {
    0x22: _Key(_altGr, 0x2F), // "
    0x26: _Key(_shift, 0x23), // &
    0x27: _Key(0, 0x2D), // '
    0x28: _Key(_shift, 0x25), // (
    0x29: _Key(_shift, 0x26), // )
    0x2A: _Key(_shift, 0x2F), // *
    0x2B: _Key(0, 0x2F), // +
    0x2D: _Key(0, 0x38), // -
    0x2F: _Key(_shift, 0x24), // /
    0x3A: _Key(_shift, 0x37), // :
    0x3B: _Key(_shift, 0x36), // ;
    0x3C: _Key(0, 0x64), // <
    0x3D: _Key(_shift, 0x27), // =
    0x3E: _Key(_shift, 0x64), // >
    0x3F: _Key(_shift, 0x2D), // ?
    0x40: _Key(_altGr, 0x1F), // @
    0x5B: _Key(_altGr, 0x25), // [
    0x5C: _Key(_altGr, 0x64), // backslash
    0x5D: _Key(_altGr, 0x26), // ]
    0x5E: _Key(_altGr, 0x34), // ^
    0x5F: _Key(_shift, 0x38), // _
    0x60: _Key(_shift, 0x30), // `
    0x7B: _Key(_altGr, 0x24), // {
    0x7C: _Key(_shift, 0x35), // |
    0x7D: _Key(_altGr, 0x27), // }
    0x7E: _Key(0, 0x31), // ~
  };

  static const Map<int, _Key> _seOverrides = {
    0x24: _Key(_altGr, 0x21), // $
    0x26: _Key(_shift, 0x23), // &
    0x27: _Key(0, 0x31), // '
    0x28: _Key(_shift, 0x25), // (
    0x29: _Key(_shift, 0x26), // )
    0x2A: _Key(_shift, 0x31), // *
    0x2B: _Key(0, 0x2D), // +
    0x2D: _Key(0, 0x38), // -
    0x2F: _Key(_shift, 0x24), // /
    0x3A: _Key(_shift, 0x37), // :
    0x3B: _Key(_shift, 0x36), // ;
    0x3C: _Key(0, 0x64), // <
    0x3E: _Key(_shift, 0x64), // >
    0x3F: _Key(_shift, 0x2D), // ?
    0x40: _Key(_altGr, 0x1F), // @
    0x5B: _Key(_altGr, 0x25), // [
    0x5C: _Key(_altGr, 0x2D), // backslash
    0x5D: _Key(_altGr, 0x26), // ]
    0x5E: _Key(_shift, 0x30), // ^
    0x5F: _Key(_shift, 0x38), // _
    0x60: _Key(_shift, 0x2E), // `
    0x7B: _Key(_altGr, 0x24), // {
    0x7C: _Key(_altGr, 0x64), // |
    0x7D: _Key(_altGr, 0x27), // }
    0x7E: _Key(_altGr, 0x30), // ~
  };

  static const Map<int, _Key> _fiOverrides = {
    ..._seOverrides,
    0x22: _Key(_shift, 0x1F), // "
    0x3D: _Key(_shift, 0x27), // =
  };

  static final Map<int, _Key> _dkOverrides = {
    ..._fiOverrides,
    0x5C: _Key(_altGr, 0x64), // backslash
    0x5E: _Key(_altGr, 0x34), // ^
    0x7C: _Key(_altGr, 0x2E), // |
  };

  static final Map<int, _Key> _noOverrides = {
    ..._fiOverrides,
    0x5C: _Key(0, 0x2E), // backslash
    0x5E: _Key(_altGr, 0x34), // ^
    0x7C: _Key(0, 0x35), // |
  };

  static const Map<int, _Key> _beOverrides = {
    0x21: _Key(0, 0x25), // !
    0x22: _Key(0, 0x20), // "
    0x23: _Key(_altGr, 0x20), // #
    0x24: _Key(0, 0x30), // $
    0x25: _Key(_shift, 0x34), // %
    0x26: _Key(0, 0x1E), // &
    0x27: _Key(_altGr, 0x34), // '
    0x28: _Key(0, 0x22), // (
    0x29: _Key(0, 0x2D), // )
    0x2A: _Key(_shift, 0x30), // *
    0x2B: _Key(_shift, 0x38), // +
    0x2C: _Key(0, 0x10), // ,
    0x2D: _Key(0, 0x2E), // -
    0x2E: _Key(_shift, 0x36), // .
    0x2F: _Key(_shift, 0x37), // /
    0x30: _Key(_shift, 0x27), // 0
    0x31: _Key(_shift, 0x1E), // 1
    0x32: _Key(_shift, 0x1F), // 2
    0x33: _Key(_shift, 0x20), // 3
    0x34: _Key(_shift, 0x21), // 4
    0x35: _Key(_shift, 0x22), // 5
    0x36: _Key(_shift, 0x23), // 6
    0x37: _Key(_shift, 0x24), // 7
    0x38: _Key(_shift, 0x25), // 8
    0x39: _Key(_shift, 0x26), // 9
    0x3A: _Key(0, 0x37), // :
    0x3B: _Key(0, 0x36), // ;
    0x3C: _Key(_shiftAltGr, 0x1D), // <
    0x3D: _Key(0, 0x38), // =
    0x3E: _Key(_shift, 0x64), // >
    0x3F: _Key(_shift, 0x10), // ?
    0x40: _Key(_altGr, 0x14), // @
    0x41: _Key(_shift, 0x14), // A
    0x4D: _Key(_shift, 0x33), // M
    0x51: _Key(_shift, 0x04), // Q
    0x57: _Key(_shift, 0x1D), // W
    0x5A: _Key(_shift, 0x1A), // Z
    0x5B: _Key(_altGr, 0x2F), // [
    0x5C: _Key(_altGr, 0x64), // backslash
    0x5D: _Key(_altGr, 0x30), // ]
    0x5E: _Key(0, 0x2F), // ^
    0x5F: _Key(_shift, 0x2E), // _
    0x60: _Key(_altGr, 0x31), // `
    0x61: _Key(0, 0x14), // a
    0x6D: _Key(0, 0x33), // m
    0x71: _Key(0, 0x04), // q
    0x77: _Key(0, 0x1D), // w
    0x7A: _Key(0, 0x1A), // z
    0x7B: _Key(_altGr, 0x26), // {
    0x7C: _Key(_altGr, 0x1E), // |
    0x7D: _Key(_altGr, 0x27), // }
    0x7E: _Key(_altGr, 0x38), // ~
  };

  static const Map<int, _Key> _chDeOverrides = {
    0x21: _Key(_shift, 0x30), // !
    0x22: _Key(_shift, 0x1F), // "
    0x23: _Key(_altGr, 0x20), // #
    0x24: _Key(0, 0x31), // $
    0x26: _Key(_shift, 0x23), // &
    0x27: _Key(0, 0x2D), // '
    0x28: _Key(_shift, 0x25), // (
    0x29: _Key(_shift, 0x26), // )
    0x2A: _Key(_shift, 0x20), // *
    0x2B: _Key(_shift, 0x1E), // +
    0x2D: _Key(0, 0x38), // -
    0x2F: _Key(_shift, 0x24), // /
    0x3A: _Key(_shift, 0x37), // :
    0x3B: _Key(_shift, 0x36), // ;
    0x3C: _Key(0, 0x64), // <
    0x3D: _Key(_shift, 0x27), // =
    0x3E: _Key(_shift, 0x64), // >
    0x3F: _Key(_shift, 0x2D), // ?
    0x40: _Key(_altGr, 0x1F), // @
    0x59: _Key(_shift, 0x1D), // Y
    0x5A: _Key(_shift, 0x1C), // Z
    0x5B: _Key(_altGr, 0x2F), // [
    0x5C: _Key(_altGr, 0x64), // backslash
    0x5D: _Key(_altGr, 0x30), // ]
    0x5E: _Key(0, 0x2E), // ^
    0x5F: _Key(_shift, 0x38), // _
    0x60: _Key(_shift, 0x2E), // `
    0x79: _Key(0, 0x1D), // y
    0x7A: _Key(0, 0x1C), // z
    0x7B: _Key(_altGr, 0x34), // {
    0x7C: _Key(_altGr, 0x24), // |
    0x7D: _Key(_altGr, 0x31), // }
    0x7E: _Key(_altGr, 0x2E), // ~
  };

  static const Map<int, _Key> _chFrOverrides = _chDeOverrides;
}

class _Key {
  final int modifier;
  final int usage;

  const _Key(this.modifier, this.usage);
}
