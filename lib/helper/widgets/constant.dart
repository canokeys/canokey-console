class WidgetConstantData {
  final double containerRadius;
  final double cardRadius;
  final double buttonRadius;

  WidgetConstantData({this.containerRadius = 4, this.cardRadius = 4, this.buttonRadius = 4});
}

class WidgetConstant {
  static WidgetConstantData _constant = WidgetConstantData();

  static WidgetConstantData get constant => _constant;

  static void setConstant(WidgetConstantData constantData) {
    _constant = constantData;
  }
}
