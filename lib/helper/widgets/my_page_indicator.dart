import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:canokey_console/helper/widgets/my_pages.dart';

class MyPagerIndicator extends StatelessWidget {
  final PagerIndicatorViewModel? viewModel;

  MyPagerIndicator({
    this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    List<PageBubble> bubbles = [];
    for (var i = 0; i < viewModel!.pages.length; ++i) {
      final page = viewModel!.pages[i];

      double? percentActive;

      if (i == viewModel!.activeIndex) {
        percentActive = 1.0 - viewModel!.slidePercent!;
      } else if (i == viewModel!.activeIndex - 1 &&
          viewModel!.slideDirection == SlideDirection.leftToRight) {
        percentActive = viewModel!.slidePercent;
      } else if (i == viewModel!.activeIndex + 1 &&
          viewModel!.slideDirection == SlideDirection.rightToLeft) {
        percentActive = viewModel!.slidePercent;
      } else {
        percentActive = 0.0;
      }

      bool isActive = ((i == viewModel!.activeIndex) && percentActive! > 0.4 ||
          (i != viewModel!.activeIndex && percentActive! > 0.6));

      bubbles.add(
        PageBubble(
          viewModel: PageBubbleViewModel(
              page.color,
              percentActive,
              isActive,
              viewModel!.selectedIndicatorColor,
              viewModel!.unSelectedIndicatorColor),
        ),
      );
    }

    const bubbleWidth = 55.0;
    final baseTranslation =
        ((viewModel!.pages.length * bubbleWidth) / 2) - (bubbleWidth / 2);
    var translation = baseTranslation - (viewModel!.activeIndex * bubbleWidth);

    if (viewModel!.slideDirection == SlideDirection.leftToRight) {
      translation += bubbleWidth * viewModel!.slidePercent!;
    } else if (viewModel!.slideDirection == SlideDirection.rightToLeft) {
      translation -= bubbleWidth * viewModel!.slidePercent!;
    }

    return Column(
      children: <Widget>[
        Expanded(child: Container()),
        Container(
          margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Opacity(
                opacity: (viewModel!.activeIndex ==
                            viewModel!.pages.length - 1 &&
                        viewModel!.slideDirection == SlideDirection.leftToRight
                    ? viewModel!.slidePercent!
                    : (viewModel!.activeIndex == viewModel!.pages.length - 2 &&
                            viewModel!.slideDirection ==
                                SlideDirection.rightToLeft)
                        ? (1 - viewModel!.slidePercent!)
                        : (viewModel!.activeIndex != viewModel!.pages.length - 1
                            ? 1
                            : 0)),
                child: viewModel!.skipWidget,
              ),
              Expanded(
                flex: 1,
                child: Transform(
                  transform: Matrix4.translationValues(translation, 0.0, 0.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: bubbles,
                  ),
                ),
              ),
              Opacity(
                opacity: (viewModel!.activeIndex ==
                            viewModel!.pages.length - 2 &&
                        viewModel!.slideDirection == SlideDirection.rightToLeft
                    ? viewModel!.slidePercent!
                    : (viewModel!.activeIndex == viewModel!.pages.length - 1 &&
                            viewModel!.slideDirection ==
                                SlideDirection.leftToRight)
                        ? (1 - viewModel!.slidePercent!)
                        : (viewModel!.activeIndex == viewModel!.pages.length - 1
                            ? 1
                            : 0)),
                child: viewModel!.doidget,
              )
            ],
          ),
        ),
      ],
    );
  }
}

enum SlideDirection {
  leftToRight,
  rightToLeft,
  none,
}

class PagerIndicatorViewModel {
  final List<PageViewModel> pages;
  final int activeIndex;
  final SlideDirection? slideDirection;
  final double? slidePercent;
  final Color selectedIndicatorColor;
  final Color unSelectedIndicatorColor;
  final Widget skipWidget;
  final Widget doidget;

  PagerIndicatorViewModel(
    this.pages,
    this.activeIndex,
    this.slideDirection,
    this.slidePercent,
    this.selectedIndicatorColor,
    this.unSelectedIndicatorColor,
    this.skipWidget,
    this.doidget,
  );
}

class PageBubble extends StatelessWidget {
  final PageBubbleViewModel? viewModel;

  PageBubble({this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 2),
      width: lerpDouble(25.0, 75.0, viewModel!.activePercent!),
      height: 4,
      child: Row(
        children: <Widget>[
          Container(
              width: lerpDouble(25.0, 75.0, viewModel!.activePercent!),
              height: lerpDouble(25.0, 75.0, viewModel!.activePercent!),
              decoration: BoxDecoration(
                //shape: BoxShape.circle,
                color: viewModel!.isActive
                    ? viewModel!.selectedIndicatorColor
                        .withAlpha((255 * viewModel!.activePercent!).floor())
                    : viewModel!.unSelectedIndicatorColor,
              ),
              child: Container()),
        ],
      ),
    );
  }
}

class PageBubbleViewModel {
  final Color color;
  final double? activePercent;
  final bool isActive;
  final Color selectedIndicatorColor;
  final Color unSelectedIndicatorColor;

  PageBubbleViewModel(
    this.color,
    this.activePercent,
    this.isActive,
    this.selectedIndicatorColor,
    this.unSelectedIndicatorColor,
  );
}
