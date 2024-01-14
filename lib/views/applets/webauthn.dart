import 'package:canokey_console/controller/applets/webauthn.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/my_spacing.dart';
import 'package:canokey_console/helper/widgets/my_text.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:lucide_icons/lucide_icons.dart';

final log = Logger('Console:WebAuthn:View');

class WebAuthnPage extends StatefulWidget {
  const WebAuthnPage({Key? key}) : super(key: key);

  @override
  State<WebAuthnPage> createState() => _WebAuthnPageState();
}

class _WebAuthnPageState extends State<WebAuthnPage> with SingleTickerProviderStateMixin, UIMixin {
  late WebAuthnController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(WebAuthnController());
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      title: "WebAuthn",
      topActions: GetBuilder(
          init: controller,
          builder: (_) {
            List<Widget> widgets = [
              InkWell(
                onTap: controller.refreshData,
                child: Icon(LucideIcons.refreshCw, size: 18, color: topBarTheme.onBackground),
              )
            ];
            if (controller.polled) {
              widgets.insertAll(0, [
                InkWell(
                  onTap: () {},
                  child: Icon(LucideIcons.lock, size: 18, color: topBarTheme.onBackground),
                ),
                MySpacing.width(12),
              ]);
            }
            return Row(children: widgets);
          }),
      child: GetBuilder(
        init: controller,
        builder: (_) {
          if (!controller.polled) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MySpacing.height(MediaQuery.of(context).size.height / 2 - 120),
                Center(
                    child: Padding(
                  padding: MySpacing.horizontal(36),
                  child: MyText.bodyMedium(S.of(context).pollCanoKey, fontSize: 24),
                )),
              ],
            );
          }
          // TODO: no credentials
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MySpacing.height(20),
                    GridView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      itemCount: 0,
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 500, crossAxisSpacing: 16, mainAxisSpacing: 16, mainAxisExtent: 150),
                      itemBuilder: (context, index) => buildWebAuthnItem(controller, index),
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildWebAuthnItem(WebAuthnController controller, int index) {
    return Container();
  }
}
