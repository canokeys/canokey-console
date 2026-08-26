import 'package:get/get.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:platform_detector/platform_detector.dart';

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
