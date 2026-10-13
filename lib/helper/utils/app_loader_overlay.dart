import 'package:get/get.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:canokey_console/helper/utils/app_platform.dart';

class AppLoaderOverlay {
  static void show() {
    if (!isIOSApp()) {
      Get.context!.loaderOverlay.show();
    }
  }

  static void hide() {
    if (!isIOSApp()) {
      Get.context!.loaderOverlay.hide();
    }
  }
}
