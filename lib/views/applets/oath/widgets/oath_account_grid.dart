import 'package:canokey_console/helper/widgets/responsive_grid.dart';
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
  Widget build(BuildContext context) => ResponsiveGrid(
    minWidth:
        360 * (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 1.6),
    spacing: 16,
    children: [
      for (final entry in accounts.entries)
        OathItemCard(
          key: ValueKey(entry.key),
          name: entry.key,
          item: entry.value,
          controller: controller,
        ),
    ],
  );
}
