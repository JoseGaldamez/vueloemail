import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Professional minimalist palette
  static const Color primaryBlue = Color(0xFF0F223D); // Deep dark blue
  static const Color accentBlue = Color(0xFF1F487E); // Slightly lighter for active states
  static const Color accentOrange = Color(0xFFF1653B); // Orange accent for subtle details
  
  // Backgrounds - extremely clean
  static const Color backgroundWhite = Color(0xFFF8F9FA); // Very light grey, almost white
  static const Color surfaceWhite = Colors.white; // Pure white for cards/surfaces
  
  // Text colors
  static const Color textMain = Color(0xFF1E2632); // Near black
  static const Color textSecondary = Color(0xFF6B7280); // Muted grey
  static const Color textLight = Color(0xFFA0AEC0); // Very muted

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: accentOrange,
        surface: surfaceWhite,
        onPrimary: Colors.white,
        onSurface: textMain,
        surfaceContainerHighest: Color(0xFFEDF2F7), // Light grey for hovered/selected surfaces
      ),
      scaffoldBackgroundColor: backgroundWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite, // Clean white app bar
        foregroundColor: primaryBlue, // Dark blue icons and text
        elevation: 0,
        scrolledUnderElevation: 0, // Prevents shade when scrolling
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryBlue),
        titleTextStyle: TextStyle(
          color: primaryBlue,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark, // Dark status bar icons
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0, // Flat buttons look more modern
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Softer corners
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), // Rounded inputs
          borderSide: BorderSide.none, // Try to avoid heavy borders initially
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentOrange, // Orange FAB for strong contrast and call to action
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: surfaceWhite,
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.05),
        indicatorColor: const Color(0xFFEDF2F7), // Subtle blue-grey for active indicator
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryBlue);
          }
          return TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryBlue, size: 26);
          }
          return IconThemeData(color: textSecondary, size: 24);
        }),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent, // We hide default dividers for a cleaner look
        thickness: 0,
        space: 8,
      ),
    );
  }
}
