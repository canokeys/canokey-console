enum ScreenMediaType {
  xs(576, "xs"), //Mobile
  sm(768, "sm"), //Tablet
  md(1200, "md"), //Laptop
  lg(1400, "lg"), //Desktop
  xl(1800, "xl"), //Large Desktop
  xxl(4000, "xxl"); //Extra Large Desktop

  bool get isMobile => this == ScreenMediaType.xs;

  bool get isTablet => this == ScreenMediaType.sm;

  bool get isLaptop => this == ScreenMediaType.md;

  bool get isMiniDesktop => this == ScreenMediaType.lg;

  bool get isDesktop => this == ScreenMediaType.xl;

  static List<ScreenMediaType> list = [ScreenMediaType.xs, ScreenMediaType.sm, ScreenMediaType.md, ScreenMediaType.lg, ScreenMediaType.xl, ScreenMediaType.xxl];

  const ScreenMediaType(this.width, this.className);

  final double width;

  final String className;
}
