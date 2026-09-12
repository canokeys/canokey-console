import 'package:canokey_console/controller/applets/ndef/ndef_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/applet_disabled_screen.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/helper/widgets/poll_canokey_screen.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/ndef.dart';
import 'package:canokey_console/views/applets/ndef/dialogs/ndef_record_dialog.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:canokey_console/views/layout/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:platform_detector/platform_detector.dart';

class NdefPage extends StatefulWidget {
  const NdefPage({super.key});

  @override
  State<NdefPage> createState() => _NdefPageState();
}

class _NdefPageState extends State<NdefPage> with UIMixin {
  final NdefController _controller = Get.put(NdefController());

  @override
  Widget build(BuildContext context) {
    final mobile = ScreenMedia.getTypeFromWidth(
      MediaQuery.sizeOf(context).width,
    ).isMobile;
    return Layout(
      title: 'NDEF',
      onRefresh: _controller.refreshData,
      topActions: isWeb() || isIOSApp()
          ? TopBarRefreshButton(onPressed: _controller.refreshData)
          : null,
      child: GetBuilder<NdefController>(
        init: _controller,
        builder: (_) {
          if (_controller.disabledMessage != null) {
            return AppletDisabledScreen(message: _controller.disabledMessage!);
          }
          if (!_controller.polled) return const PollCanoKeyScreen();

          return LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 640 ||
                  MediaQuery.textScalerOf(context).scale(14) > 20;
              return IgnorePointer(
                ignoring: _controller.writing,
                child: Opacity(
                  opacity: _controller.writing ? .7 : 1,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 16 : flexSpacing,
                      compact ? 16 : 0,
                      compact ? 16 : flexSpacing,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildOverview(mobile),
                        const SizedBox(height: 28),
                        _surface(
                          padding: EdgeInsets.all(compact ? 16 : 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildRecordHeader(compact),
                              const SizedBox(height: 16),
                              if (_controller.decodeError != null)
                                _buildNotice(
                                  LucideIcons.shieldAlert,
                                  _controller.decodeError!,
                                  contentTheme.danger,
                                )
                              else if (_controller.records.isEmpty)
                                _buildEmptyState()
                              else
                                for (
                                  var index = 0;
                                  index < _controller.records.length;
                                  index++
                                ) ...[
                                  if (index > 0) const SizedBox(height: 12),
                                  _buildRecord(index),
                                ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildFooter(compact),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static const _accent = Color(0xff009b83);
  Color get _ink => Theme.of(context).colorScheme.onSurface;
  Color get _muted => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xff35414c)
      : const Color(0xffe5edf2);

  Widget _surface({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
  }) => Material(
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xff202b34)
        : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(9),
      side: BorderSide(color: _border),
    ),
    child: Padding(padding: padding, child: child),
  );

  ButtonStyle get _buttonStyle => FilledButton.styleFrom(
    backgroundColor: _accent,
    foregroundColor: Colors.white,
    minimumSize: const Size(0, 46),
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    shape: const StadiumBorder(),
  );

  Widget _buildOverview(bool mobile) {
    final used = _controller.messageLength;
    final total = _controller.maxMessageLength;
    final progress = total <= 0 ? 0.0 : (used / total).clamp(0.0, 1.0);
    return _surface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 540 ||
              MediaQuery.textScalerOf(context).scale(14) > 20;
          final status = _StatusLabel(
            text: _controller.readOnly
                ? S.of(context).ndefReadOnlyStatus
                : S.of(context).ndefWritable,
            color: _controller.readOnly ? contentTheme.warning : _accent,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!mobile)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: compact ? 56 : 72,
                      height: compact ? 56 : 72,
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.nfc,
                        color: _accent,
                        size: compact ? 30 : 38,
                      ),
                    ),
                    SizedBox(width: compact ? 16 : 26),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomizedText.headlineSmall(
                            S.of(context).ndefTagContent,
                            fontSize: 24,
                            fontWeight: 600,
                            color: _ink,
                          ),
                          const SizedBox(height: 8),
                          CustomizedText.bodyMedium(
                            S.of(context).ndefTagContentDescription,
                            color: _muted,
                          ),
                        ],
                      ),
                    ),
                    if (!compact) ...[const SizedBox(width: 20), status],
                  ],
                ),
              if (compact || mobile) ...[
                if (!mobile) const SizedBox(height: 16),
                Align(alignment: Alignment.centerLeft, child: status),
              ],
              if (_controller.readOnly) ...[
                const SizedBox(height: 20),
                _buildNotice(
                  LucideIcons.fileLock,
                  S.of(context).ndefReadOnlyDescription,
                  contentTheme.warning,
                ),
              ],
              const SizedBox(height: 32),
              if (compact) ...[
                CustomizedText.bodyLarge(
                  S.of(context).ndefCapacity,
                  color: _ink,
                ),
                const SizedBox(height: 6),
                CustomizedText.bodyMedium(
                  S.of(context).ndefBytesUsed(used, total),
                  color: _controller.exceedsCapacity
                      ? contentTheme.danger
                      : _muted,
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: CustomizedText.bodyLarge(
                        S.of(context).ndefCapacity,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: CustomizedText.bodyMedium(
                          S.of(context).ndefBytesUsed(used, total),
                          textAlign: TextAlign.right,
                          color: _controller.exceedsCapacity
                              ? contentTheme.danger
                              : _muted,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  color: _controller.exceedsCapacity
                      ? contentTheme.danger
                      : _accent,
                  backgroundColor: _accent.withValues(alpha: .13),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecordHeader(bool mobile) {
    final heading = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(LucideIcons.fileText, color: _ink, size: 24),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: CustomizedText.titleLarge(
            S.of(context).ndefRecords,
            fontSize: 22,
            fontWeight: 600,
            color: _ink,
          ),
        ),
      ],
    );
    final addButton = FilledButton.icon(
      style: _buttonStyle,
      onPressed: _controller.canEdit ? () => _openEditor() : null,
      icon: const Icon(LucideIcons.plus, size: 22),
      label: Text(S.of(context).ndefAddRecord),
    );
    return mobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [heading, const SizedBox(height: 16), addButton],
          )
        : Row(
            children: [
              Expanded(child: heading),
              const SizedBox(width: 16),
              addButton,
            ],
          );
  }

