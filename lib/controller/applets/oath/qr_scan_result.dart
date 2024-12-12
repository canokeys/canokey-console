import 'package:canokey_console/models/oath.dart';

class QrScanResult {
  final String issuer;
  final String account;
  final String secret;
  final OathType type;
  final OathAlgorithm algo;
  final int digits;
  final int initValue;

  QrScanResult({
    required this.issuer,
    required this.account,
    required this.secret,
    required this.type,
    required this.algo,
    required this.digits,
    required this.initValue,
  });
}
