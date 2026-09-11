import 'package:canokey_console/models/piv.dart';
import 'package:canokey_console/models/piv_self_sign_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generic settings omit new extensions', () {
    final options = PivSelfSignOptions(
      slotNumber: '9A',
      pinPolicy: PinPolicy.always,
    );
    expect(options.includeBasicConstraints, isFalse);
    expect(options.keyUsage, 0);
    expect(options.extendedKeyUsage, isEmpty);
    expect(options.matchesMacOsLogin, isFalse);
  });

  test('macOS preset replaces incompatible settings and preserves touch', () {
    final options =
        PivSelfSignOptions(slotNumber: '9A', pinPolicy: PinPolicy.never)
          ..algorithm = AlgorithmType.ed25519
          ..touchPolicy = TouchPolicy.always
          ..keyUsage = 16
          ..extendedKeyUsage.add('1.3.6.1.5.5.7.3.1');
    options.applyMacOsLogin();
    expect(options.algorithm, AlgorithmType.eccp256);
    expect(options.pinPolicy, PinPolicy.once);
    expect(options.touchPolicy, TouchPolicy.always);
    expect(options.matchesMacOsLogin, isTrue);
    options.keyUsage |= 2;
    expect(options.matchesMacOsLogin, isFalse);
    options.applyMacOsLogin();
    expect(options.matchesMacOsLogin, isTrue);
  });

  test(
    'macOS preset preserves compatible RSA and detects changed policies',
    () {
      final options = PivSelfSignOptions(
        slotNumber: '9A',
        pinPolicy: PinPolicy.always,
      )..algorithm = AlgorithmType.rsa2048;
      options.applyMacOsLogin();
      expect(options.algorithm, AlgorithmType.rsa2048);
      options.pinPolicy = PinPolicy.always;
      expect(options.matchesMacOsLogin, isFalse);
    },
  );
  test('9D gets the wrapping usage for its algorithm, without clientAuth', () {
    for (final algorithm in [AlgorithmType.eccp256, AlgorithmType.rsa2048]) {
      final options =
          PivSelfSignOptions(slotNumber: '9D', pinPolicy: PinPolicy.always)
            ..algorithm = algorithm
            ..touchPolicy = TouchPolicy.cached
            ..keyUsage = 1
            ..extendedKeyUsage.add(PivSelfSignOptions.clientAuth);
      options.applyMacOsLogin();
      expect(options.algorithm, algorithm);
      expect(options.keyUsage, algorithm == AlgorithmType.eccp256 ? 16 : 4);
      expect(options.extendedKeyUsage, isEmpty);
      expect(options.includeBasicConstraints, isTrue);
      expect(options.pinPolicy, PinPolicy.once);
      expect(options.touchPolicy, TouchPolicy.cached);
      expect(options.matchesMacOsLogin, isTrue);
      options.keyUsage = 1;
      expect(
        options.matchesMacOsLogin,
        isFalse,
        reason: 'A signing-only 9D key cannot provide keychain wrapping',
      );
      options.applyMacOsLogin();
      options.algorithm = algorithm == AlgorithmType.eccp256
          ? AlgorithmType.rsa2048
          : AlgorithmType.eccp256;
      expect(options.matchesMacOsLogin, isFalse);
      options.applyMacOsLogin();
      expect(options.matchesMacOsLogin, isTrue);
    }
  });

  test('other slots cannot apply or match a Mac setup preset', () {
    for (final slot in ['9C', '9E', '82']) {
      final options = PivSelfSignOptions(
        slotNumber: slot,
        pinPolicy: PinPolicy.once,
      );
      expect(options.supportsMacOsLogin, isFalse);
      expect(options.matchesMacOsLogin, isFalse);
      expect(options.applyMacOsLogin, throwsStateError);
      expect(options.keyUsage, 0);
    }
  });
}
