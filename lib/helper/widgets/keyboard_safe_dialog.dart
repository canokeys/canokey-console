import 'package:flutter/material.dart';

class KeyboardSafeDialog extends StatelessWidget {
  final Widget child;

  const KeyboardSafeDialog({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: child,
      ),
    );
  }
}
