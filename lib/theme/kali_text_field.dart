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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Fila de etiqueta + acción opcional ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: KaliText.label(KaliColors.espresso),
            ),
            if (actionLabel != null)
              GestureDetector(
                onTap: onActionTap,
                child: Text(
                  actionLabel!,
                  style: KaliText.caption(KaliColors.clayDark),
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // ── Campo de texto ──
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: KaliText.body(KaliColors.espresso, size: 14),
          cursorColor: KaliColors.clay,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: KaliText.body(KaliColors.clay, size: 14),

            // Fondo del campo
            filled: true,
            fillColor: KaliColors.sand,

            // Icono derecho
            suffixIcon: GestureDetector(
              onTap: onSuffixTap,
              child: Icon(
                suffixIcon,
                color: KaliColors.clayDark,
                size: 18,
              ),
            ),

            // Bordes
            border: _border(KaliColors.sand2),
            enabledBorder: _border(KaliColors.sand2),
            focusedBorder: _border(KaliColors.clay),

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
