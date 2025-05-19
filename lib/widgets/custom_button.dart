import 'package:flutter/material.dart';
import '../theme/app_theme.dart'; // Corrected import path

Widget customButton(String text, VoidCallback onPressed, {bool isLoading = false}) {
  return ElevatedButton(
    onPressed: isLoading ? null : onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primaryColor, // Maroon color
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
    child: isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
  );
} 