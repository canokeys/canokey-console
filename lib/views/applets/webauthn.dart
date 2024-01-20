import 'package:canokey_console/controller/applets/webauthn.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/my_shadow.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/my_button.dart';
import 'package:canokey_console/helper/widgets/my_card.dart';
import 'package:canokey_console/helper/widgets/my_container.dart';
import 'package:canokey_console/helper/widgets/my_spacing.dart';
import 'package:canokey_console/helper/widgets/my_text.dart';
import 'package:canokey_console/helper/widgets/my_validators.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/models/webauthn.dart';
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
                child: Icon(LucideIcons.refreshCw, size: 20, color: topBarTheme.onBackground),
              )
            ];
            if (controller.polled) {
              widgets.insertAll(0, [
                InkWell(
                  onTap: () {
                    Prompts.showInputPinDialog(
                      title: S.of(context).changePin,
                      label: 'PIN',
                      prompt: S.of(context).changePinPrompt(4, 63),
                      validators: [MyLengthValidator(min: 4, max: 63)],
                    ).then((value) => controller.changePin(value)).onError((error, stackTrace) => null); // Canceled
                  },
                  child: Icon(LucideIcons.lock, size: 20, color: topBarTheme.onBackground),
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
          if (controller.webAuthnItems.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MySpacing.height(MediaQuery.of(context).size.height / 2 - 100),
                Center(child: MyText.bodyMedium(S.of(context).noCredential, fontSize: 24)),
              ],
            );
          }
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
                      physics: ScrollPhysics(),
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      itemCount: controller.webAuthnItems.length,
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 500, crossAxisSpacing: 16, mainAxisSpacing: 16, mainAxisExtent: 120),
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
    WebAuthnItem item = controller.webAuthnItems[index];
    return MyCard(
      shadow: MyShadow(elevation: 0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText.bodyMedium(item.userDisplayName, fontSize: 16, fontWeight: 600),
              MyContainer.none(
                paddingAll: 8,
                borderRadiusAll: 5,
                child: PopupMenuButton(
                  offset: const Offset(0, 10),
                  position: PopupMenuPosition.under,
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      padding: MySpacing.xy(16, 8),
                      height: 10,
                      child: MyText.bodySmall(S.of(context).delete),
                      onTap: () => _showDeleteDialog(item),
                    ),
                  ],
                  child: const Icon(LucideIcons.moreHorizontal, size: 18),
                ),
              ),
            ],
          ),
          Row(
            children: [
              MyContainer.rounded(
                color: contentTheme.primary.withAlpha(30),
                paddingAll: 2,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: Icon(LucideIcons.user, size: 16, color: contentTheme.primary),
              ),
              MySpacing.width(12),
              MyText.bodyMedium(item.userName),
            ],
          ),
          Row(
            children: [
              MyContainer.rounded(
                color: contentTheme.primary.withAlpha(30),
                paddingAll: 2,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: Icon(LucideIcons.globe, size: 16, color: contentTheme.primary),
              ),
              MySpacing.width(12),
              MyText.bodyMedium(item.rpId),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(WebAuthnItem item) {
    Get.dialog(Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: MySpacing.all(16),
              child: MyText.labelLarge(S.of(context).delete),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: MySpacing.all(16),
              child: MyText.labelLarge(S.of(context).webauthnDelete('${item.userDisplayName} (${item.userName})')),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: MySpacing.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MyButton.rounded(
                    onPressed: () => Navigator.pop(context),
                    elevation: 0,
                    padding: MySpacing.xy(20, 16),
                    backgroundColor: contentTheme.secondary,
                    child: MyText.labelMedium(S.of(context).cancel, color: contentTheme.onSecondary),
                  ),
                  MySpacing.width(16),
                  MyButton.rounded(
                    onPressed: () => controller.delete(item.credentialId),
                    elevation: 0,
                    padding: MySpacing.xy(20, 16),
                    backgroundColor: contentTheme.danger,
                    child: MyText.labelMedium(S.of(context).delete, color: contentTheme.onDanger),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
