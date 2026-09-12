import 'dart:math' as math;
import 'package:canokey_console/controller/applets/oath/oath_controller.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:canokey_console/views/applets/oath/widgets/oath_item_card.dart';
import 'package:flutter/material.dart';

class OathAccountGrid extends StatelessWidget {
  const OathAccountGrid({
    super.key,
    required this.accounts,
    required this.controller,
  });
  final Map<String, OathItem> accounts;
  final OathController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (accounts.isEmpty) return const SizedBox.shrink();
      const gap = 16.0;
      final minWidth =
          360 *
          (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 1.6);
      final columns = math.min(
        accounts.length,
        math.max(1, ((constraints.maxWidth + gap) / (minWidth + gap)).floor()),
      );
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final entry in accounts.entries)
            SizedBox(
              width: width,
              child: OathItemCard(
                key: ValueKey(entry.key),
                name: entry.key,
                item: entry.value,
                controller: controller,
              ),
            ),
        ],
      );
    },
  );
}
