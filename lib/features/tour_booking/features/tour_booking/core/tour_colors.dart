import 'package:flutter/material.dart';
import 'package:pathway/core/theme/app_colors.dart';

/// Tour Booking colour tokens.
///
/// Neutrals, status and service-tile colours are re-used from the app-wide
/// [AppColors]; only the module's indigo/teal brand shades from the design
/// are defined here.
class TourColors {
  TourColors._();

  // Brand
  static const Color primary = AppColors.mapBlue; // indigo-blue 0xFF3D4DE0
  static const Color primaryDark = Color(0xFF2B37B8);
  static const Color primaryLight = Color(0xFF6B76F0);
  static const Color purple = Color(0xFF7C3AED);
  static const Color tile = Color(0xFFF1F4FF);
  static const Color chip = Color(0xFFEFF2FF);

  // Hero (tropical)
  static const Color heroTop = Color(0xFF0B8FB5);
  static const Color heroMid = Color(0xFF2DD4BF);
  static const Color heroBottom = Color(0xFF0F766E);

  // Shared tokens from AppColors
  static const Color text = AppColors.textPrimary;
  static const Color muted = AppColors.textSecondary;
  static const Color subtle = AppColors.textTertiary;
  static const Color border = AppColors.border;
  static const Color star = AppColors.star;
  static const Color success = AppColors.success;
  static const Color successSurface = AppColors.successSurface;
  static const Color error = AppColors.error;
  static const Color errorSurface = AppColors.errorSurface;
  static const Color info = AppColors.info;
  static const Color infoSurface = AppColors.infoSurface;
  static const Color tipBg = AppColors.deliveryBg;
  static const Color tipBorder = AppColors.deliveryBorder;

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [heroTop, heroMid, heroBottom],
  );

  static const LinearGradient promoGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, purple],
  );

  static const LinearGradient confirmedGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFDDEBFF), Colors.white],
  );
}
