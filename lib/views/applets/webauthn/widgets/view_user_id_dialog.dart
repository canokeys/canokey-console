import 'dart:convert';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void showWebAuthnViewUserIdDialog(BuildContext context, List<int> userId) {
  String hexValue = userId.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
  String? utf8Value;
  try {
    int nullIndex = userId.indexOf(0);
    List<int> trimmedUserId = nullIndex != -1 ? userId.sublist(0, nullIndex) : userId;
    utf8Value = utf8.decode(trimmedUserId);
  } catch (e) {
    // If UTF-8 decoding fails, we'll show only the hex value
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: CustomizedText.bodyLarge(S.of(context).viewUserId),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (utf8Value != null) ...[
            CustomizedText.bodyMedium('UTF-8:'),
            Row(
              children: [
                Expanded(child: SelectableText(utf8Value)),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => Clipboard.setData(ClipboardData(text: utf8Value!)),
                ),
              ],
            ),
            Spacing.height(16),
          ],
          CustomizedText.bodyMedium('Hex:'),
          Row(
            children: [
              Expanded(child: SelectableText(hexValue)),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () => Clipboard.setData(ClipboardData(text: hexValue)),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: CustomizedText.labelLarge(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    ),
  );
}
