import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors (Restored to original Cricket Green theme)
  static const Color background = Color(0xFFF3F7F5);   // Soft light grey-green
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF2C8A53);      // Original Cricket Green (#2C8A53)
  static const Color accent = Color(0xFF2C8A53);
  static const Color secondary = Color(0xFFFFA000);   // Amber gold
  
  // Text colors for light backgrounds
  static const Color textPrimary = Color(0xFF141F1A);  // Dark forest-grey
  static const Color textSecondary = Color(0xFF556961); // Muted green-grey
  static const Color textMuted = Color(0xFF8CA399);
  
  // Card borders and details
  static const Color border = Color(0xFFE0EBE6);
  static const Color cardHighlight = Color(0x1A2C8A53);

  // Premium Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2C8A53), Color(0xFF20663C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient liveGradient = LinearGradient(
    colors: [Color(0xFFFF1744), Color(0xFFD50000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF5F8F6), Color(0xFFEAF1EE)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFFAFDFB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient headerGradient = LinearGradient(
    colors: [Color(0xFF2C8A53), Color(0xFF1E603B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient premiumDarkGradient = LinearGradient(
    colors: [Color(0xFF0F2618), Color(0xFF07120B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Modern Card Decoration
  static BoxDecoration cardDecoration({bool hasHighlight = false, double borderRadius = 20.0}) {
    return BoxDecoration(
      gradient: cardGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: hasHighlight ? primary.withValues(alpha: 0.5) : border,
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: hasHighlight ? 0.08 : 0.02),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration dashboardCardDecoration({
    required Color accentColor,
    bool isHovered = false,
    double borderRadius = 24.0,
  }) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isHovered ? accentColor.withValues(alpha: 0.6) : border,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: isHovered ? accentColor.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.02),
          blurRadius: isHovered ? 24 : 12,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Modern Glassmorphism Decoration
  static BoxDecoration glassDecoration({
    double borderRadius = 24.0,
    bool hasHighlight = false,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: hasHighlight ? primary.withValues(alpha: 0.4) : border.withValues(alpha: 0.5),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // Modern Input Decoration
  static InputDecoration inputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
      prefixIcon: Icon(prefixIcon, color: primary.withValues(alpha: 0.8), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF9FBFB),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
      ),
    );
  }
}

