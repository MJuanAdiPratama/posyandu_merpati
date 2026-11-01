import 'package:flutter_test/flutter_test.dart';
import 'package:posyandu_merpati/core/utils/growth_status_helper.dart';

void main() {
  group('GrowthStatusHelper Z-score WHO', () {
    test('berat median anak laki-laki usia 12 bulan -> Z mendekati 0', () {
      final z = GrowthStatusHelper.zScoreBeratUmur(
        beratBadan: 9.6479,
        usiaBulan: 12,
        jenisKelamin: 'Laki-laki',
      );
      expect(z, closeTo(0, 0.01));
    });

    test('berat -2 SD anak laki-laki usia 12 bulan -> Z mendekati -2', () {
      final z = GrowthStatusHelper.zScoreBeratUmur(
        beratBadan: 7.7,
        usiaBulan: 12,
        jenisKelamin: 'Laki-laki',
      );
      expect(z, closeTo(-2, 0.05));
    });

    test('tinggi median anak perempuan usia 24 bulan -> Z mendekati 0', () {
      final z = GrowthStatusHelper.zScoreTinggiUmur(
        tinggiBadan: 85.7153,
        usiaBulan: 24,
        jenisKelamin: 'Perempuan',
      );
      expect(z, closeTo(0, 0.01));
    });

    test('balita stunting (TB/U < -3 SD) terklasifikasi Stunting', () {
      final status = GrowthStatusHelper.hitungStatusGizi(
        beratBadan: 8.0,
        tinggiBadan: 76.0,
        usiaBulan: 24,
        jenisKelamin: 'Laki-laki',
      );
      expect(status, 'Stunting');
    });

    test('balita gizi normal terklasifikasi Normal', () {
      final status = GrowthStatusHelper.hitungStatusGizi(
        beratBadan: 12.2,
        tinggiBadan: 87.8,
        usiaBulan: 24,
        jenisKelamin: 'Laki-laki',
      );
      expect(status, 'Normal');
    });

    test('usia negatif -> Tidak diketahui', () {
      final status = GrowthStatusHelper.hitungStatusGizi(
        beratBadan: 10,
        tinggiBadan: 80,
        usiaBulan: -1,
        jenisKelamin: 'Laki-laki',
      );
      expect(status, 'Tidak diketahui');
    });

    test('usia 0 bulan tetap terklasifikasi (bukan Tidak diketahui)', () {
      final status = GrowthStatusHelper.hitungStatusGizi(
        beratBadan: 3.3,
        tinggiBadan: 49.9,
        usiaBulan: 0,
        jenisKelamin: 'Laki-laki',
      );
      expect(status, isNot('Tidak diketahui'));
    });
  });

  group('GrowthStatusHelper.isBermasalah', () {
    test('status Normal bukan bermasalah', () {
      expect(GrowthStatusHelper.isBermasalah('Normal'), isFalse);
    });

    test('status null bukan bermasalah', () {
      expect(GrowthStatusHelper.isBermasalah(null), isFalse);
    });

    test('status "Tidak diketahui" bukan bermasalah', () {
      expect(GrowthStatusHelper.isBermasalah('Tidak diketahui'), isFalse);
    });

    test('status Stunting bermasalah', () {
      expect(GrowthStatusHelper.isBermasalah('Stunting'), isTrue);
    });

    test('status Gizi Kurang bermasalah', () {
      expect(GrowthStatusHelper.isBermasalah('Gizi Kurang'), isTrue);
    });

    test('status Obesitas bermasalah', () {
      expect(GrowthStatusHelper.isBermasalah('Obesitas'), isTrue);
    });
  });
}
