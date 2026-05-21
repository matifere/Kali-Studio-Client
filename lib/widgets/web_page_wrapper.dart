import 'package:flutter/widgets.dart';
import '../utils/responsive.dart';

/// Centra el contenido horizontalmente con un max-width en desktop.
/// En mobile no hace nada — el contenido ocupa todo el ancho.
class WebPageWrapper extends StatelessWidget {
  final Widget child;

  const WebPageWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!Responsive.isDesktop(context)) return child;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
        child: child,
      ),
    );
  }
}
