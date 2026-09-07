import 'dart:js_interop';

export 'package:flutter_nfc_kit/webusb_interop.dart' show WebUSB;

@JS('navigator.usb')
external _USB? get _usb;

extension type _USB(JSObject _) implements JSObject {
  external JSAny? get requestDevice;
  external JSPromise<JSArray<JSObject>> getDevices();
}

Future<bool> isWebUsbAvailable() async {
  try {
    final usb = _usb;
    if (usb == null || !usb.requestDevice.typeofEquals('function')) {
      return false;
    }
    // This checks policy restrictions without prompting or requiring a device.
    await usb.getDevices().toDart;
    return true;
  } catch (_) {
    return false;
  }
}
