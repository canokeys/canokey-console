enum MyDisplayType {
  none("none"),
  block("block");

  const MyDisplayType(this.className);

  bool get isBlock => this == MyDisplayType.block;

  final String className;

  static MyDisplayType fromString(String text) {
    return text == MyDisplayType.none.className
        ? MyDisplayType.none
        : MyDisplayType.block;
  }
}
