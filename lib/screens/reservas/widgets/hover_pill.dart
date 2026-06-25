import 'package:flutter/material.dart';
import '../../../../theme/kali_theme.dart';
import '../../../../widgets/motion.dart';

class HoverPill extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  const HoverPill({
    super.key,
    required this.label,
    this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  State<HoverPill> createState() => _HoverPillState();
}

class _HoverPillState extends State<HoverPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Pressable(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          opacity: _hovered ? 0.72 : 1.0,
          duration: const Duration(milliseconds: 130),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: widget.background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 12, color: widget.foreground),
                  const SizedBox(width: 5),
                ],
                Text(
                  widget.label,
                  style: KaliText.label(widget.foreground)
                      .copyWith(fontSize: 10, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
