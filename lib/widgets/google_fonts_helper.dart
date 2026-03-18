import 'package:flutter/material.dart';

class GoogleFontsHelper {
  static TextStyle cormorant(Color color, double size,
      {bool italic = false, FontWeight weight = FontWeight.w300}) {
    return TextStyle(
      fontFamily: 'Cormorant Garamond',
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    );
  }
}
