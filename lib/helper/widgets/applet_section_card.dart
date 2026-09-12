import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:flutter/material.dart';

abstract final class AppletStyle {
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

class AppletSectionCard extends StatelessWidget {
  const AppletSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.clipBehavior = Clip.antiAlias,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Clip clipBehavior;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) => Material(
    color: AppletStyle.surface(context),
    clipBehavior: clipBehavior,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(9),
      side: BorderSide(color: AppletStyle.border(context)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppletStyle.accent, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: CustomizedText.titleMedium(
                  title,
                  fontSize: 18,
                  fontWeight: 600,
                  color: titleColor,
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
