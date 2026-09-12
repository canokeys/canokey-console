import 'package:canokey_console/helper/localization/hints.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';

class PollCanoKeyScreen extends StatelessWidget {
  const PollCanoKeyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = ScreenMedia.getTypeFromWidth(
      MediaQuery.sizeOf(context).width,
    ).isMobile;
    return LayoutBuilder(
      builder: (context, constraints) {
        final prompt = Align(
          alignment: mobile ? const Alignment(0, -0.25) : Alignment.center,
          child: Padding(
            padding: Spacing.horizontal(36),
            child: CustomizedText.bodyMedium(
              Hints.pollCanoKeyPrompt,
              fontSize: 24,
              textAlign: TextAlign.center,
            ),
          ),
        );
        if (constraints.minHeight > 0) {
          return prompt;
        }
        if (mobile) {
          final mediaQuery = MediaQuery.of(context);
          return SizedBox(
            height:
                mediaQuery.size.height -
                mediaQuery.viewPadding.vertical -
                kToolbarHeight,
            child: prompt,
          );
        }
        return Column(
          children: [
            Spacing.height(MediaQuery.sizeOf(context).height / 2 - 120),
            prompt,
          ],
        );
      },
    );
  }
}
