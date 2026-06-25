import 'package:flutter/material.dart';
import '../theme/kali_theme.dart';

class KaliUI {
  /// Muestra un SnackBar global utilizando la configuración de estilo estándar de la app.
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: KaliText.body(KaliColors.clay),
        ),
        backgroundColor: KaliColors.espresso,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Muestra un BottomSheet con los parámetros estándar requeridos (transparente, scrollControlled).
  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required Widget builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => builder,
    );
  }
}
