import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF800000); // Maroon color

  static const TextStyle titleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: 'Montserrat-VariableFont.ttf',
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontFamily: 'Montserrat-VariableFont.ttf',
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontFamily: 'Montserrat-VariableFont.ttf',
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Montserrat-VariableFont.ttf',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Montserrat-VariableFont.ttf'),
        displayMedium: TextStyle(fontFamily: 'Montserrat-VariableFont.ttf'),
        displaySmall: TextStyle(fontFamily: 'Montserrat-VariableFont.ttf'),
        headlineLarge: TextStyle(fontFamily: 'Montserrat-VariableFont.ttf'),
        headlineMedium: TextStyle(fontFamily: 'Montserrat-VariableFont.ttf'),
        headlineSmall: TextStyle(fontFamily: 'Montserrat-VariableFont.ttf'),
        titleLarge: TextStyle(fontFamily: 'Montserrat-VariableFont.ttf'),
        titleMedium: TextStyle(fontFamily: 'Montserrat-VariableFont.ttf'),
        titleSmall: TextStyle(fontFamily: 'Montserrat-VariableFont.ttf'),
        bodyLarge: TextStyle(fontFamily: 'Montserrat-VariableFont.ttf'),
        bodyMedium: TextStyle(fontFamily: 'Montserrat-VariableFont.ttf'),
        bodySmall: TextStyle(fontFamily: 'Montserrat-VariableFont.ttf'),
        labelLarge: TextStyle(fontFamily: 'Montserrat-VariableFont.ttf'),
        labelMedium: TextStyle(fontFamily: 'Montserrat-VariableFont.ttf'),
        labelSmall: TextStyle(fontFamily: 'Montserrat-VariableFont.ttf'),
      ),
    );
  }
} 