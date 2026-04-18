import 'package:flutter/material.dart';

/// Rakshak Sentinel Color Palette
/// No gradients. Flat, bold colors only.
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF0A0E27);
  static const Color primaryLight = Color(0xFF1A1F3A);
  static const Color accent = Color(0xFF00D9FF);
  
  // Risk Colors
  static const Color riskLow = Color(0xFF00E676);
  static const Color riskMedium = Color(0xFFFFD600);
  static const Color riskHigh = Color(0xFFFF1744);
  static const Color riskCritical = Color(0xFFD50000);
  
  // Neutral Colors
  static const Color background = Color(0xFF0A0E27);
  static const Color surface = Color(0xFF1A1F3A);
  static const Color surfaceLight = Color(0xFF252B47);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8D4);
  static const Color textTertiary = Color(0xFF6B7599);
  
  // Functional Colors
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD600);
  static const Color error = Color(0xFFFF1744);
  static const Color info = Color(0xFF00D9FF);
  
  // Border & Divider
  static const Color border = Color(0xFF2A3150);
  static const Color divider = Color(0xFF1F2540);
}
