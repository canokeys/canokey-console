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
    this.equalRowHeight = false,
  });
  final List<Widget> children;
  final double minWidth;
  final int? maxColumns;
  final double spacing;
  final double minChildHeight;

  /// Stretch cards in each row to the tallest card's natural height.
  final bool equalRowHeight;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (children.isEmpty) return const SizedBox.shrink();
      final columns = ((constraints.maxWidth + spacing) / (minWidth + spacing))
          .floor()
          .clamp(1, math.min(children.length, maxColumns ?? children.length))
          .toInt();
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      if (equalRowHeight) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var start = 0; start < children.length; start += columns) ...[
              if (start > 0) SizedBox(height: spacing),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (
                      var i = start;
                      i < math.min(start + columns, children.length);
                      i++
                    ) ...[
                      if (i > start) SizedBox(width: spacing),
                      SizedBox(
                        width: width,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: minChildHeight,
                          ),
                          child: children[i],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      }
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
