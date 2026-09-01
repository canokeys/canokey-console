import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

abstract final class AppDialog {
  static const Color barrierColor = Color(0x8A000000);

  static Future<T?> replace<T>(BuildContext currentDialogContext, Widget dialog,
      {bool useSafeArea = true}) async {
    // Keep NFC polling suspended while the outgoing route finishes its reverse
    // transition. The replacement must not overlap that transition: otherwise
    // both dialog trees relayout during the keyboard animation.
    SmartCard.beginDialogInputScope();
    try {
      final route = ModalRoute.of(currentDialogContext);
      Navigator.of(currentDialogContext).pop();
      await route?.completed;
      return await show<T>(dialog, useSafeArea: useSafeArea);
    } finally {
      SmartCard.endDialogInputScope();
    }
  }

  static Future<T?> show<T>(Widget dialog, {bool useSafeArea = true}) async {
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
        useSafeArea: useSafeArea,
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
      // The platform already animates viewInsets with the keyboard. A second
      // tween here restarts on every metrics update and makes large dialogs
      // visibly lag behind the native keyboard animation.
      insetAnimationDuration: Duration.zero,
      child: child,
    );
  }
}

abstract final class AppDialogWidth {
  static const double compact = 400;
  static const double medium = 520;
  static const double large = 640;
}
