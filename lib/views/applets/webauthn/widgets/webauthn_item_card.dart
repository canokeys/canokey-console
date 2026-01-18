import 'package:canokey_console/controller/applets/webauthn/webauthn_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/shadow.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_card.dart';
import 'package:canokey_console/helper/widgets/customized_container.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/models/webauthn.dart';
import 'package:canokey_console/views/applets/webauthn/dialogs/delete_dialog.dart';
import 'package:canokey_console/views/applets/webauthn/dialogs/view_user_id_dialog.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WebAuthnItemCard extends StatelessWidget with UIMixin {
  final WebAuthnItem item;
  final WebAuthnController controller;

  const WebAuthnItemCard({
    super.key,
    required this.item,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return CustomizedCard(
      shadow: Shadow(elevation: 0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: CustomizedText.bodyMedium(item.userDisplayName.isEmpty ? S.of(context).passkey : item.userDisplayName, fontSize: 16, fontWeight: 600, overflow: TextOverflow.ellipsis)),
              CustomizedContainer.none(
                paddingAll: 8,
                borderRadiusAll: 5,
                child: PopupMenuButton(
                  offset: const Offset(0, 10),
                  position: PopupMenuPosition.under,
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      padding: Spacing.xy(16, 8),
                      height: 10,
                      child: CustomizedText.bodySmall(S.of(context).viewUserId),
                      onTap: () => WebAuthnViewUserIdDialog.show(item.userId),
                    ),
                    PopupMenuItem(
                      padding: Spacing.xy(16, 8),
                      height: 10,
                      child: CustomizedText.bodySmall(S.of(context).delete),
                      onTap: () => WebAuthnDeleteDialog.show(item, () => controller.delete(item.credentialId)),
                    ),
                  ],
                  child: const Icon(LucideIcons.moreHorizontal, size: 18),
                ),
              ),
            ],
          ),
          Row(
            children: [
              CustomizedContainer.rounded(
                color: contentTheme.primary.withAlpha(30),
                paddingAll: 2,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: Icon(LucideIcons.user, size: 16, color: contentTheme.primary),
              ),
              Spacing.width(12),
              Flexible(child: CustomizedText.bodyMedium(item.userName, overflow: TextOverflow.ellipsis)),
            ],
          ),
          Row(
            children: [
              CustomizedContainer.rounded(
                color: contentTheme.primary.withAlpha(30),
                paddingAll: 2,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: Icon(LucideIcons.globe, size: 16, color: contentTheme.primary),
              ),
              Spacing.width(12),
              CustomizedText.bodyMedium(item.rpId),
            ],
          ),
        ],
      ),
    );
  }
}
