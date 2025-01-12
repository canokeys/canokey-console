import 'package:canokey_console/helper/localization/hints.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';

class PollCanoKeyScreen extends StatelessWidget {
  const PollCanoKeyScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Spacing.height(MediaQuery.of(context).size.height / 2 - 120),
        Center(
          child: Padding(
            padding: Spacing.horizontal(36),
            child: CustomizedText.bodyMedium(Hints.pollCanoKeyPrompt, fontSize: 24),
          ),
        ),
      ],
    );
  }
}
