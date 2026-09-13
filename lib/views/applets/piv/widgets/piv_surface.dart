import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:canokey_console/helper/widgets/customized_text_style.dart';

abstract final class PivStyle {
  static const primary = Color(0xff009b83);
  static bool dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  static Color ink(BuildContext context) =>
      dark(context) ? const Color(0xffe6edf4) : const Color(0xff182536);
  static Color muted(BuildContext context) =>
      dark(context) ? const Color(0xffa5b3c4) : const Color(0xff748196);
  static Color border(BuildContext context) =>
      dark(context) ? const Color(0xff35414c) : const Color(0xffe5edf2);
  static Color soft(BuildContext context) =>
      dark(context) ? const Color(0xff26343d) : const Color(0xfff4f7f9);
  static Color surface(BuildContext context) =>
      dark(context) ? const Color(0xff202b34) : Colors.white;
  // Resolve each font weight once; copying a style must not start a new
  // Google Fonts loading future for every label on every rebuild.
  static final TextStyle _regular = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w400,
  ).copyWith(fontFamilyFallback: CustomizedTextStyle.cjkFontFallback);
  static final TextStyle _semibold = GoogleFonts.ibmPlexSans(
    fontWeight: FontWeight.w600,
  ).copyWith(fontFamilyFallback: CustomizedTextStyle.cjkFontFallback);
  static TextStyle text(
    BuildContext context,
    double size, {
    bool bold = false,
    bool secondary = false,
  }) => (bold ? _semibold : _regular).copyWith(
    fontSize: size,
    height: 1.4,
    color: secondary ? muted(context) : ink(context),
    letterSpacing: 0,
  );

  static double buttonHeight(BuildContext context) =>
      44 +
      (MediaQuery.textScalerOf(context).scale(13) - 13).clamp(
            0,
            double.infinity,
          ) *
          2.8;

  static TextStyle monospace(BuildContext context, double size) =>
      text(context, size).copyWith(fontFamily: 'CanoKey Mono');
}

class PivSurface extends StatelessWidget {
  const PivSurface({
    super.key,
    required this.child,
    this.danger = false,
    this.padding = const EdgeInsets.all(18),
    this.tinted = false,
  });
  final Widget child;
  final bool danger;
  final bool tinted;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Material(
    color: danger
        ? (PivStyle.dark(context)
              ? const Color(0xff39292f)
              : const Color(0xfffff8f9))
        : tinted
        ? (PivStyle.dark(context)
              ? const Color(0xff24333d)
              : const Color(0xfff9fcfd))
        : PivStyle.surface(context),
    shape: RoundedRectangleBorder(
      side: BorderSide(
        color: danger
            ? const Color(0xffef5266).withValues(alpha: .2)
            : PivStyle.border(context),
      ),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class PivIcon extends StatelessWidget {
  const PivIcon(this.icon, {super.key, this.size = 42, this.neutral = false});
  final IconData icon;
  final double size;
  final bool neutral;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: neutral
          ? PivStyle.soft(context)
          : PivStyle.dark(context)
          ? const Color(0xff163f3b)
          : const Color(0xffdefaf3),
      borderRadius: BorderRadius.circular(size > 48 ? 14 : 10),
    ),
    child: Icon(
      icon,
      size: size * .55,
      color: neutral ? PivStyle.muted(context) : const Color(0xff008775),
    ),
  );
}

class PivStatus extends StatelessWidget {
  const PivStatus(
    this.label, {
    super.key,
    this.active = true,
    this.danger = false,
    this.pill = true,
  });
  final String label;
  final bool active, danger, pill;
  @override
  Widget build(BuildContext context) {
    final color = danger
        ? const Color(0xffe63652)
        : active
        ? PivStyle.primary
        : PivStyle.muted(context);
    return Container(
      padding: pill
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
          : EdgeInsets.zero,
      decoration: pill
          ? BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(7),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: PivStyle.text(
                context,
                12,
                bold: true,
              ).copyWith(color: pill ? color : PivStyle.ink(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class PivSectionHeader extends StatelessWidget {
  const PivSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String? description;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      PivIcon(icon, size: 40),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: PivStyle.text(context, 17, bold: true)),
            if (description != null) ...[
              const SizedBox(height: 3),
              Text(
                description!,
                style: PivStyle.text(context, 12, secondary: true),
              ),
            ],
          ],
        ),
      ),
      if (trailing != null) ...[const SizedBox(width: 16), trailing!],
    ],
  );
}

class PivButton extends StatelessWidget {
  const PivButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = false,
    this.danger = false,
    this.compact = false,
    this.width = 120,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary, danger, compact;
  final double? width;
  @override
  Widget build(BuildContext context) {
    final foreground = primary || danger ? Colors.white : PivStyle.ink(context);
    return SizedBox(
      width: width,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: foreground,
          disabledForegroundColor: PivStyle.muted(
            context,
          ).withValues(alpha: .55),
          backgroundColor: danger
              ? const Color(0xffe73550)
              : primary
              ? PivStyle.primary
              : PivStyle.soft(context),
          minimumSize: Size(96, PivStyle.buttonHeight(context)),
          maximumSize: Size(double.infinity, PivStyle.buttonHeight(context)),
          fixedSize: Size.fromHeight(PivStyle.buttonHeight(context)),
          visualDensity: VisualDensity.standard,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: 4,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: primary || danger
                  ? Colors.transparent
                  : PivStyle.border(context),
            ),
          ),
          textStyle: PivStyle.text(context, compact ? 12 : 13, bold: primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 9),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PivDialog extends StatelessWidget {
  const PivDialog({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => AppDialogSurface(child: child);
}
