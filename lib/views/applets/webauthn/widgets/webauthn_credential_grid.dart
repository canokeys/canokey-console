import 'package:canokey_console/helper/widgets/responsive_grid.dart';
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
  Widget build(BuildContext context) => ResponsiveGrid(
    minWidth:
        380 * (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 1.6),
    spacing: 16,
    children: [
      for (final item in items)
        WebAuthnItemCard(item: item, controller: controller),
    ],
  );
}
