import 'package:canokey_console/controller/applets/oath/oath_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/models/oath.dart';
import 'package:canokey_console/views/applets/oath/dialogs/delete_dialog.dart';
import 'package:canokey_console/views/applets/oath/dialogs/set_default_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timer_controller/timer_controller.dart';

enum _OathAction { delete, setDefault }

class OathItemCard extends StatelessWidget {
  final OathController controller;
  final String name;
  final OathItem item;
  static const _accent = Color(0xff009b83);

  const OathItemCard({
    super.key,
    required this.controller,
    required this.name,
    required this.item,
  });

  Widget _issuerIcon(BuildContext context, String label) {
    final brand = switch (item.issuer.trim().toLowerCase()) {
      'google' => ('google', const Color(0xff4285f4)),
      'github' => ('github', const Color(0xff24292f)),
      'microsoft' => ('microsoft', const Color(0xff0078d4)),
      'discord' => ('discord', const Color(0xff5865f2)),
      'aws' ||
      'amazon web services' ||
      'amazonaws' => ('amazonaws', const Color(0xff232f3e)),
      _ => null,
    };
    if (brand != null) {
      return Image.asset(
        'assets/images/oath/${brand.$1}.png',
        width: 30,
        height: 30,
        color:
            Theme.of(context).brightness == Brightness.dark &&
                (brand.$1 == 'github' || brand.$1 == 'amazonaws')
            ? Colors.white
            : brand.$2,
        excludeFromSemantics: true,
      );
    }
    return CustomizedText.titleLarge(
      label.isEmpty ? '?' : label.characters.first.toUpperCase(),
      fontSize: 24,
      color: _accent,
      fontWeight: 600,
    );
  }

  String get _displayCode {
    if (item.code.isEmpty) return '••• •••';
    if (item.format == OathCodeFormat.decimal &&
        (item.code.length == 6 || item.code.length == 8)) {
      final middle = item.code.length ~/ 2;
      return '${item.code.substring(0, middle)} ${item.code.substring(middle)}';
    }
    return item.code;
  }

  Widget _timer(BuildContext context, int remaining) => SizedBox.square(
    dimension: 56,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.square(
          dimension: 50,
          child: CircularProgressIndicator(
            value: (remaining / 30).clamp(0.0, 1.0),
            strokeWidth: 5,
            color: _accent,
            backgroundColor: _accent.withValues(alpha: .16),
          ),
        ),
        CustomizedText.bodyLarge(
          '$remaining',
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 18,
        ),
      ],
    ),
  );

  Widget _indicator(BuildContext context) {
    if (item.type == OathType.hotp ||
        (item.code.isEmpty && item.requireTouch)) {
      return IconButton(
        tooltip: item.type == OathType.hotp
            ? S.of(context).refresh
            : S.of(context).oathRequireTouch,
        style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
        onPressed: () => controller.calculate(name, item.type),
        icon: Icon(
          item.type == OathType.hotp ? LucideIcons.refreshCw : Icons.touch_app,
          size: 26,
          color: _accent,
        ),
      );
    }
    if (item.code.isEmpty) return _timer(context, 0);
    return TimerControllerBuilder(
      controller: controller.timerController,
      builder: (context, value, child) => _timer(context, value.remaining),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final label = item.issuer.isEmpty ? item.account : item.issuer;
    final code = Tooltip(
      message: item.code,
      child: CustomizedText.bodyLarge(
        _displayCode,
        fontSize: 32,
        color: colors.onSurface,
        style: TextStyle(
          fontSize: 32,
          color: colors.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
          letterSpacing: 1,
        ),
      ),
    );
    final copy = IconButton(
      tooltip: S.of(context).copy,
      onPressed: item.code.isEmpty
          ? null
          : () {
              Clipboard.setData(ClipboardData(text: item.code));
              Prompts.showPrompt(
                S.of(context).copied,
                ContentThemeColor.success,
              );
            },
      icon: const Icon(LucideIcons.copy, size: 22),
      color: _accent,
    );
    return Material(
      color: dark ? const Color(0xff202b34) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: dark ? const Color(0xff35414c) : const Color(0xffe5edf2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: .10),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _issuerIcon(context, label),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tooltip(
                        message: label,
                        child: CustomizedText.titleMedium(
                          label,
                          fontSize: 17,
                          fontWeight: 600,
                          color: colors.onSurface,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Tooltip(
                        message: item.account,
                        child: CustomizedText.bodyMedium(
                          item.account,
                          color: colors.onSurfaceVariant,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<_OathAction>(
                  tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
                  position: PopupMenuPosition.under,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  icon: Icon(
                    LucideIcons.moreHorizontal,
                    size: 22,
                    color: colors.onSurface,
                  ),
                  onSelected: (action) {
                    switch (action) {
                      case _OathAction.delete:
                        DeleteDialog.show(
                          name: name,
                          onDelete: () => controller.delete(name),
                        );
                      case _OathAction.setDefault:
                        SetDefaultDialog.show(
                          name: name,
                          onSetDefault: (slot, withEnter) =>
                              controller.setDefault(name, slot, withEnter),
                        );
                    }
                  },
                  itemBuilder: (context) => [
                    if (item.type == OathType.hotp)
                      PopupMenuItem(
                        value: _OathAction.setDefault,
                        child: Text(S.of(context).oathSetDefault),
                      ),
                    PopupMenuItem(
                      value: _OathAction.delete,
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.trash2,
                            size: 20,
                            color: colors.error,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            S.of(context).delete,
                            style: TextStyle(color: colors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final largeText =
                    MediaQuery.textScalerOf(context).scale(32) > 40;
                if (constraints.maxWidth < 300 ||
                    largeText ||
                    (item.code.length > 6 && constraints.maxWidth < 370)) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [_indicator(context), copy],
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: code,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    _indicator(context),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: code,
                      ),
                    ),
                    const SizedBox(width: 8),
                    copy,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
