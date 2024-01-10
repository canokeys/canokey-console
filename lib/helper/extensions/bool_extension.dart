extension BoolExtension on bool? {
  bool? toggle() {
    return this != null ? !this! : false;
  }
}
