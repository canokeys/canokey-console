import 'dart:developer';

import 'package:canokey_console/helper/widgets/my_exception.dart';

class BaseException extends MyException {
  StackTrace? stackTrace;
  Object? error;
  BaseException? exception;

  void setException(BaseException exception) {
    this.exception = exception;
  }

  void setErrorTrace(Object error, StackTrace stackTrace) {
    this.error = error;
    this.stackTrace = stackTrace;
    printOnConsole();
  }

  void setError(Object error) {
    this.error = error;
  }

  void setStackTrace(StackTrace stackTrace) {
    this.stackTrace = stackTrace;
  }

  void printOnConsole() {
    // return;
    if (exception != null) {
      StringBuffer stringBuffer = StringBuffer();
      stringBuffer.write('----- ${exception.runtimeType} ------ \n');
      stringBuffer.write('message : $exception');
      log(
        stringBuffer.toString(),
        stackTrace: stackTrace,
        error: error,
      );
    }
  }

  @override
  String toString() {
    return "This is base exception";
  }
}
