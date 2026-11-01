import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:posyandu_merpati/core/constants/app_colors.dart';
import 'package:posyandu_merpati/core/widgets/growth_status_badge.dart';

void main() {
  group('growthStatusColor', () {
    test('Normal -> hijau (success)', () {
      expect(growthStatusColor('Normal'), AppColors.success);
    });

    test('Gizi Kurang -> kuning (warning)', () {
      expect(growthStatusColor('Gizi Kurang'), AppColors.warning);
    });

    test('Risiko Stunting -> kuning (warning)', () {
      expect(growthStatusColor('Risiko Stunting'), AppColors.warning);
    });

    test('Stunting -> merah tua (error)', () {
      expect(growthStatusColor('Stunting'), AppColors.error);
    });

    test('Gizi Buruk -> merah tua (error)', () {
      expect(growthStatusColor('Gizi Buruk'), AppColors.error);
    });

    test('Obesitas -> deepOrange', () {
      expect(growthStatusColor('Obesitas'), Colors.deepOrange);
    });

    test('status tak dikenal -> abu (textSecondary)', () {
      expect(growthStatusColor('Belum ada data'), AppColors.textSecondary);
    });
  });

  group('growthStatusIcon', () {
    test('Normal -> sentiment_satisfied_alt_rounded', () {
      expect(growthStatusIcon('Normal'), Icons.sentiment_satisfied_alt_rounded);
    });

    test('Gizi Buruk -> warning_amber_rounded', () {
      expect(growthStatusIcon('Gizi Buruk'), Icons.warning_amber_rounded);
    });

    test('status tak dikenal -> info_outline_rounded', () {
      expect(growthStatusIcon('Belum ada data'), Icons.info_outline_rounded);
    });
  });
}
