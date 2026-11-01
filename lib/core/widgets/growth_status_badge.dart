import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../utils/growth_status_helper.dart';

/// Warna badge status gizi, satu sumber kebenaran dipakai di semua layar
/// (sebelumnya terduplikasi dan tidak konsisten di beberapa layar).
Color growthStatusColor(String status) {
  switch (GrowthStatusHelper.statusGiziKeWarna(status)) {
    case 'hijau':
      return AppColors.success;
    case 'kuning':
      return AppColors.warning;
    case 'merah_tua':
      return AppColors.error;
    case 'oranye':
    case 'merah':
      return Colors.deepOrange;
    default:
      return AppColors.textSecondary;
  }
}

IconData growthStatusIcon(String status) {
  switch (GrowthStatusHelper.statusGiziKeWarna(status)) {
    case 'hijau':
      return Icons.sentiment_satisfied_alt_rounded;
    case 'kuning':
    case 'merah_tua':
      return Icons.warning_amber_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}
