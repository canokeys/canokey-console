// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:canokey_console/helper/widgets/constant.dart';
import 'package:flutter/material.dart';

enum ButtonType { elevated, outlined, text }

class CustomizedButton extends StatelessWidget {
  final ButtonType? buttonType;

  final ButtonStyle? style;

  final VoidCallback? onPressed;

  final bool? disabled;
  final bool? block;
  final bool soft;

  final MaterialStateProperty<EdgeInsetsGeometry>? msPadding;
  final EdgeInsetsGeometry? padding;

  final MaterialStateProperty<double>? msElevation;
  final double? elevation;

  final MaterialStateProperty<EdgeInsetsGeometry>? msShape;
  final OutlinedBorder? shape;
  final BorderRadiusGeometry? borderRadius;
  final double? borderRadiusAll;

  final MaterialStateProperty<Color>? msBackgroundColor;
  final Color? backgroundColor;

  final MaterialStateProperty<BorderSide>? msSide;
  final BorderSide? side;
  final Color borderColor;

  final MaterialTapTargetSize? tapTargetSize;

  final MaterialStateProperty<Color>? msShadowColor;
  final Color? shadowColor;

  final Color? splashColor;

  final Widget child;

  CustomizedButton(
      {this.onPressed,
      required this.child,
      this.msPadding,
      this.padding,
      this.msShape,
      this.shape,
      this.borderRadius,
      this.borderRadiusAll = 0,
      this.msBackgroundColor,
      this.backgroundColor,
      this.buttonType = ButtonType.elevated,
      this.style,
      this.msShadowColor,
      this.msSide,
      this.side,
      this.borderColor = Colors.transparent,
      this.disabled = false,
      this.block = false,
      this.soft = false,
      this.msElevation,
      this.elevation = 4,
      this.shadowColor,
      this.tapTargetSize = MaterialTapTargetSize.padded,
      this.splashColor});

  CustomizedButton.rounded(
      {required this.onPressed,
      required this.child,
      this.msPadding,
      this.padding,
      this.msShape,
      this.shape,
      this.borderRadius,
      this.borderRadiusAll,
      this.msBackgroundColor,
      this.backgroundColor,
      this.buttonType = ButtonType.elevated,
      this.style,
      this.block = false,
      this.msSide,
      this.disabled = false,
      this.side,
      this.soft = false,
      this.borderColor = Colors.transparent,
      this.msShadowColor,
      this.msElevation,
      this.elevation = 4,
      this.shadowColor,
      this.tapTargetSize = MaterialTapTargetSize.padded,
      this.splashColor});

  CustomizedButton.small(
      {required this.onPressed,
      required this.child,
      this.msPadding,
      this.padding = const EdgeInsets.fromLTRB(8, 4, 8, 4),
      this.msShape,
      this.shape,
      this.borderRadius,
      this.borderRadiusAll,
      this.msBackgroundColor,
      this.backgroundColor,
      this.buttonType = ButtonType.elevated,
      this.style,
      this.block = false,
      this.msSide,
      this.soft = false,
      this.disabled = false,
      this.side,
      this.borderColor = Colors.transparent,
      this.msShadowColor,
      this.msElevation,
      this.elevation = 4,
      this.shadowColor,
      this.tapTargetSize = MaterialTapTargetSize.padded,
      this.splashColor});

