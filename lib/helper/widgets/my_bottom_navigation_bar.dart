// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/widgets/my_bottom_navigation_bar_item.dart';
import 'package:canokey_console/helper/widgets/my_container.dart';
import 'package:canokey_console/helper/widgets/my_spacing.dart';
import 'package:canokey_console/helper/widgets/my_text_style.dart';

enum MyBottomNavigationBarType {
  normal,
  containered,
}

class MyBottomNavigationBar extends StatefulWidget {
  final List<MyBottomNavigationBarItem>? itemList;
  final Duration? animationDuration;
  final Color? indicatorColor;
  final double? indicatorSize;
  final Decoration? indicatorDecoration;
  final MyBottomNavigationBarType? myBottomNavigationBarType;
  final bool showLabel;
  final bool? showActiveLabel;
  final Color? activeContainerColor;
  final Color? backgroundColor;
  final Axis? labelDirection;
  final double labelSpacing;
  final TextStyle? activeTitleStyle;
  final TextStyle? titleStyle;
  final int initialIndex;
  final Decoration? containerDecoration;
  final BoxShape? containerShape;
  final Color? activeTitleColor;
  final Color? titleColor;
  final double? activeTitleSize;
  final double? titleSize;
  final Color? iconColor;
  final Color? activeIconColor;
  final double? iconSize;
  final double? activeIconSize;
  final EdgeInsetsGeometry? outerPadding;
  final EdgeInsetsGeometry? outerMargin;
  final EdgeInsetsGeometry? containerPadding;
  final double? containerRadius;

  MyBottomNavigationBar(
      {required this.itemList,
      this.animationDuration,
      this.indicatorColor,
      this.indicatorSize,
      this.indicatorDecoration,
      this.myBottomNavigationBarType,
      this.showLabel = true,
      this.activeContainerColor,
      this.backgroundColor,
      this.showActiveLabel,
      this.labelDirection = Axis.horizontal,
      this.labelSpacing = 8,
      this.activeTitleStyle,
      this.titleStyle,
      this.initialIndex = 0,
      this.activeTitleColor,
      this.titleColor,
      this.activeTitleSize,
      this.titleSize,
      this.iconColor,
      this.activeIconColor,
      this.iconSize,
      this.activeIconSize,
      this.containerDecoration,
      this.containerShape,
      this.outerPadding,
      this.outerMargin,
      this.containerRadius,
      this.containerPadding});

  @override
  _MyBottomNavigationBarState createState() => _MyBottomNavigationBarState();
}

