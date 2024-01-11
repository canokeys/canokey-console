import 'package:canokey_console/controller/starter_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/my_spacing.dart';
import 'package:canokey_console/helper/widgets/my_text.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
                  MySpacing.height(MediaQuery.of(context).size.height / 2 - 100),
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
                  ),
                ],
              );
            }));
  }
}
