import 'dart:math' as math;

import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:flutter/material.dart';

class KeyboardSafeDialog extends StatelessWidget {
  final Widget child;
  final bool useCompositedKeyboardMotion;

  const KeyboardSafeDialog({
    super.key,
    required this.child,
    this.useCompositedKeyboardMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    final dialog = AppDialogSurface(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: child,
      ),
    );
    if (!useCompositedKeyboardMotion) {
      return dialog;
    }
    if (MediaQuery.sizeOf(context).height < 600) {
      return SafeArea(child: dialog);
    }
    return _CompositedKeyboardMotion(child: dialog);
  }
}

class _CompositedKeyboardMotion extends StatelessWidget {
  final Widget child;

  const _CompositedKeyboardMotion({required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = math.max(
      0.0,
      mediaQuery.viewInsets.bottom - mediaQuery.viewPadding.bottom,
    );

    return MediaQuery(
      data: mediaQuery.copyWith(
        padding: mediaQuery.viewPadding,
        viewInsets: EdgeInsets.zero,
      ),
      child: SafeArea(
        child: Transform.translate(
          offset: Offset(0, -keyboardHeight / 2),
          child: RepaintBoundary(child: child),
        ),
      ),
    );
  }
}
