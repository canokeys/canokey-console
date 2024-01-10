import 'package:flutter/material.dart';
import 'package:get/get.dart';

mixin MyNavigationMixin on GetxController {
  Future<T?>? push<T>(Widget widget) {
    return Get.to(widget);
    // Navigator.push(context, MaterialPageRoute(builder: (context) => widget));
  }

  void pop<T>([T? result]) {
    return Get.back(result: result);
    // return Navigator.pop(context, result);
  }

  Future<T?>? pushReplacement<T>(Widget widget) {
    return Get.off(widget);
    // return Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => widget));
  }

  Future<T?>? pushAndPopAll<T>(Widget widget) {
    // Navigator.popUntil(context, (route) => route.isFirst);
    Get.offUntil(Get.context as Route, (route) => route.isFirst);
    return Get.off<T>(widget);
    // return pushReplacement<T>(widget);
  }

  void goBack<T>([T? result]) {
    return Navigator.pop<T>(Get.context as BuildContext, result);
  }
}