class _MyBottomNavigationBarState extends State<MyBottomNavigationBar>
    with SingleTickerProviderStateMixin {
  late List<MyBottomNavigationBarItem>? itemList;
  late int _currentIndex;
  late Duration? animationDuration;
  late TabController? _tabController;
  late Color? indicatorColor;
  late double? indicatorSize;
  late Decoration? indicatorDecoration;
  late MyBottomNavigationBarType? myBottomNavigationBarType;
  late bool showLabel;
  late bool showActiveLabel;
  late Color? activeContainerColor;
  late Color? backgroundColor;
  late Decoration? containerDecoration;
  late BoxShape? containerShape;
  late TextStyle? activeTitleStyle;
  late TextStyle? titleStyle;
  late Color? activeTitleColor;
  late Color? titleColor;
  late double? activeTitleSize;
  late Color? iconColor;
  late Color? activeIconColor;
  late double? iconSize;
  late double? activeIconSize;
  late EdgeInsetsGeometry? outerPadding;
  late EdgeInsetsGeometry? containerPadding;
  late EdgeInsetsGeometry? outerMargin;
  late double? containerRadius;

  _handleTabSelection() {
    setState(() {
      _currentIndex = _tabController!.index;
    });
  }

  @override
  void initState() {
    itemList = widget.itemList;
    _currentIndex = widget.initialIndex;
    _tabController = TabController(
        length: itemList!.length,
        initialIndex: widget.initialIndex,
        vsync: this);
    _tabController!.addListener(_handleTabSelection);
    _tabController!.animation!.addListener(() {
      final animationValue = _tabController!.animation!.value;
      if (animationValue - _currentIndex > 0.5) {
        setState(() {
          _currentIndex = _currentIndex + 1;
        });
      } else if (animationValue - _currentIndex < -0.5) {
        setState(() {
          _currentIndex = _currentIndex - 1;
        });
      }
    });
    super.initState();
  }

  @override
  dispose() {
    super.dispose();
    _tabController!.dispose();
  }

  List<Widget> getListOfViews() {
    List<Widget> viewList = [];
    for (int i = 0; i < itemList!.length; i++) {
      viewList.add(itemList![i].page!);
    }
    return viewList;
  }

  Widget getItem(int index) {
    MyBottomNavigationBarItem item = itemList![index];

    if (MyBottomNavigationBarType == MyBottomNavigationBarType.normal) {
      return Container(
        child: (_currentIndex == index)
            ? Wrap(
                direction: widget.labelDirection!,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  item.activeIcon ??
                      Icon(
                        item.activeIconData,
                        size: activeIconSize ?? item.activeIconSize ?? 14,
                        color: activeIconColor ??
                            item.activeIconColor ??
                            theme.primaryColor,
                      ),
                  widget.labelDirection == Axis.horizontal
                      ? MySpacing.width(
                          showActiveLabel ? widget.labelSpacing : 0)
                      : MySpacing.height(
                          showActiveLabel ? widget.labelSpacing : 0),
                  showActiveLabel
                      ? Text(
                          item.title!,
                          style: activeTitleStyle ??
                              item.activeTitleStyle ??
                              MyTextStyle.labelSmall(
                                  color: activeTitleColor ??
                                      item.activeTitleColor ??
                                      theme.primaryColor,
                                  fontSize:
                                      activeTitleSize ?? item.activeTitleSize),
                        )
                      : Container(),
                ],
              )
            : Wrap(
                direction: widget.labelDirection!,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  item.icon ??
                      Icon(
                        item.iconData,
                        size: iconSize ?? item.iconSize ?? 14,
                        color: iconColor ??
                            item.iconColor ??
                            theme.colorScheme.onBackground,
                      ),
                  widget.labelDirection == Axis.horizontal
                      ? MySpacing.width(showLabel ? widget.labelSpacing : 0)
                      : MySpacing.height(showLabel ? widget.labelSpacing : 0),
                  showLabel
                      ? Text(
                          item.title!,
                          style: titleStyle ??
                              item.titleStyle ??
                              MyTextStyle.labelSmall(
                                  color: titleColor ??
                                      item.titleColor ??
                                      theme.colorScheme.onBackground,
                                  fontSize: widget.titleSize ?? item.titleSize),
                        )
                      : Container(),
                ],
              ),
      );
    } else {
      Widget iconWidget;
      if (item.activeIcon != null) {
        iconWidget = item.activeIcon!;
      } else {
        iconWidget = Icon(
          item.activeIconData ?? item.iconData,
          size: activeIconSize ?? item.activeIconSize ?? 24,
          color: activeIconColor ?? item.activeIconColor ?? theme.primaryColor,
        );
      }

      return (_currentIndex == index)
          ? MyContainer(
              padding: containerPadding ?? MySpacing.all(8),
              borderRadiusAll: containerRadius ?? 8,
              shape: containerShape ?? BoxShape.rectangle,
              color: activeContainerColor,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  iconWidget,
                  MySpacing.width(showActiveLabel ? 8 : 0),
                  showActiveLabel
                      ? Text(
                          item.title!,
                          style: activeTitleStyle ??
                              item.activeTitleStyle ??
                              MyTextStyle.labelSmall(
                                  color: activeTitleColor ??
                                      item.activeTitleColor ??
                                      theme.primaryColor,
                                  fontSize:
                                      activeTitleSize ?? item.activeTitleSize),
                        )
                      : Container(),
                ],
              ),
            )
          : item.icon ??
              Icon(
                item.iconData,
                size: iconSize ?? item.iconSize ?? 24,
                color: iconColor ??
                    item.iconColor ??
                    theme.colorScheme.onBackground.withAlpha(150),
              );
    }
  }

  List<Widget> getListOfItems() {
    List<Widget> list = [];

    double singleWidth = (MediaQuery.of(context).size.width - 50) /
        (itemList!.length +
            (widget.showLabel ? 0 : (showActiveLabel ? 0.5 : 0)));

    for (int i = 0; i < itemList!.length; i++) {
      double containerWidth = widget.showLabel
          ? (singleWidth)
          : (showActiveLabel
              ? (i == _currentIndex ? singleWidth * 1.5 : singleWidth)
              : singleWidth);
      list.add(SizedBox(
        width: containerWidth,
        child: InkWell(
          child: Center(child: getItem(i)),
          onTap: () {
            setState(() {
              _currentIndex = i;
              _tabController!.index = i;
            });
          },
        ),
      ));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    // animationDuration=widget.animationDuration!;
    indicatorColor = widget.indicatorColor ?? theme.primaryColor;
    indicatorSize = widget.indicatorSize;
    indicatorDecoration = widget.indicatorDecoration;
    myBottomNavigationBarType =
        widget.myBottomNavigationBarType ?? MyBottomNavigationBarType.normal;
    showLabel = widget.showLabel;
    showActiveLabel = widget.showActiveLabel ?? true;
    activeContainerColor =
        widget.activeContainerColor ?? theme.primaryColor.withAlpha(100);
    backgroundColor = widget.backgroundColor ?? theme.colorScheme.background;
    activeTitleStyle = widget.activeTitleStyle;
    titleStyle = widget.titleStyle;
    activeTitleColor = widget.activeTitleColor;
    titleColor = widget.titleColor;
    activeTitleSize = widget.activeTitleSize;
    iconColor = widget.iconColor;
    activeIconColor = widget.activeIconColor;
    iconSize = widget.iconSize;
    activeIconSize = widget.activeIconSize;
    containerDecoration = widget.containerDecoration;
    containerShape = widget.containerShape;
    outerPadding = widget.outerPadding;
    outerMargin = widget.outerMargin;
    containerRadius = widget.containerRadius;
    containerPadding = widget.containerPadding;

    return Column(
      children: [
        Expanded(
          child: TabBarView(
            physics: ClampingScrollPhysics(),
            controller: _tabController,
            children: getListOfViews(),
          ),
        ),
        Container(
          padding: outerPadding ?? MySpacing.all(16),
          margin: outerMargin ?? MySpacing.zero,
          decoration: containerDecoration ??
              BoxDecoration(
                color: backgroundColor,
              ),
          child: Row(
            children: getListOfItems(),
          ),
        ),
      ],
    );
  }
}
