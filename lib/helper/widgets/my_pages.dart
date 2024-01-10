import 'package:flutter/material.dart';

class MySinglePage extends StatelessWidget {
  final PageViewModel? viewModel;
  final double? percentVisible;

  MySinglePage({
    this.viewModel,
    this.percentVisible = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        color: viewModel!.color,
        child: Opacity(
          opacity: percentVisible!,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Transform(
                transform: Matrix4.translationValues(
                    0.0, 50.0 * (1.0 - percentVisible!), 0.0),
                child: viewModel!.content),
          ]),
        ));
  }
}

class PageViewModel {
  final Color color;
  final Widget content;

  PageViewModel(
    this.color,
    this.content,
  );
}
