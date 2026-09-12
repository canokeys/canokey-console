import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/utils/string_utils.dart';
import 'package:canokey_console/helper/widgets/field_validator.dart';
import 'package:get/get.dart';

class EmailValidator extends FieldValidatorRule<String> {
  @override
  String? validate(String? value, bool required, Map<String, dynamic> data) {
    if (!required) {
      if (value == null) {
        return null;
      }
    } else if (value != null && value.isNotEmpty) {
      if (!StringUtils.isEmail(value)) {
        return S.current.ndefInvalidEmail;
      }
    }
    return null;
  }
}

class IntValidator extends FieldValidatorRule<String> {
  final bool required;
  final int? min, max;

  IntValidator({this.required = true, this.min, this.max});

  @override
  String? validate(String? value, bool required, Map<String, dynamic> data) {
    if (value != null) {
      if (!required && value.isEmpty) {
        return null;
      }
      int? v = int.tryParse(value);
      if (v == null) {
        return S.current.validationNumber;
      }
      if (min != null && v < min!) {
        return S.current.validationNumberMin(min!);
      }
      if (max != null && v > max!) {
        return S.current.validationNumberMax(max!);
      }
    }
    return null;
  }
}

class LengthValidator implements FieldValidatorRule<String> {
  final bool required;
  final int? min, max, exact;

  LengthValidator({this.required = true, this.exact, this.min, this.max});

  @override
  String? validate(String? value, bool required, Map<String, dynamic> data) {
    if (value != null) {
      if (!required && value.isEmpty) {
        return null;
      }
      if (exact != null && value.length != exact!) {
        return S.of(Get.context!).validationExactLength(exact!);
      }
      if (min != null && value.length < min!) {
        return S.current.validationAtLeastCharacters(min!);
      }
      if (max != null && value.length > max!) {
        return S.current.validationAtMostCharacters(max!);
      }
    }
    return null;
  }
}

class HexStringValidator implements FieldValidatorRule<String> {
  final bool required;

  HexStringValidator({this.required = true});

  @override
  String? validate(String? value, bool required, Map<String, dynamic> data) {
    if (value != null) {
      if (!required && value.isEmpty) {
        return null;
      }
      if (!StringUtils.isHex(value)) {
        return S.of(Get.context!).validationHexString;
      }
    }
    return null;
  }
}
