import 'package:canokey_console/controller/starter_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:platform_detector/platform_detector.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class StarterScreen extends StatefulWidget {
  const StarterScreen({super.key});

  @override
  State<StarterScreen> createState() => _StarterScreenState();
}

class _StarterScreenState extends State<StarterScreen> with SingleTickerProviderStateMixin, UIMixin {
  late StarterController controller;

  @override
  void initState() {
    controller = Get.put(StarterController());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
        topActions: Container(),
        title: S.of(context).homeScreenTitle,
        child: GetBuilder<StarterController>(
            init: controller,
            builder: (_) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Spacing.height(MediaQuery.of(context).size.height / 2 - 100),
                  if (Layout.hasSidebar())
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(S.of(context).homePress, style: TextStyle(fontSize: 18.0)),
                        SizedBox(width: 5.0),
                        Icon(Icons.menu, color: Colors.black, size: 22.0),
                        SizedBox(width: 5.0),
                        Text(S.of(context).homeSelect, style: TextStyle(fontSize: 18.0)),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(S.of(context).homeDirectlySelect, style: TextStyle(fontSize: 18.0)),
                      ],
                    ),
                  if (isWeb()) ...[
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        launchUrl(Uri.parse('https://console-legacy.canokeys.org'));
                      },
                      child: Text(
                        'Use Legacy Version',
                        style: TextStyle(fontSize: 16.0, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ],
              );
            }));
  }
}
