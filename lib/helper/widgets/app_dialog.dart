import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

abstract final class AppDialog {
  static const Color barrierColor = Color(0x8A000000);

  static Future<T?> replace<T>(
    BuildContext currentDialogContext,
    Widget dialog, {
    bool useSafeArea = true,
  }) async {
    // Keep NFC polling suspended while the outgoing route finishes its reverse
    // transition. The replacement must not overlap that transition: otherwise
    // both dialog trees relayout during the keyboard animation.
    SmartCard.beginDialogInputScope();
    try {
      final route = ModalRoute.of(currentDialogContext);
      Navigator.of(currentDialogContext).pop();
      await route?.completed;
      return await show<T>(dialog, useSafeArea: useSafeArea);
    } finally {
      SmartCard.endDialogInputScope();
    }
  }

  static Future<T?> show<T>(Widget dialog, {bool useSafeArea = true}) async {
    final log = Logging.logger('Dialog');
    log.t('Open ${dialog.runtimeType}');
    SmartCard.beginDialogInputScope();
    var released = false;
    void releaseNfcScope() {
      if (released) {
        return;
      }
      released = true;
      SmartCard.endDialogInputScope();
    }

    try {
      return await Get.dialog<T>(
        _AppDialogNfcScope(onDispose: releaseNfcScope, child: dialog),
        barrierDismissible: false,
        barrierColor: barrierColor,
        useSafeArea: useSafeArea,
      );
    } finally {
      releaseNfcScope();
      log.t('Close ${dialog.runtimeType}');
    }
  }
}

class _AppDialogNfcScope extends StatefulWidget {
  final Widget child;
  final VoidCallback onDispose;

  const _AppDialogNfcScope({required this.child, required this.onDispose});

  @override
  State<_AppDialogNfcScope> createState() => _AppDialogNfcScopeState();
}

class _AppDialogNfcScopeState extends State<_AppDialogNfcScope> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class AppDialogSurface extends StatelessWidget {
  final Widget child;

  const AppDialogSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      // The platform already animates viewInsets with the keyboard. A second
      // tween here restarts on every metrics update and makes large dialogs
      // visibly lag behind the native keyboard animation.
      insetAnimationDuration: Duration.zero,
      child: child,
    );
  }
}

abstract final class AppDialogWidth {
  static const double compact = 460;
  static const double medium = 520;
  static const double large = 640;
}

/// Shared dialog chrome, also used by forms with their own scrolling.
class AppDialogHeader extends StatelessWidget {
  const AppDialogHeader({
    super.key,
    required this.title,
    this.icon,
    this.description,
    this.showClose = true,
    this.onClose,
    this.closeEnabled = true,
  });

  final String title;
  final bool showClose;
  final VoidCallback? onClose;
  final bool closeEnabled;
  final IconData? icon;
  final String? description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xff009b83).withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xff009b83), size: 26),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (showClose)
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: closeEnabled
                    ? (onClose ?? () => Navigator.of(context).pop())
                    : null,
                icon: const Icon(Icons.close, size: 22),
              ),
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 12),
          Text(
            description!,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    ),
  );
}

class AppDialogActions extends StatelessWidget {
  const AppDialogActions({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    child: SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 12,
        runSpacing: 12,
        children: children,
      ),
    ),
  );
}

class AppDialogAction extends StatelessWidget {
  const AppDialogAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.destructive = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool secondary, destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: secondary
            ? (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xff303b44)
                  : const Color(0xffedf2f6))
            : destructive
            ? colors.error
            : const Color(0xff009b83),
        foregroundColor: secondary ? colors.onSurface : Colors.white,
        minimumSize: const Size(96, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

class AppDialogChoice extends StatelessWidget {
  const AppDialogChoice({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const accent = Color(0xff009b83);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Semantics(
        checked: selected,
        inMutuallyExclusiveGroup: true,
        child: Material(
          color: selected
              ? accent.withValues(alpha: .12)
              : Theme.of(context).brightness == Brightness.dark
              ? const Color(0xff252f38)
              : const Color(0xfff5f7fa),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: selected
                  ? accent.withValues(alpha: .45)
                  : colors.outlineVariant,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? accent : colors.onSurfaceVariant,
                    size: 24,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            color: selected ? accent : colors.onSurface,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
