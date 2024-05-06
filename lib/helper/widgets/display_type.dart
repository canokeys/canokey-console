enum DisplayType {
  none("none"),
  block("block");

  const DisplayType(this.className);

  bool get isBlock => this == DisplayType.block;

  final String className;

  static DisplayType fromString(String text) {
    return text == DisplayType.none.className ? DisplayType.none : DisplayType.block;
  }
}
