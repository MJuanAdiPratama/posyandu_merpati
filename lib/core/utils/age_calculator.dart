class AgeCalculator {
  static int hitungUsiaBulan(DateTime tanggalLahir, DateTime tanggalAcuan) {
    int tahun = tanggalAcuan.year - tanggalLahir.year;
    int bulan = tanggalAcuan.month - tanggalLahir.month;
    int totalBulan = tahun * 12 + bulan;
    if (tanggalAcuan.day < tanggalLahir.day) {
      totalBulan--;
    }
    return totalBulan < 0 ? 0 : totalBulan;
  }

  static int hitungUsiaBulanSekarang(DateTime tanggalLahir) {
    return hitungUsiaBulan(tanggalLahir, DateTime.now());
  }

  static String formatUsia(int usiaBulan) {
    if (usiaBulan < 12) {
      return '$usiaBulan bulan';
    }
    int tahun = usiaBulan ~/ 12;
    int sisaBulan = usiaBulan % 12;
    if (sisaBulan == 0) return '$tahun tahun';
    return '$tahun tahun $sisaBulan bulan';
  }

  static String formatUsiaDariTanggalLahir(DateTime tanggalLahir) {
    int usiaBulan = hitungUsiaBulanSekarang(tanggalLahir);
    return formatUsia(usiaBulan);
  }

  /// Mengembalikan usia dalam format "X bulan Y hari"
  static String formatUsiaDetail(
    DateTime tanggalLahir, [
    DateTime? tanggalAcuan,
  ]) {
    final acuan = tanggalAcuan ?? DateTime.now();
    final bulan = hitungUsiaBulan(tanggalLahir, acuan);
    // Hitung sisa hari setelah bulan penuh
    final setelahBulan = DateTime(
      tanggalLahir.year + (tanggalLahir.month + bulan - 1) ~/ 12,
      (tanggalLahir.month + bulan - 1) % 12 + 1,
      tanggalLahir.day,
    );
    final hari = acuan.difference(setelahBulan).inDays;
    if (bulan == 0) return '${hari.clamp(0, 999)} hari';
    if (hari <= 0) return '$bulan bulan';
    return '$bulan bulan $hari hari';
  }
}
