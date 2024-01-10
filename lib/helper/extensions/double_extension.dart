extension DoubleExtension on double? {
  String get precise {
    if (this != null) {
      return this!.toStringAsFixed(this!.truncateToDouble() == this ? 0 : 1);
    }
    return '';
  }
}
