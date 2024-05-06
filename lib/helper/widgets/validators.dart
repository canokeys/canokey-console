import 'package:canokey_console/helper/utils/string_utils.dart';
import 'package:canokey_console/helper/widgets/field_validator.dart';

class EmailValidator extends FieldValidatorRule<String> {
  @override
  String? validate(String? value, bool required, Map<String, dynamic> data) {
    if (!required) {
      if (value == null) {
        return null;
      }
    } else if (value != null && value.isNotEmpty) {
      if (!StringUtils.isEmail(value)) {
        return "Please enter valid email";
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
        return "Please enter valid number";
      }
      if (min != null && v < min!) {
        return "Number must be greater than $min";
      }
      if (max != null && v > max!) {
        return "Number must be lesser than $max";
      }
    }
    return null;
  }
}

class LengthValidator implements FieldValidatorRule<String> {
  final bool short, required;
  final int? min, max, exact;

  LengthValidator({this.required = true, this.exact, this.min, this.max, this.short = false});

  @override
  String? validate(String? value, bool required, Map<String, dynamic> data) {
    if (value != null) {
      if (!required && value.isEmpty) {
        return null;
      }
      if (exact != null && value.length != exact!) {
        return short ? "Need $exact characters" : "Need exact $exact characters";
      }
      if (min != null && value.length < min!) {
        return short ? "Need $min characters" : "Longer than $min characters";
      }
      if (max != null && value.length > max!) {
        return short ? "Only $max characters" : "Lesser than $max characters";
      }
    }
    return null;
  }
}
