import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary dark background colors
  static const Color backgroundDark = Color(0xFF1A1D26);
  static const Color backgroundMedium = Color(0xFF232731);
  static const Color backgroundLight = Color(0xFF2A2F3C);
  
  // Neumorphic shadow colors
  static const Color shadowDark = Color(0xFF0D0F14);
  static const Color shadowLight = Color(0xFF2D3340);
  
  // Accent colors (blue theme)
  static const Color primaryBlue = Color(0xFF00B4D8);
  static const Color primaryBlueLight = Color(0xFF48CAE4);
  static const Color primaryBlueDark = Color(0xFF0077B6);
  static const Color accentCyan = Color(0xFF90E0EF);
  
  // Status colors
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color info = Color(0xFF60A5FA);
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8BCC8);
  static const Color textMuted = Color(0xFF6B7280);
  
  // Feature card colors
  static const Color cardPDF = Color(0xFFFF6B6B);
  static const Color cardEstimate = Color(0xFF00B4D8);
  static const Color cardAI = Color(0xFF8B5CF6);
  static const Color cardLibrary = Color(0xFF14B8A6);
  static const Color cardHistory = Color(0xFF3B82F6);
  static const Color cardDatabase = Color(0xFF22C55E);
  static const Color cardManager = Color(0xFFA855F7);
  static const Color cardJSON = Color(0xFFF59E0B);
}

class NeumorphicDecoration {
  static BoxDecoration flat({
    Color? color,
    double radius = 20,
    double intensity = 0.8,
  }) {
    final bgColor = color ?? AppColors.backgroundMedium;
    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowDark.withOpacity(0.7 * intensity),
          offset: const Offset(6, 6),
          blurRadius: 12,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: AppColors.shadowLight.withOpacity(0.4 * intensity),
          offset: const Offset(-4, -4),
          blurRadius: 10,
          spreadRadius: 0,
        ),
      ],
    );
  }

  static BoxDecoration pressed({
    Color? color,
    double radius = 20,
    double intensity = 0.8,
  }) {
    final bgColor = color ?? AppColors.backgroundMedium;
    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowDark.withOpacity(0.5 * intensity),
          offset: const Offset(2, 2),
          blurRadius: 5,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: AppColors.shadowLight.withOpacity(0.3 * intensity),
          offset: const Offset(-2, -2),
          blurRadius: 5,
          spreadRadius: -2,
        ),
      ],
    );
  }

  static BoxDecoration concave({
    Color? color,
    double radius = 20,
    double intensity = 0.8,
  }) {
    final bgColor = color ?? AppColors.backgroundMedium;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.shadowDark.withOpacity(0.3 * intensity),
          bgColor,
          AppColors.shadowLight.withOpacity(0.15 * intensity),
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowDark.withOpacity(0.4 * intensity),
          offset: const Offset(4, 4),
          blurRadius: 8,
          spreadRadius: -3,
        ),
      ],
    );
  }

  static BoxDecoration glowingBorder({
    required Color glowColor,
    Color? backgroundColor,
    double radius = 20,
    double glowIntensity = 0.6,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? AppColors.backgroundMedium,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: glowColor.withOpacity(0.5),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(0.3 * glowIntensity),
          blurRadius: 20,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: AppColors.shadowDark.withOpacity(0.5),
          offset: const Offset(4, 4),
          blurRadius: 10,
        ),
        BoxShadow(
          color: AppColors.shadowLight.withOpacity(0.2),
          offset: const Offset(-3, -3),
          blurRadius: 8,
        ),
      ],
    );
  }
}

class AppTheme {
  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark();
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        brightness: Brightness.dark,
        primary: AppColors.primaryBlue,
        secondary: AppColors.accentCyan,
        tertiary: AppColors.primaryBlueLight,
        surface: AppColors.backgroundMedium,
        onSurface: AppColors.textPrimary,
      ),
      
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
          color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: AppColors.textPrimary,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.backgroundMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.shadowLight.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
        ),
      ),
      
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),
      
      dividerTheme: DividerThemeData(
        color: AppColors.shadowLight.withOpacity(0.3),
        thickness: 1,
      ),
    );
  }
}
