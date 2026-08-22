import 'package:flutter/material.dart';
import 'package:get/get.dart';

abstract final class AppDialog {
  static const Color barrierColor = Color(0x8A000000);

  static Future<T?> show<T>(Widget dialog) {
    return Get.dialog<T>(
      dialog,
      barrierDismissible: false,
      barrierColor: barrierColor,
    );
  }
}

class AppDialogSurface extends StatelessWidget {
  final Widget child;

  const AppDialogSurface({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

abstract final class AppDialogWidth {
  static const double compact = 400;
  static const double medium = 520;
  static const double large = 640;
}
