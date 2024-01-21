import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/my_field_validator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyFormValidator {
  Map<String, dynamic> errors = {};
  Map<String, dynamic> remainingError = {};
  GlobalKey<FormState> formKey = GlobalKey();
  bool consumeError = true;

  final Map<String, dynamic> _validators = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _data = {};

  void addField<T>(String name,
      {bool required = false,
      List<MyFieldValidatorRule<T>> validators = const [],
      String? label,
      TextEditingController? controller}) {
    _validators[name] = _createValidation<T>(name,
        required: required, validators: validators, label: label);
    if (controller != null) _controllers[name] = controller;
  }

  MyFieldValidator<T>? getValidator<T>(String name) => _validators[name] != null
      ? _validators[name] as MyFieldValidator<T>
      : null;

  TextEditingController? getController(String name) => _controllers[name];

  MyFieldValidator<T> _createValidation<T>(String name,
      {bool required = false,
      List<MyFieldValidatorRule<T>> validators = const [],
      String? label}) {
    return (T? value) {
      label ??= name.capitalize;
      String? error = getError(name);
      if (error != null) {
        return error;
      }

      if (required && (value == null || (value.toString().isEmpty))) {
        return S.of(Get.context!).oathRequired;
      }
      for (MyFieldValidatorRule validator in validators) {
        String? validationError =
            validator.validate(value, required, getData());
        if (validationError != null) {
          return validationError;
        }
      }
      return null;
    };
  }

  String? getError(String name) {
    if (errors.containsKey(name)) {
      dynamic error = errors[name];

      if (error is List && error.isNotEmpty) {
        String errorText = error[0].toString();
        if (consumeError) {
          remainingError.remove(name);
        }
        return errorText;
      } else {
        String errorText = error.toString();
        if (consumeError) {
          remainingError.remove(name);
        }
        return errorText;
      }
    }
    return null;
  }

  bool validateForm({bool clear = false, bool consumeError = true}) {
    if (clear) {
      errors.clear();
      remainingError.clear();
    }
    this.consumeError = consumeError;

    return formKey.currentState?.validate() ?? false;
  }

  ValueChanged<T> onChanged<T>(String key) {
    return (T value) {
      _data[key] = value;
    };
  }

  Map<String, dynamic> getData() {
    var map = {
      ..._data,
    };
    for (var key in _controllers.keys) {
      if (_controllers[key]?.text != null) {
        map[key] = _controllers[key]!.text;
      }
    }

    return map;
  }

  void resetForm() {
    formKey.currentState?.reset();
  }

  void clearErrors() {
    errors.clear();
  }

  void addError(String key, dynamic error) {
    errors[key] = error;
  }

  void addErrors(Map<String, dynamic> errors) {
    errors.forEach((key, value) {
      this.errors[key] = value;
    });
  }
}
