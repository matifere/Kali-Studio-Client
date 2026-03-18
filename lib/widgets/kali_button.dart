import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';

class KaliButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool outlined;

  const KaliButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : KaliColors.espresso,
          border: Border.all(
            color: outlined ? KaliColors.espresso : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text.toUpperCase(),
          textAlign: TextAlign.center,
          style: KaliText.label(
            outlined ? KaliColors.espresso : KaliColors.clay,
          ).copyWith(fontSize: 12, letterSpacing: 1.8),
        ),
      ),
    );
  }
}
