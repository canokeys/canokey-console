typedef MyFieldValidator<T> = String? Function(T? value);

abstract class FieldValidatorRule<T> {
  String? validate(T? value, bool required, Map<String, dynamic> data);
}
