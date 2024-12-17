import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';

class NoCredentialScreen extends StatelessWidget {
  const NoCredentialScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Spacing.height(MediaQuery.of(context).size.height / 2 - 100),
        Center(child: CustomizedText.bodyMedium(S.of(context).noCredential, fontSize: 24)),
      ],
    );
  }
}
