import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Equal-width columns with natural card heights, based on available width.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minWidth = 220,
    this.maxColumns,
    this.spacing = 10,
    this.minChildHeight = 0,
  });
  final List<Widget> children;
  final double minWidth;
  final int? maxColumns;
  final double spacing;
  final double minChildHeight;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (children.isEmpty) return const SizedBox.shrink();
      final columns = ((constraints.maxWidth + spacing) / (minWidth + spacing))
          .floor()
          .clamp(1, math.min(children.length, maxColumns ?? children.length));
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (var i = 0; i < children.length; i++)
            SizedBox(
              width: width,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minChildHeight),
                child: children[i],
              ),
            ),
        ],
      );
    },
  );
}
