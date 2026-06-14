import 'dart:math' as math;

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StorageUsageDialog extends StatelessWidget with UIMixin {
  final StorageUsage storageUsage;

  const StorageUsageDialog({super.key, required this.storageUsage});

  static Future<void> show(StorageUsage storageUsage) {
    return Get.dialog(StorageUsageDialog(storageUsage: storageUsage));
  }

  @override
  Widget build(BuildContext context) {
    final usedBytes = storageUsage.usedKiB * 1024;
    final totalBytes = storageUsage.totalKiB * 1024;
    final slices = _buildSlices(usedBytes, totalBytes);

    return Dialog(
      child: SizedBox(
        width: 520,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child:
                  CustomizedText.labelLarge(S.of(context).settingsStorageUsage),
            ),
            Divider(height: 0, thickness: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: Spacing.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: CustomPaint(
                            painter: _StorageUsagePiePainter(
                              slices: slices,
                              backgroundColor: contentTheme.light,
                            ),
                          ),
                        ),
                      ),
                      Spacing.height(16),
                      Center(
                        child: CustomizedText.bodyMedium(
                          '${storageUsage.usedKiB} / ${storageUsage.totalKiB} KiB',
                          fontWeight: 600,
                        ),
                      ),
                      if (slices.isNotEmpty) ...[
                        Spacing.height(16),
                        ...slices.map((slice) => _LegendRow(
                              label: slice.label,
                              value: _formatBytes(slice.bytes),
                              color: slice.color,
                              approximate: slice.approximate,
                            )),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomizedButton.rounded(
                    onPressed: () => Navigator.pop(context),
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium(
                      S.of(context).close,
                      color: contentTheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_StorageUsageSlice> _buildSlices(int usedBytes, int totalBytes) {
    final colors = [
      contentTheme.primary,
      contentTheme.info,
      contentTheme.warning,
      contentTheme.success,
      contentTheme.pink,
      contentTheme.blue,
      contentTheme.danger,
      contentTheme.dark,
    ];
    final slices = <_StorageUsageSlice>[];
    var colorIndex = 0;
    var attributedBytes = 0;

    for (final usage in storageUsage.applets) {
      if (usage.logicalBytes <= 0) {
        continue;
      }
      attributedBytes += usage.logicalBytes;
      slices.add(_StorageUsageSlice(
        label: usage.name,
        bytes: usage.logicalBytes,
        color: colors[colorIndex % colors.length],
        approximate: usage.hasMissingSources,
      ));
      colorIndex++;
    }

    final unattributedUsedBytes = usedBytes - attributedBytes;
    if (unattributedUsedBytes > 0) {
      slices.add(_StorageUsageSlice(
        label: S.of(Get.context!).other,
        bytes: unattributedUsedBytes,
        color: contentTheme.cardTextMuted,
      ));
    }

    final freeBytes = totalBytes - usedBytes;
    if (freeBytes > 0) {
      slices.add(_StorageUsageSlice(
        label: S.of(Get.context!).settingsStorageFree,
        bytes: freeBytes,
        color: contentTheme.light,
      ));
    }

    return slices;
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024) {
      final kib = bytes / 1024;
      return '${kib.toStringAsFixed(kib >= 10 ? 0 : 1)} KiB';
    }
    return '$bytes B';
  }
}

class _LegendRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool approximate;

  const _LegendRow({
    required this.label,
    required this.value,
    required this.color,
    this.approximate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Spacing.bottom(8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Spacing.width(10),
          Expanded(child: CustomizedText.bodySmall(label)),
          CustomizedText.bodySmall('${approximate ? '~ ' : ''}$value'),
        ],
      ),
    );
  }
}

class _StorageUsageSlice {
  final String label;
  final int bytes;
  final Color color;
  final bool approximate;

  const _StorageUsageSlice({
    required this.label,
    required this.bytes,
    required this.color,
    this.approximate = false,
  });
}

class _StorageUsagePiePainter extends CustomPainter {
  final List<_StorageUsageSlice> slices;
  final Color backgroundColor;

  _StorageUsagePiePainter({
    required this.slices,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.bytes);
    final paint = Paint()..style = PaintingStyle.fill;

    if (total <= 0) {
      paint.color = backgroundColor;
      canvas.drawOval(rect, paint);
      return;
    }

    var startAngle = -math.pi / 2;
    for (final slice in slices) {
      final sweepAngle = slice.bytes / total * math.pi * 2;
      paint.color = slice.color;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    paint
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(rect.deflate(1), paint);
  }

  @override
  bool shouldRepaint(covariant _StorageUsagePiePainter oldDelegate) {
    return slices != oldDelegate.slices ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
