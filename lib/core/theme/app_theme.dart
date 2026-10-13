import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const forest = Color(0xff183e32);
  static const cream = Color(0xfff4f6f2);
  static ThemeData create(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: forest,
      brightness: brightness,
      primary: dark ? const Color(0xffbdd0ab) : forest,
      surface: dark ? const Color(0xff16231e) : cream,
      primaryContainer: dark
          ? const Color(0xff314b3c)
          : const Color(0xffd5e9da),
      onPrimaryContainer: dark ? cream : forest,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'Manrope',
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Lora',
          fontSize: 72,
          height: 1.05,
          color: scheme.onSurface,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Lora',
          fontSize: 36,
          height: 1.15,
          color: scheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Lora',
          fontSize: 27,
          height: 1.2,
          color: scheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          height: 1.55,
          color: scheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          height: 1.5,
          color: scheme.onSurface,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        height: 76,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: .5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: .5),
      ),
    );
  }
}
