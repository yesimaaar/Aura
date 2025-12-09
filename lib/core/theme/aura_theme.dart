import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuraColors {
  // Gradient Colors (solo para el nombre "Aura")
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryCyan = Color(0xFF06B6D4);
  
  // Dark Theme - Pure Black
  static const Color backgroundDark = Color(0xFF000000);
  static const Color backgroundCard = Color(0xFF0A0A0A);
  static const Color backgroundElevated = Color(0xFF111111);
  static const Color bottomNavDark = Color(0xFF000000);
  static const Color inputBackground = Color(0xFF1A1A1A);
  
  // Light Theme Background Colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundCardLight = Color(0xFFFFFFFF);
  static const Color backgroundElevatedLight = Color(0xFFF0F0F0);
  static const Color bottomNavLight = Color(0xFFFFFFFF);
  static const Color inputBackgroundLight = Color(0xFFE5E5E5);
  
  // Surface Colors
  static const Color surface = Color(0xFF0A0A0A);
  static const Color surfaceLight = Color(0xFF1A1A1A);
  static const Color surfaceLightTheme = Color(0xFFE0E0E0);
  
  // Text Colors - Dark Theme
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textMuted = Color(0xFF666666);
  
  // Text Colors - Light Theme
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0xFF555555);
  static const Color textMutedLight = Color(0xFF999999);
  
  // Accent Colors (minimalistas)
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentWhite = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Gradients (solo para el nombre Aura)
  static const LinearGradient auraGradient = LinearGradient(
    colors: [primaryPurple, primaryBlue, primaryCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Helper methods for theme-aware colors
  static Color getBackgroundColor(bool isDark) => isDark ? backgroundDark : backgroundLight;
  static Color getCardColor(bool isDark) => isDark ? backgroundCard : backgroundCardLight;
  static Color getBottomNavColor(bool isDark) => isDark ? bottomNavDark : bottomNavLight;
  static Color getTextPrimary(bool isDark) => isDark ? textPrimary : textPrimaryLight;
  static Color getTextSecondary(bool isDark) => isDark ? textSecondary : textSecondaryLight;
  static Color getTextMuted(bool isDark) => isDark ? textMuted : textMutedLight;
  static Color getSurfaceColor(bool isDark) => isDark ? surfaceLight : surfaceLightTheme;
  static Color getInputBackground(bool isDark) => isDark ? inputBackground : inputBackgroundLight;
}

class AuraTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AuraColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AuraColors.textPrimary,
        secondary: AuraColors.textSecondary,
        tertiary: AuraColors.textMuted,
        surface: AuraColors.surface,
        error: AuraColors.error,
        onPrimary: AuraColors.backgroundDark,
        onSecondary: AuraColors.backgroundDark,
        onSurface: AuraColors.textPrimary,
        onError: AuraColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AuraColors.textPrimary),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AuraColors.textPrimary),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AuraColors.textPrimary),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AuraColors.textPrimary),
          headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AuraColors.textPrimary),
          titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AuraColors.textPrimary),
          titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AuraColors.textPrimary),
          bodyLarge: TextStyle(fontSize: 16, color: AuraColors.textSecondary),
          bodyMedium: TextStyle(fontSize: 14, color: AuraColors.textSecondary),
          bodySmall: TextStyle(fontSize: 12, color: AuraColors.textMuted),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AuraColors.backgroundDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AuraColors.textPrimary),
        iconTheme: IconThemeData(color: AuraColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AuraColors.backgroundCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AuraColors.textPrimary,
          foregroundColor: AuraColors.backgroundDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AuraColors.textPrimary,
          side: const BorderSide(color: AuraColors.surfaceLight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AuraColors.textPrimary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AuraColors.textPrimary,
        foregroundColor: AuraColors.backgroundDark,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AuraColors.bottomNavDark,
        indicatorColor: AuraColors.surfaceLight,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AuraColors.bottomNavDark,
        selectedItemColor: AuraColors.textPrimary,
        unselectedItemColor: AuraColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AuraColors.textPrimary,
        inactiveTrackColor: AuraColors.surfaceLight,
        thumbColor: AuraColors.textPrimary,
        overlayColor: AuraColors.textPrimary.withValues(alpha: 0.2),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AuraColors.textPrimary;
          return AuraColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AuraColors.textPrimary.withValues(alpha: 0.5);
          return AuraColors.surfaceLight;
        }),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AuraColors.textSecondary,
        textColor: AuraColors.textPrimary,
      ),
      dividerTheme: const DividerThemeData(color: AuraColors.surfaceLight, thickness: 1),
      tabBarTheme: const TabBarThemeData(
        labelColor: AuraColors.textPrimary,
        unselectedLabelColor: AuraColors.textMuted,
        indicatorColor: AuraColors.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AuraColors.inputBackground,
        hintStyle: const TextStyle(color: AuraColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AuraColors.textMuted, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AuraColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AuraColors.textPrimaryLight,
        secondary: AuraColors.textSecondaryLight,
        tertiary: AuraColors.textMutedLight,
        surface: AuraColors.backgroundCardLight,
        error: AuraColors.error,
        onPrimary: AuraColors.backgroundLight,
        onSecondary: AuraColors.backgroundLight,
        onSurface: AuraColors.textPrimaryLight,
        onError: AuraColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AuraColors.textPrimaryLight),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AuraColors.textPrimaryLight),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AuraColors.textPrimaryLight),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AuraColors.textPrimaryLight),
          headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AuraColors.textPrimaryLight),
          titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AuraColors.textPrimaryLight),
          titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AuraColors.textPrimaryLight),
          bodyLarge: TextStyle(fontSize: 16, color: AuraColors.textSecondaryLight),
          bodyMedium: TextStyle(fontSize: 14, color: AuraColors.textSecondaryLight),
          bodySmall: TextStyle(fontSize: 12, color: AuraColors.textMutedLight),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AuraColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AuraColors.textPrimaryLight),
        iconTheme: IconThemeData(color: AuraColors.textPrimaryLight),
      ),
      cardTheme: CardThemeData(
        color: AuraColors.backgroundCardLight,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AuraColors.textPrimaryLight,
          foregroundColor: AuraColors.backgroundLight,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AuraColors.textPrimaryLight,
          side: const BorderSide(color: AuraColors.surfaceLightTheme),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AuraColors.textPrimaryLight),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AuraColors.textPrimaryLight,
        foregroundColor: AuraColors.backgroundLight,
        elevation: 2,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AuraColors.bottomNavLight,
        indicatorColor: AuraColors.surfaceLightTheme,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AuraColors.bottomNavLight,
        selectedItemColor: AuraColors.textPrimaryLight,
        unselectedItemColor: AuraColors.textMutedLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AuraColors.textPrimaryLight,
        inactiveTrackColor: AuraColors.surfaceLightTheme,
        thumbColor: AuraColors.textPrimaryLight,
        overlayColor: AuraColors.textPrimaryLight.withValues(alpha: 0.2),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AuraColors.textPrimaryLight;
          return AuraColors.textMutedLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AuraColors.textPrimaryLight.withValues(alpha: 0.5);
          return AuraColors.surfaceLightTheme;
        }),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AuraColors.textSecondaryLight,
        textColor: AuraColors.textPrimaryLight,
      ),
      dividerTheme: const DividerThemeData(color: AuraColors.surfaceLightTheme, thickness: 1),
      tabBarTheme: const TabBarThemeData(
        labelColor: AuraColors.textPrimaryLight,
        unselectedLabelColor: AuraColors.textMutedLight,
        indicatorColor: AuraColors.textPrimaryLight,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AuraColors.inputBackgroundLight,
        hintStyle: const TextStyle(color: AuraColors.textMutedLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AuraColors.textMutedLight, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
