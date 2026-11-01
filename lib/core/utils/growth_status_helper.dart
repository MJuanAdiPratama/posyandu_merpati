import 'dart:math';

import 'who_growth_data.dart';

/// Status gizi dihitung dari Z-score standar WHO Child Growth Standards
/// (BB/U = berat badan menurut umur, TB/U = tinggi/panjang badan menurut umur).
class GrowthStatusHelper {
  static String hitungStatusGizi({
    required double beratBadan,
    required double tinggiBadan,
    required int usiaBulan,
    required String jenisKelamin,
  }) {
    if (usiaBulan < 0) return 'Tidak diketahui';

    final zTinggi = zScoreTinggiUmur(
      tinggiBadan: tinggiBadan,
      usiaBulan: usiaBulan,
      jenisKelamin: jenisKelamin,
    );
    final zBerat = zScoreBeratUmur(
      beratBadan: beratBadan,
      usiaBulan: usiaBulan,
      jenisKelamin: jenisKelamin,
    );

    if (zTinggi < -3) return 'Stunting';
    if (zTinggi < -2) return 'Risiko Stunting';

    if (zBerat < -3) return 'Gizi Buruk';
    if (zBerat < -2) return 'Gizi Kurang';
    if (zBerat > 3) return 'Obesitas';
    if (zBerat > 2) return 'Gizi Lebih';
    if (zBerat > 1) return 'Risiko Gizi Lebih';

    return 'Normal';
  }

  static String hitungStatusTinggiBadan({
    required double tinggiBadan,
    required int usiaBulan,
    required String jenisKelamin,
  }) {
    final z = zScoreTinggiUmur(
      tinggiBadan: tinggiBadan,
      usiaBulan: usiaBulan,
      jenisKelamin: jenisKelamin,
    );
    if (z < -3) return 'Sangat Pendek';
    if (z < -2) return 'Pendek';
    if (z <= 3) return 'Normal';
    return 'Tinggi';
  }

  static String hitungStatusBeratBadan({
    required double beratBadan,
    required int usiaBulan,
    required String jenisKelamin,
  }) {
    final z = zScoreBeratUmur(
      beratBadan: beratBadan,
      usiaBulan: usiaBulan,
      jenisKelamin: jenisKelamin,
    );
    return labelZScore(z);
  }

  /// Z-score berat badan menurut umur (BB/U) berdasarkan standar WHO.
  static double zScoreBeratUmur({
    required double beratBadan,
    required int usiaBulan,
    required String jenisKelamin,
  }) {
    final lakiLaki = jenisKelamin == 'Laki-laki';
    final tabel = lakiLaki
        ? WhoGrowthData.beratUmurLakiLaki
        : WhoGrowthData.beratUmurPerempuan;
    return _hitungZ(beratBadan, tabel[_indeksBulan(usiaBulan)]);
  }

  /// Z-score tinggi/panjang badan menurut umur (TB/U atau PB/U) berdasarkan
  /// standar WHO.
  static double zScoreTinggiUmur({
    required double tinggiBadan,
    required int usiaBulan,
    required String jenisKelamin,
  }) {
    final lakiLaki = jenisKelamin == 'Laki-laki';
    final tabel = lakiLaki
        ? WhoGrowthData.tinggiUmurLakiLaki
        : WhoGrowthData.tinggiUmurPerempuan;
    return _hitungZ(tinggiBadan, tabel[_indeksBulan(usiaBulan)]);
  }

  /// Z-Score BB/U, dipertahankan untuk kompatibilitas kode yang sudah ada.
  static double hitungZScoreBBTB({
    required double beratBadan,
    required int usiaBulan,
    required String jenisKelamin,
  }) {
    return zScoreBeratUmur(
      beratBadan: beratBadan,
      usiaBulan: usiaBulan,
      jenisKelamin: jenisKelamin,
    );
  }

  /// Label status dari Z-Score BB/U.
  static String labelZScore(double z) {
    if (z < -3) return 'Sangat Kurang';
    if (z < -2) return 'Kurang';
    if (z <= 1) return 'Normal';
    if (z <= 2) return 'Lebih';
    return 'Obesitas';
  }

  static String statusGiziKeWarna(String status) {
    switch (status) {
      case 'Normal':
        return 'hijau';
      case 'Gizi Kurang':
      case 'Risiko Stunting':
        return 'kuning';
      case 'Gizi Buruk':
      case 'Stunting':
        return 'merah_tua';
      case 'Risiko Gizi Lebih':
        return 'oranye';
      case 'Gizi Lebih':
      case 'Obesitas':
        return 'merah';
      default:
        return 'abu';
    }
  }

  /// True jika status menandakan masalah gizi yang perlu ditindaklanjuti
  /// (bukan Normal dan bukan hasil yang tidak bisa dihitung).
  static bool isBermasalah(String? status) {
    return status != null && status != 'Normal' && status != 'Tidak diketahui';
  }

  static int _indeksBulan(int usiaBulan) => usiaBulan.clamp(0, 60);

  /// Rumus Box-Cox standar WHO: Z = ((X/M)^L - 1) / (L*S), atau
  /// Z = ln(X/M) / S ketika L = 0.
  static double _hitungZ(double x, List<double> lms) {
    final l = lms[0], m = lms[1], s = lms[2];
    if (l == 0) return log(x / m) / s;
    return (pow(x / m, l) - 1) / (l * s);
  }
}
