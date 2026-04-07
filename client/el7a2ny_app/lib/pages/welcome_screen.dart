import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Emergency Vibe: A striking diagonal gradient from bright "alert" red to a deep, serious maroon
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE44646), // Bright urgent red (top-left)
              Color(0xFF8B0000), // Deep maroon (bottom-right)
            ],
          ),
        ),
        child: const Center(
          child: Text(
            'الحقني',
            style: TextStyle(
              fontFamily: 'Unixel',
              fontSize: 68, // Made the text a bit bigger
              fontWeight: FontWeight.w900, // Maximum boldness
              color: Colors.white,
              shadows: [
                // A double-layered drop shadow to make the word "pop" out aggressively and look premium
                Shadow(
                  offset: Offset(0, 8),
                  blurRadius: 12.0,
                  color: Colors.black45,
                ),
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 4.0,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
