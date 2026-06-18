import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';

class KaliButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool outlined;

  const KaliButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  State<KaliButton> createState() => _KaliButtonState();
}

class _KaliButtonState extends State<KaliButton> {
  bool _hovered = false;
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final fillColor = widget.outlined ? Colors.transparent : KaliColors.espresso;
    final borderColor = widget.outlined ? KaliColors.espresso : Colors.transparent;
    final textColor = widget.outlined ? KaliColors.espresso : KaliColors.background;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) { if (enabled) setState(() => _hovered = true); },
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: !enabled
                ? 0.5
                : _hovered
                    ? 0.75
                    : 1.0,
            duration: const Duration(milliseconds: 130),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: fillColor,
                border: Border.all(color: borderColor, width: 1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.text.toUpperCase(),
                textAlign: TextAlign.center,
                style: KaliText.label(textColor)
                    .copyWith(fontSize: 12, letterSpacing: 1.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
