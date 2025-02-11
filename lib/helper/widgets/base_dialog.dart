import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';

abstract class BaseDialog extends StatefulWidget {
  const BaseDialog({super.key});
}

abstract class BaseDialogState<T extends BaseDialog> extends State<T> {
  final RxBool _showPolling = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString errorLevel = 'E'.obs;

  @override
  void initState() {
    super.initState();
    Get.put(_showPolling, tag: 'dialog_polling');
    Get.put(errorMessage, tag: 'dialog_error');
    Get.put(errorLevel, tag: 'dialog_error_level');
    SmartCard.nfcState = NfcState.input; // prevent refreshing
  }

  @override
  void dispose() {
    Get.delete<RxBool>(tag: 'dialog_polling');
    Get.delete<RxString>(tag: 'dialog_error');
    Get.delete<RxString>(tag: 'dialog_error_color');
    SmartCard.nfcState = NfcState.idle; // allow refreshing
    super.dispose();
  }

  Widget buildDialogContent();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 400,
        child: Stack(
          children: [
            buildDialogContent(),
            Positioned.fill(
              child: Obx(
                () => !_showPolling.value
                    ? Container()
                    : GestureDetector(
                        onTap: () {},
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.2),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SpinKitRipple(color: Colors.tealAccent, size: 64.0),
                                Spacing.height(16),
                                CustomizedText.bodyLarge(S.of(Get.context!).readingAlertMessage, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
