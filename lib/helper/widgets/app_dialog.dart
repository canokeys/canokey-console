import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
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

/// Shared operation scope for every dialog, including non-BaseDialog forms.
class AppDialogSurface extends StatefulWidget {
  final Widget child;
  const AppDialogSurface({super.key, required this.child});

  static Future<void> run(
    BuildContext context,
    FutureOr<void> Function() action,
  ) async {
    final scope = context.findAncestorStateOfType<_AppDialogSurfaceState>();
    if (scope == null) {
      await action();
    } else {
      await scope.run(action);
    }
  }

  @override
  State<AppDialogSurface> createState() => _AppDialogSurfaceState();
}

class _AppDialogSurfaceState extends State<AppDialogSurface> {
  bool busy = false;

  Future<void> run(FutureOr<void> Function() action) async {
    if (busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => busy = true);
    try {
      await action();
    } on UserCanceledError {
      // Cancellation is not a failure.
    } catch (error, stack) {
      Logging.logger(
        'Dialog',
      ).e('Dialog operation failed', error: error, stackTrace: stack);
      Prompts.showPrompt(S.current.operationFailed, ContentThemeColor.danger);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      insetAnimationDuration: Duration.zero,
      child: _DialogOperationScope(
        busy: busy,
        child: Stack(
          children: [
            AbsorbPointer(absorbing: busy, child: widget.child),
            if (busy && (ModalRoute.of(context)?.isCurrent ?? true))
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(minHeight: 3),
              ),
          ],
        ),
      ),
    ),
  );
}

class _DialogOperationScope extends InheritedWidget {
  final bool busy;
  const _DialogOperationScope({required this.busy, required super.child});
  static bool isBusy(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_DialogOperationScope>()
          ?.busy ??
      false;
  @override
  bool updateShouldNotify(_DialogOperationScope oldWidget) =>
      busy != oldWidget.busy;
}

/// Fixed header and actions, with only the body scrolling on small screens.
class AppDialogLayout extends StatelessWidget {
  final Widget header;
  final Widget body;
  final List<Widget> actions;
  const AppDialogLayout({
    super.key,
    required this.header,
    required this.body,
    required this.actions,
  });
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      header,
      const Divider(height: 1),
      Flexible(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: body,
        ),
      ),
      const Divider(height: 1),
      AppDialogActions(children: actions),
    ],
  );
}

/// Declarative variant used by existing forms that provide chrome as children.
class AppDialogColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  const AppDialogColumn({
    super.key,
    required this.children,
    this.mainAxisSize = MainAxisSize.min,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });
  @override
  Widget build(BuildContext context) {
    final header = children.first;
    final footer = children.last;
    assert(header is AppDialogHeader && footer is AppDialogActions);
    final body = children.sublist(1, children.length - 1);
    if (body.firstOrNull is Divider) body.removeAt(0);
    if (body.lastOrNull is Divider) body.removeLast();
    return AppDialogLayout(
      header: header,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: body,
      ),
      actions: (footer as AppDialogActions).children,
    );
  }
}

class AppConfirmationDialog extends StatelessWidget {
  final String title, message, confirmLabel;
  final bool destructive;
  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.destructive = false,
  });
  @override
  Widget build(BuildContext context) => AppDialogSurface(
    child: SizedBox(
      width: AppDialogWidth.compact,
      child: AppDialogLayout(
        header: AppDialogHeader(title: title),
        body: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
        actions: [
          AppDialogAction(
            label: S.of(context).cancel,
            secondary: true,
            onPressed: () => Navigator.pop(context, false),
          ),
          AppDialogAction(
            label: confirmLabel,
            destructive: destructive,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ),
  );
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

  /// Defaults to a bare [Navigator.pop]. Dialogs that must run cleanup on
  /// dismissal (completing a [Completer], invoking `onCancel`, ...) MUST pass
  /// an explicit [onClose], otherwise closing via the X button skips it.
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
                onPressed:
                    closeEnabled && !_DialogOperationScope.isBusy(context)
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
  final FutureOr<void> Function()? onPressed;
  final bool secondary, destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: onPressed == null || _DialogOperationScope.isBusy(context)
          ? null
          : () => AppDialogSurface.run(context, onPressed!),
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
    this.horizontalPadding = 24,
  });
  final String title;
  final String? subtitle;
  final double horizontalPadding;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const accent = Color(0xff009b83);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4),
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

/// One interaction target for the checkbox, its label and the row's whitespace.
class AppDialogCheckbox extends StatelessWidget {
  const AppDialogCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
  });
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final Widget title;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    borderRadius: BorderRadius.circular(8),
    clipBehavior: Clip.antiAlias,
    child: ListTileTheme(
      data: const ListTileThemeData(minTileHeight: 48, horizontalTitleGap: 12),
      child: CheckboxListTile(
        value: value,
        onChanged: _DialogOperationScope.isBusy(context) ? null : onChanged,
        title: title,
        subtitle: subtitle,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        visualDensity: VisualDensity.standard,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        dense: false,
        activeColor: const Color(0xff009b83),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}

/// Immediate settings use switches; the full row shares the switch's action.
class AppDialogSwitch extends StatelessWidget {
  const AppDialogSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget title;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    borderRadius: BorderRadius.circular(8),
    clipBehavior: Clip.antiAlias,
    child: SwitchListTile(
      value: value,
      onChanged: _DialogOperationScope.isBusy(context) ? null : onChanged,
      title: title,
      subtitle: subtitle,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.trailing,
      activeThumbColor: Colors.white,
      activeTrackColor: const Color(0xff009b83),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      dense: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
