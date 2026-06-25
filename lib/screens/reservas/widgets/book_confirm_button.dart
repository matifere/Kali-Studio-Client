import 'package:flutter/material.dart';
import '../../../../theme/kali_theme.dart';
import '../../../../widgets/motion.dart';

class BookConfirmButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const BookConfirmButton({
    super.key,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled ? KaliColors.espresso : Colors.transparent;
    final fg = filled ? KaliColors.background : KaliColors.espresso;

    return Pressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: KaliColors.espresso),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: KaliText.label(fg)
              .copyWith(fontSize: 12, letterSpacing: 1.8),
        ),
      ),
    );
  }
}
