import 'dart:async';

import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/theme/app_theme.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/widgets/my_button.dart';
import 'package:canokey_console/helper/widgets/my_field_validator.dart';
import 'package:canokey_console/helper/widgets/my_form_validator.dart';
import 'package:canokey_console/helper/widgets/my_spacing.dart';
import 'package:canokey_console/helper/widgets/my_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:platform_detector/platform_detector.dart';

class Prompts {
  static late SnackbarController _snackbarController;

  static void promptPinFailureResult(String resp) {
    if (resp == '6983') {
      showPrompt(S.of(Get.context!).appletLocked, ContentThemeColor.danger);
    } else if (resp == '6982') {
      showPrompt(S.of(Get.context!).pinIncorrect, ContentThemeColor.danger);
    } else if (resp.toUpperCase().startsWith('63C')) {
      String retries = resp[resp.length - 1];
      showPrompt(S.of(Get.context!).pinRetries(retries), ContentThemeColor.danger);
    } else if (resp == '6700') {
      showPrompt(S.of(Get.context!).pinLength, ContentThemeColor.danger);
    } else {
      showPrompt('Unknown response', ContentThemeColor.danger);
    }
  }

  static void showPrompt(String content, ContentThemeColor selectedColor) {
    Color backgroundColor = selectedColor.color;
    Color color = selectedColor.onColor;

    if (isIOS()) {
      MaterialBanner banner = MaterialBanner(
        content: MyText.labelMedium(content, color: color),
        padding: MySpacing.x(24),
        backgroundColor: backgroundColor,
        overflowAlignment: OverflowBarAlignment.center,
        actions: [MySpacing.empty()],
      );
      ScaffoldMessenger.of(Get.context!).hideCurrentMaterialBanner();
      ScaffoldMessenger.of(Get.context!).showMaterialBanner(banner);
      Timer(Duration(seconds: 3), () {
        ScaffoldMessenger.of(Get.context!).hideCurrentMaterialBanner();
      });
    } else {
      SnackBar snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 300,
        duration: Duration(seconds: 3),
        showCloseIcon: true,
        closeIconColor: color,
        content: MyText.labelLarge(content, color: color),
        backgroundColor: backgroundColor,
      );
      ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
      ScaffoldMessenger.of(Get.context!).showSnackBar(snackBar);
    }
  }

  static Future<String> showInputPinDialog({
    required String title,
    required String label,
    required String prompt,
    bool required = true,
    List<MyFieldValidatorRule> validators = const [],
  }) {
    RxBool showPassword = false.obs;
    Completer<String> c = new Completer<String>();
    MyFormValidator validator = MyFormValidator();
    validator.addField('pin', required: required, controller: TextEditingController(), validators: validators);

    onSubmit() {
      if (validator.validateForm()) {
        c.complete(validator.getController('pin')!.text);
        Navigator.pop(Get.context!);
      }
    }

    Get.dialog(
        Dialog(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: MySpacing.all(16),
                  child: MyText.labelLarge(title),
                ),
                Divider(height: 0, thickness: 1),
                Padding(
                    padding: MySpacing.all(16),
                    child: Form(
                        key: validator.formKey,
                        child: Column(
                          children: [
                            MyText.bodyMedium(prompt),
                            MySpacing.height(16),
                            Obx(() => TextFormField(
                                  autofocus: true,
                                  onFieldSubmitted: (_) => onSubmit(),
                                  onTap: () => SmartCard.eject(),
                                  obscureText: !showPassword.value,
                                  controller: validator.getController('pin'),
                                  validator: validator.getValidator('pin'),
                                  decoration: InputDecoration(
                                    labelText: label,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(4)),
                                      borderSide: BorderSide(width: 1, strokeAlign: 0, color: AppTheme.theme.colorScheme.onBackground.withAlpha(80)),
                                    ),
                                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                                    suffixIcon: IconButton(
                                      onPressed: () => showPassword.value = !showPassword.value,
                                      icon: Icon(showPassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                    ),
                                  ),
                                )),
                          ],
                        ))),
                Divider(height: 0, thickness: 1),
                Padding(
                  padding: MySpacing.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MyButton.rounded(
                        onPressed: () {
                          Navigator.pop(Get.context!);
                          c.completeError(UserCanceledError());
                        },
                        elevation: 0,
                        padding: MySpacing.xy(20, 16),
                        backgroundColor: ContentThemeColor.secondary.color,
                        child: MyText.labelMedium(S.of(Get.context!).cancel, color: ContentThemeColor.secondary.onColor),
                      ),
                      MySpacing.width(16),
                      MyButton.rounded(
                        onPressed: onSubmit,
                        elevation: 0,
                        padding: MySpacing.xy(20, 16),
                        backgroundColor: ContentThemeColor.primary.color,
                        child: MyText.labelMedium(S.of(Get.context!).confirm, color: ContentThemeColor.primary.onColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false);

    return c.future;
  }

  static promptPolling() {
    if (isAndroidApp()) {
      _snackbarController = Get.snackbar(
        S.of(Get.context!).androidAlertTitle,
        S.of(Get.context!).androidAlertMessage,
        icon: SpinKitHourGlass(color: Colors.tealAccent, size: 32.0),
        duration: const Duration(seconds: 99),
        backgroundColor: Colors.grey.withOpacity(0.8),
        snackPosition: SnackPosition.BOTTOM,
        maxWidth: 400,
      );
    }
  }

  static stopPromptPolling() {
    if (isAndroidApp()) {
      _snackbarController.close();
    }
  }
}

class UserCanceledError {}
