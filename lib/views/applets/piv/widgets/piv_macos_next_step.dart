import 'package:canokey_console/generated/l10n.dart';
import 'package:flutter/material.dart';

/// Creating one certificate is not the completion of the two-slot Mac setup.
class PivMacOsNextStep extends StatelessWidget {
  const PivMacOsNextStep({
    super.key,
    required this.completedSlot,
    required this.onOpenSlot,
  });

  final String completedSlot;
  final ValueChanged<String> onOpenSlot;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final nextSlot = completedSlot == '9A' ? '9D' : '9A';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          completedSlot == '9A'
              ? s.pivMacOsAfterAuthentication
              : s.pivMacOsAfterKeychain,
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => onOpenSlot(nextSlot),
          child: Text(s.pivMacOsCheckSlot(nextSlot)),
        ),
      ],
    );
  }
}
