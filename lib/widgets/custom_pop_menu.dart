import 'package:flutter/material.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';

enum CustomPopupMenuPlacement { left, right, top, bottom }

typedef HideFn = void Function(Function hideFn);

class CustomPopupMenu extends StatefulWidget {
  final Widget menu;
  final ValueChanged<bool> onChange;
  final WidgetBuilder menuBuilder;
  final int selectedIndex;
  final CustomPopupMenuPlacement placement;
  final double offsetX, offsetY;
  final bool backdrop;
  final bool show;
  final HideFn? hideFn;

  const CustomPopupMenu(
      {super.key,
      required this.menu,
      required this.onChange,
      required this.menuBuilder,
      this.selectedIndex = 0,
      this.backdrop = false,
      this.show = true,
      this.placement = CustomPopupMenuPlacement.bottom,
      this.offsetX = 0,
      this.hideFn,
      this.offsetY = 0});

  @override
  _CustomPopupMenuState createState() => _CustomPopupMenuState();
}

class _CustomPopupMenuState extends State<CustomPopupMenu>
    with SingleTickerProviderStateMixin, UIMixin {
  late GlobalKey _key;
  bool isMenuOpen = false;
  late Offset buttonPosition;
  late Size buttonSize;
  OverlayEntry? _overlayEntry;
  OverlayEntry? _overlayEntry1;

  @override
  void initState() {
    _key = LabeledGlobalKey("popup-button");
    super.initState();
    if (widget.hideFn != null) {
      widget.hideFn!(closeMenu);
    }
  }

  findButton() {
    RenderBox? renderBox =
        _key.currentContext!.findRenderObject() as RenderBox?;
    buttonSize = renderBox!.size;
    buttonPosition = renderBox.localToGlobal(Offset.zero);
  }

  closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry1?.remove();
    // if(_animationController.)
    // _animationController.reverse();
    isMenuOpen = false;
  }

  openMenu() {
    findButton();
    _overlayEntry = _overlayEntryBuilder();
    _overlayEntry1 = _overlayEntryBuilder1();
    Overlay.of(context).insert(_overlayEntry1!);
    Overlay.of(context).insert(
      _overlayEntry!,
    );
    isMenuOpen = true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _key,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (isMenuOpen) {
                closeMenu();
                widget.onChange(false);
              } else {
                openMenu();
                widget.onChange(true);
              }
            },
            child: widget.menu),
      ),
    );
  }

  OverlayEntry _overlayEntryBuilder() {
    double left = 0, top = 0;
    if (widget.placement == CustomPopupMenuPlacement.bottom) {
      top = buttonPosition.dy + buttonSize.height + widget.offsetY;
      left = buttonPosition.dx + widget.offsetX;
    } else if (widget.placement == CustomPopupMenuPlacement.right) {
      top = buttonPosition.dy + widget.offsetY;
      left = buttonPosition.dx + buttonSize.width + widget.offsetX;
    }

    return OverlayEntry(
      builder: (context) {
        return Positioned(
          top: top,
          left: left,
          child: widget.menuBuilder(context),
        );
      },
    );
  }

  OverlayEntry _overlayEntryBuilder1() {
    return OverlayEntry(
      builder: (context) {
        return GestureDetector(
          onTap: () => {closeMenu()},
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: widget.backdrop
                ? theme.colorScheme.onBackground.withAlpha(12)
                : Colors.transparent,
          ),
        );
      },
    );
  }
}
