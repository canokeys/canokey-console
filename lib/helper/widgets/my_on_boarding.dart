import 'dart:async';

import 'package:flutter/material.dart';
import 'package:canokey_console/helper/widgets/my_page_dragger.dart';
import 'package:canokey_console/helper/widgets/my_page_indicator.dart';
import 'package:canokey_console/helper/widgets/my_page_reveal.dart';
import 'package:canokey_console/helper/widgets/my_pages.dart';

class MyOnBoarding extends StatefulWidget {
  final List<PageViewModel> pages;
  final Color selectedIndicatorColor;
  final Color unSelectedIndicatorColor;
  final Widget skipWidget, doneWidget;

  const MyOnBoarding(
      {Key? key,
      required this.pages,
      required this.selectedIndicatorColor,
      required this.unSelectedIndicatorColor,
      required this.skipWidget,
      required this.doneWidget})
      : super(key: key);

  @override
  _MyOnBoardingState createState() => _MyOnBoardingState();
}

class _MyOnBoardingState extends State<MyOnBoarding>
    with TickerProviderStateMixin {
  StreamController<SlideUpdate>? slideUpdateStream;
  AnimatedPageDragger? animatedPageDragger;

  int activeIndex = 0;

  SlideDirection? slideDirection = SlideDirection.none;
  int nextPageIndex = 0;

  double? slidePercent = 0.0;

  _MyOnBoardingState() {
    slideUpdateStream = StreamController<SlideUpdate>();

    slideUpdateStream!.stream.listen((SlideUpdate event) {
      setState(() {
        if (event.updateType == UpdateType.dragging) {
          slideDirection = event.direction;
          slidePercent = event.slidePercent;

          if (slideDirection == SlideDirection.leftToRight) {
            nextPageIndex = activeIndex - 1;
          } else if (slideDirection == SlideDirection.rightToLeft) {
            nextPageIndex = activeIndex + 1;
          } else {
            nextPageIndex = activeIndex;
          }
        } else if (event.updateType == UpdateType.doneDragging) {
          if (slidePercent! > 0.5) {
            animatedPageDragger = AnimatedPageDragger(
              slideDirection: slideDirection,
              transitionGoal: TransitionGoal.open,
              slidePercent: slidePercent,
              slideUpdateStream: slideUpdateStream,
              vsync: this,
            );
          } else {
            animatedPageDragger = AnimatedPageDragger(
              slideDirection: slideDirection,
              transitionGoal: TransitionGoal.close,
              slidePercent: slidePercent,
              slideUpdateStream: slideUpdateStream,
              vsync: this,
            );
          }

          animatedPageDragger!.run();
        } else if (event.updateType == UpdateType.animating) {
          slideDirection = event.direction;
          slidePercent = event.slidePercent;
        } else if (event.updateType == UpdateType.doneAnimating) {
          if (animatedPageDragger?.transitionGoal == TransitionGoal.open) {
            activeIndex = nextPageIndex;
          }
          slideDirection = SlideDirection.none;
          slidePercent = 0.0;

          animatedPageDragger!.dispose();
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    slideUpdateStream!.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MySinglePage(
            viewModel: widget.pages[activeIndex],
            percentVisible: 1.0,
          ),
          MyPageReveal(
            revealPercent: slidePercent,
            child: MySinglePage(
              viewModel: widget.pages[nextPageIndex],
              percentVisible: slidePercent,
            ),
          ),
          MyPagerIndicator(
            viewModel: PagerIndicatorViewModel(
                widget.pages,
                activeIndex,
                slideDirection,
                slidePercent,
                widget.selectedIndicatorColor,
                widget.unSelectedIndicatorColor,
                widget.skipWidget,
                widget.doneWidget),
          ),
          MyPageDragger(
            canDragLeftToRight: activeIndex > 0,
            canDragRightToLeft: activeIndex < widget.pages.length - 1,
            slideUpdateStream: slideUpdateStream,
          )
        ],
      ),
    );
  }
}