  Widget _buildRecord(int index) {
    final record = _controller.records[index];
    final editable = record.editableType != null && _controller.canEdit;
    final compact =
        MediaQuery.sizeOf(context).width < 900 ||
        MediaQuery.textScalerOf(context).scale(14) > 20;
    final summary = record.summary;
    final icon = switch (record.editableType) {
      NdefEditableRecordType.uri => LucideIcons.link,
      NdefEditableRecordType.text => LucideIcons.text,
      NdefEditableRecordType.phone => LucideIcons.phone,
      NdefEditableRecordType.contact => LucideIcons.contact,
      NdefEditableRecordType.wifi => LucideIcons.wifi,
      NdefEditableRecordType.androidApplication => LucideIcons.package,
      NdefEditableRecordType.custom => LucideIcons.binary,
      null => LucideIcons.fileText,
    };

    return _surface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: _accent, size: 21),
          ),
          Spacing.width(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomizedText.bodyLarge(
                  record.displayType,
                  fontWeight: 600,
                  color: _ink,
                ),
                if (summary.isNotEmpty) ...[
                  Spacing.height(3),
                  CustomizedText.bodySmall(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    color: _muted,
                  ),
                ],
              ],
            ),
          ),
          if (_controller.canEdit) ...[
            if (compact)
              _recordMenu(index, editable)
            else ...[
              _recordAction(
                S.of(context).ndefMoveUp,
                LucideIcons.arrowUp,
                index == 0
                    ? null
                    : () => _controller.moveRecord(index, index - 1),
              ),
              _recordAction(
                S.of(context).ndefMoveDown,
                LucideIcons.arrowDown,
                index == _controller.records.length - 1
                    ? null
                    : () => _controller.moveRecord(index, index + 1),
              ),
              if (editable)
                _recordAction(
                  S.of(context).ndefEditRecord,
                  LucideIcons.pencil,
                  () => _openEditor(index: index),
                ),
              _recordAction(
                S.of(context).delete,
                LucideIcons.trash2,
                () => _controller.removeRecord(index),
                color: contentTheme.danger,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _recordMenu(int index, bool editable) {
    return PopupMenuButton<_RecordAction>(
      tooltip: S.of(context).actions,
      icon: const Icon(LucideIcons.moreHorizontal, size: 19),
      onSelected: (action) {
        switch (action) {
          case _RecordAction.moveUp:
            _controller.moveRecord(index, index - 1);
          case _RecordAction.moveDown:
            _controller.moveRecord(index, index + 1);
          case _RecordAction.edit:
            _openEditor(index: index);
          case _RecordAction.delete:
            _controller.removeRecord(index);
        }
      },
      itemBuilder: (context) => [
        _recordMenuItem(
          _RecordAction.moveUp,
          LucideIcons.arrowUp,
          S.of(context).ndefMoveUp,
          enabled: index > 0,
        ),
        _recordMenuItem(
          _RecordAction.moveDown,
          LucideIcons.arrowDown,
          S.of(context).ndefMoveDown,
          enabled: index < _controller.records.length - 1,
        ),
        if (editable)
          _recordMenuItem(
            _RecordAction.edit,
            LucideIcons.pencil,
            S.of(context).ndefEditRecord,
          ),
        _recordMenuItem(
          _RecordAction.delete,
          LucideIcons.trash2,
          S.of(context).delete,
          color: contentTheme.danger,
        ),
      ],
    );
  }

  PopupMenuItem<_RecordAction> _recordMenuItem(
    _RecordAction value,
    IconData icon,
    String text, {
    bool enabled = true,
    Color? color,
  }) {
    return PopupMenuItem(
      value: value,
      enabled: enabled,
      child: Row(
        children: [
          Icon(icon, size: 18, color: enabled ? color : null),
          Spacing.width(12),
          CustomizedText.bodyMedium(text, color: enabled ? color : null),
        ],
      ),
    );
  }

  Widget _recordAction(
    String tooltip,
    IconData icon,
    VoidCallback? onPressed, {
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 18, color: onPressed == null ? null : color),
      ),
    );
  }

  Widget _buildEmptyState() => Container(
    constraints: const BoxConstraints(minHeight: 260),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
    decoration: BoxDecoration(
      border: Border.all(color: _border),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          height: 88,
          child: Stack(
            children: [
              Positioned(
                left: 10,
                bottom: 0,
                child: Icon(
                  LucideIcons.fileText,
                  size: 62,
                  color: _muted.withValues(alpha: .55),
                ),
              ),
              Positioned(
                right: 3,
                top: 2,
                child: Icon(
                  LucideIcons.plus,
                  size: 26,
                  color: _accent.withValues(alpha: .4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        CustomizedText.titleLarge(
          S.of(context).ndefNoRecords,
          fontSize: 22,
          fontWeight: 600,
          color: _ink,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        CustomizedText.bodyMedium(
          S.of(context).ndefNoRecordsDescription,
          color: _muted,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildFooter(bool mobile) {
    final status = _controller.exceedsCapacity
        ? S.of(context).ndefCapacityExceeded
        : _controller.dirty
        ? S.of(context).ndefUnsavedChanges
        : '';
    final button = FilledButton.icon(
      style: _buttonStyle,
      onPressed: _controller.canSave ? _controller.save : null,
      icon: _controller.writing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(LucideIcons.save, size: 18),
      label: Text(S.of(context).ndefSaveToKey),
    );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (status.isNotEmpty) ...[
            CustomizedText.bodySmall(
              status,
              color: _controller.exceedsCapacity ? contentTheme.danger : _muted,
            ),
            Spacing.height(10),
          ],
          button,
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: CustomizedText.bodySmall(
            status,
            color: _controller.exceedsCapacity ? contentTheme.danger : _muted,
          ),
        ),
        button,
      ],
    );
  }

  Widget _buildNotice(
    IconData icon,
    String text,
    Color color, {
    bool square = false,
  }) {
    return Container(
      padding: Spacing.xy(16, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: square ? null : BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          Spacing.width(12),
          Expanded(child: CustomizedText.bodyMedium(text, color: _ink)),
        ],
      ),
    );
  }

  Future<void> _openEditor({int? index}) async {
    final record = await NdefRecordDialog.show(
      record: index == null ? null : _controller.records[index],
      defaultLanguage: Localizations.localeOf(context).languageCode,
    );
    if (record == null) return;
    if (index == null) {
      _controller.addRecord(record);
    } else {
      _controller.updateRecord(index, record);
    }
  }
}

class _StatusLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: CustomizedText.bodyMedium(text, color: color, fontWeight: 600),
    );
  }
}

enum _RecordAction { moveUp, moveDown, edit, delete }
