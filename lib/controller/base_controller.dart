import 'package:get/get.dart';
import 'package:canokey_console/helper/theme/theme_customizer.dart';

abstract class Controller extends GetxController {
  @override
  void onInit() {
    super.onInit();
    ThemeCustomizer.addListener((old, newVal) {
      if (old.theme != newVal.theme) {
        update();
      }
    });
  }
}
