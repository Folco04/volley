import 'package:flutter/material.dart';

class AppColors {
  static const cream = Color(0xFFF8F3EA);
  static const creamDark = Color(0xFFF1E8D8);
  static const pink = Color(0xFFF4B8C5);
  static const pinkDeep = Color(0xFFE89AAB);
  static const ink = Color(0xFF3C3946);
  static const muted = Color(0xFF8A8494);
  static const white = Color(0xFFFFFCF8);
  static const peach = Color(0xFFFFC4A8);
  static const mint = Color(0xFFBFE8C4);
  static const sky = Color(0xFFB7D4F5);

  /// Stessi colori della barra pezzi: indice stabile per esercizio.
  static const puzzle = <Color>[
    Color(0xFF86DC82), // verde
    Color(0xFF7EB6F7), // azzurro
    Color(0xFFF5D24A), // giallo
    Color(0xFFF3A6B9), // rosa
    Color(0xFFFFB48A), // pesca
    Color(0xFFB9A6F5), // lilla
  ];

  static Color puzzleAt(int index) => puzzle[index % puzzle.length];

  static Color onPuzzle(Color c) {
    return c.computeLuminance() > 0.55 ? ink : const Color(0xFF2B2833);
  }
}

class AppTheme {
  static ThemeData get data {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pink,
        surface: AppColors.cream,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
          letterSpacing: -0.6,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        bodyMedium: TextStyle(color: AppColors.ink),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
      ),
    );
  }
}
