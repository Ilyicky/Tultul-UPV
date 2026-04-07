import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF800000); // Maroon color
  static const Color secondaryColor = Color(0xFF014421); // Forest Green color

  static const TextStyle titleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: 'Golos-Font.ttf',
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontFamily: 'Golos-Font.ttf',
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontFamily: 'Golos-Font.ttf',
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Golos-Font.ttf',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Golos-Font.ttf'),
        displayMedium: TextStyle(fontFamily: 'Golos-Font.ttf'),
        displaySmall: TextStyle(fontFamily: 'Golos-Font.ttf'),
        headlineLarge: TextStyle(fontFamily: 'Golos-Font.ttf'),
        headlineMedium: TextStyle(fontFamily: 'Golos-Font.ttf'),
        headlineSmall: TextStyle(fontFamily: 'Golos-Font.ttf'),
        titleLarge: TextStyle(fontFamily: 'Golos-Font.ttf'),
        titleMedium: TextStyle(fontFamily: 'Golos-Font.ttf'),
        titleSmall: TextStyle(fontFamily: 'Golos-Font.ttf'),
        bodyLarge: TextStyle(fontFamily: 'Golos-Font.ttf'),
        bodyMedium: TextStyle(fontFamily: 'Golos-Font.ttf'),
        bodySmall: TextStyle(fontFamily: 'Golos-Font.ttf'),
        labelLarge: TextStyle(fontFamily: 'Golos-Font.ttf'),
        labelMedium: TextStyle(fontFamily: 'Golos-Font.ttf'),
        labelSmall: TextStyle(fontFamily: 'Golos-Font.ttf'),
      ),
    );
  }
}