  CustomizedButton.medium(
      {required this.onPressed,
      required this.child,
      this.msPadding,
      this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 16),
      this.msShape,
      this.block = false,
      this.shape,
      this.soft = false,
      this.borderRadius,
      this.borderRadiusAll,
      this.msBackgroundColor,
      this.backgroundColor,
      this.buttonType = ButtonType.elevated,
      this.style,
      this.msSide,
      this.disabled = false,
      this.side,
      this.borderColor = Colors.transparent,
      this.msShadowColor,
      this.msElevation,
      this.elevation = 4,
      this.shadowColor,
      this.tapTargetSize = MaterialTapTargetSize.padded,
      this.splashColor});

  CustomizedButton.text(
      {required this.onPressed,
      required this.child,
      this.msPadding,
      this.padding = const EdgeInsets.all(0),
      this.msShape,
      this.block = false,
      this.shape,
      this.soft = false,
      this.borderRadius,
      this.borderRadiusAll,
      this.msBackgroundColor,
      this.backgroundColor,
      this.buttonType = ButtonType.text,
      this.style,
      this.msSide,
      this.disabled = false,
      this.side,
      this.borderColor = Colors.transparent,
      this.msShadowColor,
      this.msElevation,
      this.elevation = 4,
      this.shadowColor,
      this.tapTargetSize = MaterialTapTargetSize.padded,
      this.splashColor});

  CustomizedButton.block(
      {required this.onPressed,
      required this.child,
      this.msPadding,
      this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 16),
      this.msShape,
      this.block = true,
      this.shape,
      this.soft = false,
      this.borderRadius,
      this.borderRadiusAll,
      this.msBackgroundColor,
      this.backgroundColor,
      this.buttonType = ButtonType.elevated,
      this.style,
      this.msSide,
      this.disabled = false,
      this.side,
      this.borderColor = Colors.transparent,
      this.msShadowColor,
      this.msElevation,
      this.elevation = 4,
      this.shadowColor,
      this.tapTargetSize = MaterialTapTargetSize.padded,
      this.splashColor});

  CustomizedButton.outlined(
      {required this.onPressed,
      required this.child,
      this.msPadding,
      this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 16),
      this.msShape,
      this.soft = false,
      this.shape,
      this.borderRadius,
      this.borderRadiusAll,
      this.msBackgroundColor,
      this.backgroundColor,
      this.buttonType = ButtonType.outlined,
      this.style,
      this.msSide,
      this.block = false,
      this.side,
      this.disabled = false,
      this.borderColor = Colors.transparent,
      this.msShadowColor,
      this.msElevation,
      this.elevation = 4,
      this.shadowColor,
      this.tapTargetSize = MaterialTapTargetSize.padded,
      this.splashColor});

  CustomizedButton.large(
      {required this.onPressed,
      required this.child,
      this.msPadding,
      this.padding = const EdgeInsets.fromLTRB(36, 20, 36, 20),
      this.msShape,
      this.shape,
      this.soft = false,
      this.borderRadius,
      this.borderRadiusAll,
      this.msBackgroundColor,
      this.backgroundColor,
      this.buttonType = ButtonType.elevated,
      this.style,
      this.disabled = false,
      this.msSide,
      this.side,
      this.block = false,
      this.borderColor = Colors.transparent,
      this.msShadowColor,
      this.msElevation,
      this.elevation = 4,
      this.shadowColor,
      this.tapTargetSize = MaterialTapTargetSize.padded,
      this.splashColor});

  @override
  Widget build(BuildContext context) {
    Widget button;
    Color bgColor = backgroundColor ?? Theme.of(context).colorScheme.primary;

    if (buttonType == ButtonType.outlined) {
      button = OutlinedButton(
        onPressed: onPressed,
        style: style ??
            ButtonStyle(
                tapTargetSize: tapTargetSize,
                side: msSide ??
                    MaterialStateProperty.all(side ??
                        BorderSide(
                          color: soft ? borderColor.withAlpha(100) : borderColor,
                          width: soft ? 0.8 : 1,
                        )),
                overlayColor: MaterialStateProperty.all(splashColor ?? (bgColor.withAlpha(40))),
                backgroundColor: soft ? MaterialStateProperty.all(borderColor.withAlpha(40)) : null,
                foregroundColor: MaterialStateProperty.all(borderColor.withAlpha(40)),
                shadowColor: msShadowColor ?? MaterialStateProperty.all(shadowColor),
                padding: msPadding ?? MaterialStateProperty.all(padding),
                shape: MaterialStateProperty.all(shape ??
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadiusAll ?? WidgetConstant.constant.buttonRadius),
                    ))),
        child: child,
      );
    } else if (buttonType == ButtonType.elevated) {
      button = ElevatedButton(
          style: style ??
              ButtonStyle(
                  tapTargetSize: tapTargetSize,
                  visualDensity: VisualDensity.compact,
                  elevation: msElevation ??
                      MaterialStateProperty.resolveWith<double>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return 0;
                          } else if (states.contains(MaterialState.pressed))
                            return elevation! * 2;
                          else if (states.contains(MaterialState.hovered)) return elevation! * 1.5;
                          return elevation!;
                        },
                      ),
                  backgroundColor: msBackgroundColor ??
                      MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) return bgColor.withAlpha(100);
                          return bgColor;
                        },
                      ),
                  shadowColor: msShadowColor ?? MaterialStateProperty.all(shadowColor ?? bgColor),
                  padding: msPadding ?? MaterialStateProperty.all(padding),
                  overlayColor: MaterialStateProperty.all(splashColor ?? (Theme.of(context).colorScheme.onPrimary.withAlpha(36))),
                  shape: MaterialStateProperty.all(shape ??
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadiusAll ?? WidgetConstant.constant.buttonRadius),
                      ))),
          onPressed: onPressed,
          child: child);
    } else {
      button = TextButton(
        style: ButtonStyle(
            overlayColor: MaterialStateProperty.all(splashColor ?? (bgColor.withAlpha(40))),
            padding: msPadding ?? MaterialStateProperty.all(padding),
            // visualDensity: VisualDensity.standard,
            tapTargetSize: tapTargetSize),
        onPressed: onPressed,
        child: child,
      );
    }

    return block! ? Row(children: [Expanded(child: button)]) : button;
  }
}
