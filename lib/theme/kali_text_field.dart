import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';

class KaliTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData suffixIcon;
  final bool obscureText;
  final TextEditingController? controller;
  final VoidCallback? onSuffixTap;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const KaliTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.suffixIcon,
    this.obscureText = false,
    this.controller,
    this.onSuffixTap,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = KaliColors.espresso;
    final actionColor = KaliColors.clayDark;
    final textColor = KaliColors.espresso;
    final hintColor = KaliColors.clay;
    final fillColor = KaliColors.sand;
    final borderColor = KaliColors.sand2;
    final focusedBorderColor = KaliColors.clay;
    final iconColor = KaliColors.clayDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Fila de etiqueta + acción opcional ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: KaliText.label(labelColor),
            ),
            if (actionLabel != null)
              GestureDetector(
                onTap: onActionTap,
                child: Text(
                  actionLabel!,
                  style: KaliText.caption(actionColor),
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // ── Campo de texto ──
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: KaliText.body(textColor, size: 14),
          cursorColor: focusedBorderColor,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: KaliText.body(hintColor, size: 14),

            // Fondo del campo
            filled: true,
            fillColor: fillColor,

            // Icono derecho
            suffixIcon: GestureDetector(
              onTap: onSuffixTap,
              child: Icon(
                suffixIcon,
                color: iconColor,
                size: 18,
              ),
            ),

            // Bordes
            border: _border(borderColor),
            enabledBorder: _border(borderColor),
            focusedBorder: _border(focusedBorderColor),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: 1.2),
      );
}
