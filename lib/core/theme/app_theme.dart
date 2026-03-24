import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Brand Colors used in theme
  static const Color primary = AppColors.primary;
  static const Color background = AppColors.background;
  static const Color surface = AppColors.surface;

  static ThemeData get premiumDark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: AppColors.secondary,
        surface: surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
      ),

      // Modern Typography
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            headlineLarge: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            headlineMedium: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            titleLarge: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            bodyLarge: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
            bodyMedium: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            labelLarge: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),

      // Component Styling
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.textDim, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: primary.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primary,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary);
          }
          return const IconThemeData(color: AppColors.textSecondary);
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: background,
        selectedIconTheme: const IconThemeData(color: primary),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.textSecondary,
        ),
        selectedLabelTextStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: surface,
        dialBackgroundColor: AppColors.elevated,
        dialHandColor: primary.withValues(alpha: 0.7), // More subtle hand
        hourMinuteColor: AppColors.elevated,
        hourMinuteTextColor: AppColors.textPrimary,
        dayPeriodColor: AppColors.elevated,
        dayPeriodTextColor: AppColors.textPrimary,
        helpTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
        hourMinuteTextStyle: GoogleFonts.outfit(
          fontSize: 40,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1,
        ),
        dialTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        dayPeriodTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0.6,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  static ThemeData get premiumLight {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: AppColors.secondary,
        surface: Colors.grey.shade50,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: Colors.grey.shade900,
        onSurfaceVariant: Colors.grey.shade600,
        outline: Colors.grey.shade300,
      ),

      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme)
          .copyWith(
            headlineLarge: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
              letterSpacing: -0.5,
            ),
            headlineMedium: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
            titleLarge: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
            bodyLarge: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey.shade900,
              height: 1.5,
            ),
            bodyMedium: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            labelLarge: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade900,
        ),
        iconTheme: IconThemeData(color: Colors.grey.shade700),
      ),

      cardTheme: CardThemeData(
        color: Colors.grey.shade50,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primary.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primary,
            );
          }
          return GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary);
          }
          return IconThemeData(color: Colors.grey.shade400);
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        selectedIconTheme: const IconThemeData(color: primary),
        unselectedIconTheme: IconThemeData(color: Colors.grey.shade400),
        selectedLabelTextStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          fontSize: 11,
          color: Colors.grey.shade600,
        ),
      ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: Colors.white,
        dialBackgroundColor: Colors.grey.shade100,
        dialHandColor: primary.withValues(alpha: 0.7),
        hourMinuteColor: Colors.grey.shade100,
        hourMinuteTextColor: Colors.grey.shade900,
        dayPeriodColor: Colors.grey.shade100,
        dayPeriodTextColor: Colors.grey.shade900,
        helpTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
          letterSpacing: 0.8,
        ),
        hourMinuteTextStyle: GoogleFonts.outfit(
          fontSize: 40,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade900,
          height: 1,
        ),
        dialTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade900,
        ),
        dayPeriodTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade900,
          letterSpacing: 0.6,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
