import 'package:canokey_console/controller/applets/webauthn/webauthn_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';
import 'package:canokey_console/models/webauthn.dart';
import 'package:canokey_console/views/applets/webauthn/dialogs/delete_dialog.dart';
import 'package:canokey_console/views/applets/webauthn/dialogs/view_user_id_dialog.dart';
import 'package:flutter/material.dart';

enum _CredentialAction { viewUserId, delete }

class WebAuthnItemCard extends StatelessWidget {
  final WebAuthnItem item;
  final WebAuthnController controller;

  const WebAuthnItemCard({
    super.key,
    required this.item,
    required this.controller,
  });

  static const accent = Color(0xff009b83);

  Widget _detail(BuildContext context, IconData icon, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: accent),
      const SizedBox(width: 10),
      Expanded(
        child: Tooltip(
          message: value,
          child: CustomizedText.bodyMedium(
            value,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = Theme.of(context).colorScheme.onSurface;
    final danger = Theme.of(context).colorScheme.error;
    final title = item.userDisplayName.isEmpty
        ? S.of(context).passkey
        : item.userDisplayName;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        return Material(
          color: dark ? const Color(0xff202b34) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: dark ? const Color(0xff35414c) : const Color(0xffe5edf2),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 44 : 60,
                  height: compact ? 44 : 60,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.user,
                    color: accent,
                    size: compact ? 26 : 32,
                  ),
                ),
                SizedBox(width: compact ? 12 : 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tooltip(
                        message: title,
                        child: CustomizedText.titleMedium(
                          title,
                          color: ink,
                          fontSize: 18,
                          fontWeight: 600,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _detail(context, LucideIcons.user, item.userName),
                      const SizedBox(height: 10),
                      _detail(context, LucideIcons.globe, item.rpId),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<_CredentialAction>(
                  tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
                  position: PopupMenuPosition.under,
                  offset: const Offset(0, 8),
                  color: dark ? const Color(0xff202b34) : Colors.white,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  onSelected: (action) {
                    switch (action) {
                      case _CredentialAction.viewUserId:
                        WebAuthnViewUserIdDialog.show(item.userId);
                      case _CredentialAction.delete:
                        WebAuthnDeleteDialog.show(
                          item,
                          () => controller.delete(item.credentialId),
                        );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _CredentialAction.viewUserId,
                      child: Row(
                        children: [
                          Icon(LucideIcons.user, size: 20, color: ink),
                          const SizedBox(width: 14),
                          Flexible(
                            child: CustomizedText.bodyMedium(
                              S.of(context).viewUserId,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _CredentialAction.delete,
                      child: Row(
                        children: [
                          Icon(LucideIcons.trash2, size: 20, color: danger),
                          const SizedBox(width: 14),
                          Flexible(
                            child: CustomizedText.bodyMedium(
                              S.of(context).delete,
                              color: danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      LucideIcons.moreHorizontal,
                      size: 22,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
