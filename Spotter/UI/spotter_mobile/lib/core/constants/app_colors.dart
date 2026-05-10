import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF7C3AED);
  static const Color secondary = Color(0xFF5B21B6);
  static const Color accent = Color(0xFFEA580C);
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);

  static const Map<String, Color> categoryColors = {
    '#7C3AED': Color(0xFF7C3AED),
    '#EA580C': Color(0xFFEA580C),
    '#0EA5E9': Color(0xFF0EA5E9),
    '#16A34A': Color(0xFF16A34A),
    '#CA8A04': Color(0xFFCA8A04),
    '#DB2777': Color(0xFFDB2777),
  };

  static Color fromHex(String? hex) {
  if (hex == null || hex.isEmpty) return AppColors.primary;
  try {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    return AppColors.primary;
  }
}
}
