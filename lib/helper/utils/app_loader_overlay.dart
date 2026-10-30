import 'package:get/get.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:canokey_console/helper/utils/app_platform.dart';

class AppLoaderOverlay {
  static bool _visible = false;
  static void show() {
    if (!isIOSApp() && !AppDialogSurface.hasActiveDialog) {
      _visible = true;
      Get.context!.loaderOverlay.show();
    }
  }

  static void hide() {
    if (_visible) {
      _visible = false;
      Get.context!.loaderOverlay.hide();
    }
  }
}
