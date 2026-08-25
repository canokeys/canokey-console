import 'package:canokey_console/controller/applets/ndef/ndef_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/shadow.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/applet_disabled_screen.dart';
import 'package:canokey_console/helper/widgets/customized_card.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/helper/widgets/poll_canokey_screen.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/ndef.dart';
import 'package:canokey_console/views/applets/ndef/dialogs/ndef_record_dialog.dart';
import 'package:canokey_console/views/layout/layout.dart';
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
    return Layout(
      title: 'NDEF',
      onRefresh: _controller.refreshData,
      topActions: isWeb() || isIOSApp()
          ? Tooltip(
              message: MaterialLocalizations.of(context)
                  .refreshIndicatorSemanticLabel,
              child: IconButton(
                onPressed: _controller.refreshData,
                icon: Icon(LucideIcons.refreshCw,
                    color: topBarTheme.onBackground),
              ),
            )
          : null,
      child: GetBuilder<NdefController>(
        init: _controller,
        builder: (_) {
          if (_controller.disabledMessage != null) {
            return AppletDisabledScreen(message: _controller.disabledMessage!);
          }
          if (!_controller.polled) return const PollCanoKeyScreen();

          return Responsive(
            builder: (context, constraints, screenType) => IgnorePointer(
              ignoring: _controller.writing,
              child: Opacity(
                opacity: _controller.writing ? 0.7 : 1,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Padding(
                      padding: Spacing.fromLTRB(
                          screenType.isMobile ? 16 : flexSpacing,
                          20,
                          screenType.isMobile ? 16 : flexSpacing,
                          flexSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildOverview(),
                          Spacing.height(24),
                          _buildRecordHeader(screenType.isMobile),
                          Spacing.height(12),
                          if (_controller.decodeError != null)
                            _buildNotice(
                              LucideIcons.shieldAlert,
                              _controller.decodeError!,
                              contentTheme.danger,
                            )
                          else if (_controller.records.isEmpty)
                            _buildEmptyState()
                          else
                            ...List.generate(
                              _controller.records.length,
                              (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildRecord(index),
                              ),
                            ),
                          Spacing.height(8),
                          _buildFooter(screenType.isMobile),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverview() {
    final used = _controller.messageLength;
    final total = _controller.maxMessageLength;
    final progress = total == 0 ? 0.0 : (used / total).clamp(0.0, 1.0);
    return CustomizedCard(
      clipBehavior: Clip.antiAlias,
      paddingAll: 0,
      shadow: Shadow(elevation: 0.5, position: ShadowPosition.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: Spacing.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: contentTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(LucideIcons.nfc,
                      color: contentTheme.primary, size: 23),
                ),
                Spacing.width(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomizedText.titleMedium(
                        S.of(context).ndefTagContent,
                        fontWeight: 600,
                        color: contentTheme.onBackground,
                      ),
                      Spacing.height(4),
                      CustomizedText.bodySmall(
                        S.of(context).ndefTagContentDescription,
                        maxLines: 3,
                        color: contentTheme.cardText,
                      ),
                    ],
                  ),
                ),
                Spacing.width(12),
                _StatusLabel(
                  text: _controller.readOnly
                      ? S.of(context).ndefReadOnlyStatus
                      : S.of(context).ndefWritable,
                  color: _controller.readOnly
                      ? contentTheme.warning
                      : contentTheme.success,
                ),
              ],
            ),
          ),
          if (_controller.readOnly)
            _buildNotice(
              LucideIcons.fileLock,
              S.of(context).ndefReadOnlyDescription,
              contentTheme.warning,
              square: true,
            ),
          Padding(
            padding: Spacing.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CustomizedText.labelMedium(S.of(context).ndefCapacity),
                    const Spacer(),
                    CustomizedText.bodySmall(
                      S.of(context).ndefBytesUsed(used, total),
                      color: _controller.exceedsCapacity
                          ? contentTheme.danger
                          : contentTheme.cardText,
                    ),
                  ],
                ),
                Spacing.height(8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    color: _controller.exceedsCapacity
                        ? contentTheme.danger
                        : contentTheme.primary,
                    backgroundColor:
                        contentTheme.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordHeader(bool mobile) {
    final addButton = FilledButton.icon(
      onPressed: _controller.canEdit ? () => _openEditor() : null,
      icon: const Icon(LucideIcons.plus, size: 18),
      label: Text(S.of(context).ndefAddRecord),
    );
    return mobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomizedText.titleMedium(S.of(context).ndefRecords,
                  fontWeight: 600),
              Spacing.height(12),
              addButton,
            ],
          )
        : Row(
            children: [
              CustomizedText.titleMedium(S.of(context).ndefRecords,
                  fontWeight: 600),
              const Spacer(),
              addButton,
            ],
          );
  }

  Widget _buildRecord(int index) {
    final record = _controller.records[index];
    final editable = record.editableType != null && _controller.canEdit;
    final compact = MediaQuery.sizeOf(context).width < 600;
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

    return CustomizedCard.bordered(
      padding: Spacing.xy(16, 14),
      shadow: Shadow(elevation: 0),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: contentTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: contentTheme.primary, size: 19),
          ),
          Spacing.width(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomizedText.labelLarge(record.displayType, fontWeight: 600),
                if (summary.isNotEmpty) ...[
                  Spacing.height(3),
                  CustomizedText.bodySmall(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    color: contentTheme.cardText,
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

  Widget _recordAction(String tooltip, IconData icon, VoidCallback? onPressed,
      {Color? color}) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 18, color: onPressed == null ? null : color),
      ),
    );
  }

  Widget _buildEmptyState() {
    return CustomizedCard.bordered(
      padding: Spacing.xy(24, 36),
      shadow: Shadow(elevation: 0),
      child: Column(
        children: [
          Icon(LucideIcons.fileText,
              size: 32, color: contentTheme.cardTextMuted),
          Spacing.height(12),
          CustomizedText.titleMedium(S.of(context).ndefNoRecords,
              fontWeight: 600),
          Spacing.height(4),
          CustomizedText.bodySmall(
            S.of(context).ndefNoRecordsDescription,
            color: contentTheme.cardText,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool mobile) {
    final status = _controller.exceedsCapacity
        ? S.of(context).ndefCapacityExceeded
        : _controller.dirty
            ? S.of(context).ndefUnsavedChanges
            : '';
    final button = FilledButton.icon(
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
              color: _controller.exceedsCapacity
                  ? contentTheme.danger
                  : contentTheme.cardText,
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
            color: _controller.exceedsCapacity
                ? contentTheme.danger
                : contentTheme.cardText,
          ),
        ),
        button,
      ],
    );
  }

  Widget _buildNotice(IconData icon, String text, Color color,
      {bool square = false}) {
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
          Expanded(child: CustomizedText.bodySmall(text, maxLines: 4)),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: CustomizedText.labelSmall(text, color: color, fontWeight: 700),
    );
  }
}

enum _RecordAction { moveUp, moveDown, edit, delete }
