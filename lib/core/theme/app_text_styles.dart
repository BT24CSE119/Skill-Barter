import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle subHeading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Color(0xFF334155), // slate-700
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.textDark,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: Color(0xFF64748B), // slate-500
  );

  static const TextStyle credits = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.amber,
  );

  static const TextStyle xp = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.blueAccent,
  );
}