import 'package:canokey_console/helper/widgets/applet_section_card.dart';
import 'package:flutter/material.dart';

class SettingsRows extends StatelessWidget {
  const SettingsRows({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0)
          Divider(height: 1, thickness: 1, color: AppletStyle.border(context)),
        children[i],
      ],
    ],
  );
}
