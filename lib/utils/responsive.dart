import 'package:flutter/widgets.dart';

class Responsive {
  static const double _breakpoint = 800;
  static const double sidebarWidth = 230.0;
  static const double maxContentWidth = 1100.0;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _breakpoint;
}
