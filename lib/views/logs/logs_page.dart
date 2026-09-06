import 'package:canokey_console/controller/base/layout_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key, this.store});

  final LogStore? store;

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  late final LogStore _store = widget.store ?? Logging.store;
  late final _text = TextEditingController(text: _store.text);
  final _scroll = ScrollController();
  final _layoutController = LayoutController();

  @override
  void initState() {
    super.initState();
    _store.addListener(_updated);
    _followLatest();
  }

  @override
  void dispose() {
    _store.removeListener(_updated);
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _updated() {
    final follow = !_scroll.hasClients || _scroll.position.extentAfter < 24;
    final text = _store.text;
    final selection = _text.selection;
    if (_text.text != text) {
      _text.value = TextEditingValue(
        text: text,
        selection: selection.isValid
            ? selection.copyWith(
                baseOffset: selection.baseOffset.clamp(0, text.length),
                extentOffset: selection.extentOffset.clamp(0, text.length))
            : selection,
      );
    }
    setState(() {});
    if (follow && selection.isCollapsed) _followLatest();
  }

  void _followLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _copy() async {
    final l10n = S.of(context);
    try {
      await Clipboard.setData(ClipboardData(text: _text.text));
      if (!mounted) return;
      Prompts.showPrompt(l10n.logsCopied, ContentThemeColor.success);
    } catch (_) {
      if (!mounted) return;
      Prompts.showPrompt(l10n.logsCopyFailed, ContentThemeColor.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final mobile =
        ScreenMedia.getTypeFromWidth(MediaQuery.sizeOf(context).width).isMobile;
    return Layout(
      controller: _layoutController,
      title: l10n.logsTitle,
      scrollable: false,
      topActions: IconButton(
        tooltip: l10n.copy,
        onPressed: _text.text.isEmpty ? null : _copy,
        icon: Icon(LucideIcons.copy,
            size: 20, color: AdminTheme.theme.topBarTheme.onBackground),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(flexSpacing, 0, flexSpacing, 16),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(
                child: mobile
                    ? CustomizedText.bodyMedium(l10n.logsRecording)
                    : CustomizedText.titleMedium(l10n.logsTitle,
                        fontWeight: 600, letterSpacing: 0),
              ),
              if (!mobile) CustomizedText.bodyMedium(l10n.logsRecording),
              const SizedBox(width: 8),
              Semantics(
                label: l10n.logsRecording,
                child: Switch.adaptive(
                  value: _store.enabled,
                  onChanged: _store.setEnabled,
                ),
              ),
            ]),
          ),
          Expanded(
            child: TextField(
              controller: _text,
              scrollController: _scroll,
              readOnly: true,
              showCursor: false,
              expands: true,
              minLines: null,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                  color: AdminTheme.theme.contentTheme.onBackground),
              decoration: InputDecoration(
                hintText: l10n.logsEmpty,
                contentPadding: const EdgeInsets.all(12),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
