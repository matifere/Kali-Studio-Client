import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsets padding;

  const SectionLabel(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text.toUpperCase(),
        style: KaliText.label(KaliColors.clayDark),
      ),
    );
  }
}
