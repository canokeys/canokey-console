import 'package:canokey_console/controller/applets/webauthn/webauthn_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/no_credential_screen.dart';
import 'package:canokey_console/helper/widgets/poll_canokey_screen.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/helper/widgets/search_box.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/views/applets/webauthn/widgets/top_actions.dart';
import 'package:canokey_console/views/applets/webauthn/widgets/webauthn_item_card.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';

final log = Logger('Console:WebAuthn:View');

class WebAuthnPage extends StatefulWidget {
  const WebAuthnPage({super.key});

  @override
  State<WebAuthnPage> createState() => _WebAuthnPageState();
}

class _WebAuthnPageState extends State<WebAuthnPage> with SingleTickerProviderStateMixin, UIMixin {
  final controller = Get.put(WebAuthnController());
  final searchText = ''.obs;

  @override
  void initState() {
    super.initState();
    Get.put(searchText, tag: 'webauthn_search');
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      title: "WebAuthn",
      topActions: TopActions(controller: controller),
      child: GetBuilder(
        init: controller,
        builder: (_) {
          if (!controller.polled) {
            return PollCanoKeyScreen();
          }
          if (controller.webAuthnItems.isEmpty) {
            return NoCredentialScreen();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.x(flexSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ScreenMedia.getTypeFromWidth(MediaQuery.of(context).size.width).isMobile) ...{
                      Spacing.height(16),
                      SearchBox(),
                    },
                    Spacing.height(16),
                    Obx(() {
                      final filteredItems = searchText.value.isEmpty
                          ? controller.webAuthnItems
                          : controller.webAuthnItems
                              .where((item) =>
                                  item.rpId.toLowerCase().contains(searchText.value.toLowerCase()) ||
                                  item.userDisplayName.toLowerCase().contains(searchText.value.toLowerCase()))
                              .toList();
                      if (filteredItems.isEmpty) return Center(child: CustomizedText.bodyMedium(S.of(context).noMatchingCredential, fontSize: 24));
                      return GridView.builder(
                        physics: ScrollPhysics(),
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        itemCount: filteredItems.length,
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 500,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 120,
                        ),
                        itemBuilder: (context, index) => WebAuthnItemCard(
                          item: filteredItems[index],
                          controller: controller,
                        ),
                      );
                    })
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
