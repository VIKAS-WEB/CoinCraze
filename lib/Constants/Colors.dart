import 'package:flutter/material.dart';

class AppColors {
  static const Color black = Color(0xFF000000);
  static const Color charcoal = Color(0xFF1E1E1E);
  static const Color snowWhite = Color(0xFFF5F5F5);

  static const Color royalPurple = Color(0xFF9B59B6);
  static const Color electricCyan = Color(0xFF00FFFF);
  static const Color hotPink = Color(0xFFFF007F);
  static const Color deepOrange = Color(0xFFFF5722);
  static const Color slateBlue = Color(0xFF6A5ACD);

  static const Gradient fancyGradient = LinearGradient(
    colors: [royalPurple, electricCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

