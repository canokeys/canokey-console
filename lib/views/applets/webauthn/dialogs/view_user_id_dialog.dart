import 'dart:convert';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:canokey_console/helper/utils/prompts.dart';

class WebAuthnViewUserIdDialog extends StatelessWidget {
  final List<int> userId;

  const WebAuthnViewUserIdDialog({super.key, required this.userId});

  static Future<void> show(List<int> userId) {
    return AppDialog.show(WebAuthnViewUserIdDialog(userId: userId));
  }

  @override
  Widget build(BuildContext context) {
    String hexValue = userId
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join(' ');
    String? utf8Value;
    try {
      int nullIndex = userId.indexOf(0);
      List<int> trimmedUserId = nullIndex != -1
          ? userId.sublist(0, nullIndex)
          : userId;
      utf8Value = utf8.decode(trimmedUserId);
    } catch (e) {
      // If UTF-8 decoding fails, we'll show only the hex value
    }

    return AppDialogSurface(
      child: SizedBox(
        width: AppDialogWidth.compact,
        child: AppDialogLayout(
          header: AppDialogHeader(title: S.of(context).viewUserId),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (utf8Value != null) ...[
                  CustomizedText.bodyMedium('UTF-8:'),
                  Row(
                    children: [
                      Expanded(child: SelectableText(utf8Value)),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).copyButtonLabel,
                        icon: const Icon(Icons.copy),
                        onPressed: () => Prompts.copyText(utf8Value!),
                      ),
                    ],
                  ),
                  Spacing.height(16),
                ],
                CustomizedText.bodyMedium('${S.of(context).ndefPayloadHex}:'),
                Row(
                  children: [
                    Expanded(child: SelectableText(hexValue)),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).copyButtonLabel,
                      icon: const Icon(Icons.copy),
                      onPressed: () => Prompts.copyText(hexValue),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            AppDialogAction(
              label: S.of(context).close,
              secondary: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
