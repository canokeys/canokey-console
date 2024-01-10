import 'package:flutter/material.dart';

class MyStarRating extends StatelessWidget {
  final double rating, size, spacing;
  final Color activeColor, inactiveColor;
  final bool inactiveStarFilled, showInactive;
  final IconData? activeIcon, halfIcon, inactiveIcon;

  MyStarRating(
      {this.rating = 5,
      this.size = 16,
      this.spacing = 0,
      this.activeColor = Colors.yellow,
      this.inactiveColor = Colors.black,
      this.inactiveStarFilled = false,
      this.showInactive = true,
      this.activeIcon,
      this.halfIcon,
      this.inactiveIcon});

  @override
  Widget build(BuildContext context) {
    int ratingCount = rating.floor();

    bool isHalf = (ratingCount != rating);
    List<Widget> stars = [];
    for (int i = 0; i < 5; i++) {
      if (i < ratingCount) {
        stars.add(Icon(
          activeIcon ?? Icons.star,
          color: activeColor,
          size: size,
        ));

        stars.add(SizedBox(width: spacing));
      } else {
        if (isHalf) {
          isHalf = false;
          stars.add(Icon(
            halfIcon ?? Icons.star_half_outlined,
            color: activeColor,
            size: size,
          ));
        } else if (showInactive) {
          stars.add(Icon(
            inactiveStarFilled
                ? (activeIcon ?? Icons.star)
                : (inactiveIcon ?? Icons.star_outline),
            color: inactiveColor,
            size: size,
          ));
        }
        stars.add(SizedBox(width: spacing));
      }
    }
    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }
}
