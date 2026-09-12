import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:flutter/material.dart';

abstract final class SettingsStyle {
  static const accent = Color(0xff009b83);
  static bool dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  static Color border(BuildContext context) =>
      dark(context) ? const Color(0xff35414c) : const Color(0xffe5edf2);
  static Color soft(BuildContext context) =>
      dark(context) ? const Color(0xff26343d) : const Color(0xfff5f8fa);
  static Color surface(BuildContext context) =>
      dark(context) ? const Color(0xff202b34) : Colors.white;
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: SettingsStyle.surface(context),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(9),
      side: BorderSide(color: SettingsStyle.border(context)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: SettingsStyle.accent, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: CustomizedText.titleMedium(
                  title,
                  fontSize: 18,
                  fontWeight: 600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

class SettingsRows extends StatelessWidget {
  const SettingsRows({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0)
          Divider(
            height: 1,
            thickness: 1,
            color: SettingsStyle.border(context),
          ),
        children[i],
      ],
    ],
  );
}
