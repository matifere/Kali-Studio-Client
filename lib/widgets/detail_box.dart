import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/google_fonts_helper.dart';

class DetailBox extends StatelessWidget {
  final String label;
  final String value;

  const DetailBox({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KaliColors.sand2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: KaliText.label(KaliColors.clayDark)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFontsHelper.cormorant(KaliColors.espresso, 20)),
        ],
      ),
    );
  }
}
