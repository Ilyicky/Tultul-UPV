import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Merriweather',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Merriweather'),
        displayMedium: TextStyle(fontFamily: 'Merriweather'),
        displaySmall: TextStyle(fontFamily: 'Merriweather'),
        headlineLarge: TextStyle(fontFamily: 'Merriweather'),
        headlineMedium: TextStyle(fontFamily: 'Merriweather'),
        headlineSmall: TextStyle(fontFamily: 'Merriweather'),
        titleLarge: TextStyle(fontFamily: 'Merriweather'),
        titleMedium: TextStyle(fontFamily: 'Merriweather'),
        titleSmall: TextStyle(fontFamily: 'Merriweather'),
        bodyLarge: TextStyle(fontFamily: 'Merriweather'),
        bodyMedium: TextStyle(fontFamily: 'Merriweather'),
        bodySmall: TextStyle(fontFamily: 'Merriweather'),
        labelLarge: TextStyle(fontFamily: 'Merriweather'),
        labelMedium: TextStyle(fontFamily: 'Merriweather'),
        labelSmall: TextStyle(fontFamily: 'Merriweather'),
      ),
    );
  }
} 