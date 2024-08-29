import 'package:canokey_console/controller/applets/webauthn.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/shadow.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_card.dart';
import 'package:canokey_console/helper/widgets/customized_container.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/helper/widgets/responsive.dart';
import 'package:canokey_console/models/webauthn.dart';
import 'package:canokey_console/views/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:lucide_icons/lucide_icons.dart';

final log = Logger('Console:WebAuthn:View');

class WebAuthnPage extends StatefulWidget {
  const WebAuthnPage({super.key});

  @override
  State<WebAuthnPage> createState() => _WebAuthnPageState();
}

class _WebAuthnPageState extends State<WebAuthnPage>
    with SingleTickerProviderStateMixin, UIMixin {
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
                child: Icon(LucideIcons.refreshCw,
                    size: 20, color: topBarTheme.onBackground),
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
                      validators: [LengthValidator(min: 4, max: 63)],
                    )
                        .then((value) => controller.changePin(value))
                        .onError((error, stackTrace) => null); // Canceled
                  },
                  child: Icon(LucideIcons.lock,
                      size: 20, color: topBarTheme.onBackground),
                ),
                Spacing.width(12),
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
                Spacing.height(MediaQuery.of(context).size.height / 2 - 120),
                Center(
                    child: Padding(
                  padding: Spacing.horizontal(36),
                  child: CustomizedText.bodyMedium(S.of(context).pollCanoKey,
                      fontSize: 24),
                )),
              ],
            );
          }
          if (controller.webAuthnItems.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Spacing.height(MediaQuery.of(context).size.height / 2 - 100),
                Center(
                    child: CustomizedText.bodyMedium(S.of(context).noCredential,
                        fontSize: 24)),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.x(flexSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Spacing.height(20),
                    GridView.builder(
                      physics: ScrollPhysics(),
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      itemCount: controller.webAuthnItems.length,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 500,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 120),
                      itemBuilder: (context, index) =>
                          buildWebAuthnItem(controller, index),
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
    return CustomizedCard(
      shadow: Shadow(elevation: 0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomizedText.bodyMedium(item.userDisplayName,
                  fontSize: 16, fontWeight: 600),
              CustomizedContainer.none(
                paddingAll: 8,
                borderRadiusAll: 5,
                child: PopupMenuButton(
                  offset: const Offset(0, 10),
                  position: PopupMenuPosition.under,
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      padding: Spacing.xy(16, 8),
                      height: 10,
                      child: CustomizedText.bodySmall(S.of(context).delete),
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
              CustomizedContainer.rounded(
                color: contentTheme.primary.withAlpha(30),
                paddingAll: 2,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: Icon(LucideIcons.user,
                    size: 16, color: contentTheme.primary),
              ),
              Spacing.width(12),
              CustomizedText.bodyMedium(item.userName),
            ],
          ),
          Row(
            children: [
              CustomizedContainer.rounded(
                color: contentTheme.primary.withAlpha(30),
                paddingAll: 2,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: Icon(LucideIcons.globe,
                    size: 16, color: contentTheme.primary),
              ),
              Spacing.width(12),
              CustomizedText.bodyMedium(item.rpId),
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
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.of(context).delete),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.of(context).webauthnDelete(
                  '${item.userDisplayName} (${item.userName})')),
            ),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomizedButton.rounded(
                    onPressed: () => Navigator.pop(context),
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.secondary,
                    child: CustomizedText.labelMedium(S.of(context).cancel,
                        color: contentTheme.onSecondary),
                  ),
                  Spacing.width(16),
                  CustomizedButton.rounded(
                    onPressed: () => controller.delete(item.credentialId),
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.danger,
                    child: CustomizedText.labelMedium(S.of(context).delete,
                        color: contentTheme.onDanger),
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
