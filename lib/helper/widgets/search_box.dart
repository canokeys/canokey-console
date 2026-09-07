import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_text_style.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:canokey_console/helper/widgets/lucide_icons.dart';

class SearchBox extends StatefulWidget {
  const SearchBox({super.key, this.formKey});

  final GlobalKey<FormState>? formKey;

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> with UIMixin {
  final FocusNode _focusNode = FocusNode();
  static const _findShortcuts = [
    SingleActivator(LogicalKeyboardKey.keyF, control: true),
    SingleActivator(LogicalKeyboardKey.keyF, meta: true),
  ];

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addEarlyKeyEventHandler(_handleFindShortcut);
  }

  KeyEventResult _handleFindShortcut(KeyEvent event) {
    if (!mounted ||
        ModalRoute.of(context)?.isCurrent == false ||
        !_focusNode.canRequestFocus ||
        !_findShortcuts.any(
            (shortcut) => shortcut.accepts(event, HardwareKeyboard.instance))) {
      return KeyEventResult.ignored;
    }

    // Handle find before the focused text field or browser consumes it.
    _focusNode.requestFocus();
    SmartCard.eject();
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    FocusManager.instance.removeEarlyKeyEventHandler(_handleFindShortcut);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: TextFormField(
        focusNode: _focusNode,
        maxLines: 1,
        style: CustomizedTextStyle.bodyMedium(),
        onChanged: (value) {
          if (Get.currentRoute == '/applets/oath') {
            Get.find<RxString>(tag: 'oath_search').value = value;
          } else if (Get.currentRoute == '/applets/webauthn') {
            Get.find<RxString>(tag: 'webauthn_search').value = value;
          }
        },
        onTap: SmartCard.eject,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        decoration: InputDecoration(
          hintText: S.of(context).search,
          hintStyle: CustomizedTextStyle.bodySmall(xMuted: true),
          border: outlineInputBorder,
          enabledBorder: outlineInputBorder,
          focusedBorder: focusedInputBorder,
          prefixIcon: const Align(
            alignment: Alignment.center,
            child: Icon(LucideIcons.search, size: 14),
          ),
          prefixIconConstraints: const BoxConstraints(
              minWidth: 36, maxWidth: 36, minHeight: 32, maxHeight: 32),
          contentPadding: Spacing.xy(16, 12),
          isCollapsed: true,
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
      ),
    );
  }
}
