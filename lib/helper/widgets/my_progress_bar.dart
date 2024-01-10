import 'package:flutter/material.dart';

class MyProgressBar extends StatelessWidget {
  final Color activeColor, inactiveColor;
  final double progress, height, width, radius;

  const MyProgressBar(
      {this.activeColor = Colors.blue,
      this.inactiveColor = Colors.grey,
      this.progress = 1,
      this.height = 1,
      this.width = 100,
      this.radius = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          color: inactiveColor,
          borderRadius: BorderRadius.all(Radius.circular(radius))),
      child: Stack(
        children: <Widget>[
          Container(
            width: width * progress,
            height: height,
            decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.all(Radius.circular(radius))),
          )
        ],
      ),
    );
  }
}
