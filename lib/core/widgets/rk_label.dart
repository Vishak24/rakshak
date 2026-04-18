import 'package:flutter/material.dart';
import '../theme/app_text.dart';
import '../theme/app_colors.dart';

/// Rakshak Label Widget
/// Simple text label with consistent styling
class RkLabel extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final TextAlign? textAlign;

  const RkLabel({
    super.key,
    required this.text,
    this.style,
    this.color,
    this.textAlign,
  });

  /// Small label (10px, uppercase, letter-spacing)
  factory RkLabel.small(String text, {Color? color}) {
    return RkLabel(
      text: text.toUpperCase(),
      style: AppText.labelSmall,
      color: color,
    );
  }

  /// Medium label (12px, semi-bold)
  factory RkLabel.medium(String text, {Color? color}) {
    return RkLabel(
      text: text,
      style: AppText.labelMedium,
      color: color,
    );
  }

  /// Large label (14px, semi-bold)
  factory RkLabel.large(String text, {Color? color}) {
    return RkLabel(
      text: text,
      style: AppText.labelLarge,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (style ?? AppText.labelMedium).copyWith(
        color: color ?? AppColors.textSecondary,
      ),
      textAlign: textAlign,
    );
  }
}
