import 'dart:math' as math;
import 'package:canokey_console/controller/applets/webauthn/webauthn_controller.dart';
import 'package:canokey_console/models/webauthn.dart';
import 'package:canokey_console/views/applets/webauthn/widgets/webauthn_item_card.dart';
import 'package:flutter/material.dart';

/// Shares the available width between cards, adding columns only when they fit.
/// Natural card heights accommodate wrapped text and accessibility text scaling.
class WebAuthnCredentialGrid extends StatelessWidget {
  const WebAuthnCredentialGrid({
    super.key,
    required this.items,
    required this.controller,
  });
  final List<WebAuthnItem> items;
  final WebAuthnController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (items.isEmpty) return const SizedBox.shrink();
      const gap = 16.0;
      final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final minWidth = 380 * textScale.clamp(1.0, 1.6);
      final columns = math.min(
        items.length,
        math.max(1, ((constraints.maxWidth + gap) / (minWidth + gap)).floor()),
      );
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final item in items)
            SizedBox(
              width: width,
              child: WebAuthnItemCard(item: item, controller: controller),
            ),
        ],
      );
    },
  );
}
