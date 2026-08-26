import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

abstract final class AppDialog {
  static const Color barrierColor = Color(0x8A000000);

  static Future<T?> show<T>(Widget dialog) async {
    SmartCard.beginDialogInputScope();
    var released = false;
    void releaseNfcScope() {
      if (released) {
        return;
      }
      released = true;
      SmartCard.endDialogInputScope();
    }

    try {
      return await Get.dialog<T>(
        _AppDialogNfcScope(
          onDispose: releaseNfcScope,
          child: dialog,
        ),
        barrierDismissible: false,
        barrierColor: barrierColor,
      );
    } finally {
      releaseNfcScope();
    }
  }
}

class _AppDialogNfcScope extends StatefulWidget {
  final Widget child;
  final VoidCallback onDispose;

  const _AppDialogNfcScope({
    required this.child,
    required this.onDispose,
  });

  @override
  State<_AppDialogNfcScope> createState() => _AppDialogNfcScopeState();
}

class _AppDialogNfcScopeState extends State<_AppDialogNfcScope> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
