import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/kali_theme.dart';

/// Renders avatar image content: selected bytes → data URL → network URL → initial letter.
///
/// Place this inside any container that provides the circular shape and border.
class KaliAvatarContent extends StatelessWidget {
  final String? avatarUrl;
  final Uint8List? selectedBytes;
  final String fallbackLetter;
  final double fallbackFontSize;

  const KaliAvatarContent({
    super.key,
    this.avatarUrl,
    this.selectedBytes,
    required this.fallbackLetter,
    this.fallbackFontSize = 34,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedBytes != null) {
      return ClipOval(child: Image.memory(selectedBytes!, fit: BoxFit.cover));
    }

    final url = avatarUrl;
    if (url != null && url.trim().isNotEmpty) {
      if (url.startsWith('data:image')) {
        final bytes = _decodeDataUrl(url);
        if (bytes != null) {
          return ClipOval(
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            ),
          );
        }
      }
      return ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Center(
      child: Text(
        fallbackLetter,
        style: KaliText.loginDisplay(KaliColors.espresso).copyWith(
          fontSize: fallbackFontSize,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  static Uint8List? _decodeDataUrl(String value) {
    try {
      final commaIndex = value.indexOf(',');
      if (commaIndex == -1) return null;
      return base64Decode(value.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }
}
