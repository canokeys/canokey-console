enum ScreenMediaType {
  xs(576), //Mobile
  sm(768), //Tablet
  md(1200), //Laptop
  lg(1400), //Desktop
  xl(1800), //Large Desktop
  xxl(4000); //Extra Large Desktop

  bool get isMobile => this == ScreenMediaType.xs;

  const ScreenMediaType(this.width);

  final double width;
}
