import 'package:flutter/material.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.brightness_6),
      onPressed: () {
        // TODO: Implement theme switching
      },
    );
  }
}
