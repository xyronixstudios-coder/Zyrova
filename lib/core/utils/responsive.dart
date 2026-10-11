import 'package:flutter/material.dart';

enum ScreenType { mobile, tablet, desktop }

class Responsive {
  static ScreenType of(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return ScreenType.mobile;
    if (width < 1024) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  static bool isMobile(BuildContext context) =>
      of(context) == ScreenType.mobile;
  static bool isTablet(BuildContext context) =>
      of(context) == ScreenType.tablet;
  static bool isDesktop(BuildContext context) =>
      of(context) == ScreenType.desktop;
}
