import '../../../core/utils/age_calculator.dart';
import '../../../core/utils/growth_status_helper.dart';
import '../../../data/models/balita_model.dart';
import '../../../data/models/jadwal_imunisasi_model.dart';
import '../../../data/models/monitoring_balita_item.dart';
import '../../../data/models/pertumbuhan_model.dart';

/// Gabungkan data balita, pertumbuhan terakhir, dan jadwal imunisasi jadi
/// daftar MonitoringBalitaItem, diurutkan: perlu perhatian dulu, lalu
/// alfabetis. Fungsi murni (tanpa akses network) agar mudah dites.
List<MonitoringBalitaItem> gabungkanMonitoringBalita({
  required List<BalitaModel> semuaBalita,
  required Map<String, PertumbuhanModel> pertumbuhanTerakhir,
  required List<JadwalImunisasiModel> semuaJadwal,
  required DateTime sekarang,
}) {
  final awalBulan = DateTime(sekarang.year, sekarang.month, 1);
  final balitaDisetujui = semuaBalita
      .where((b) => b.statusVerifikasi == 'disetujui')
      .toList();

  final items = balitaDisetujui.map((balita) {
    final pertumbuhan = pertumbuhanTerakhir[balita.id];
    final jumlahTerlambat = semuaJadwal
        .where((j) => j.balitaId == balita.id && j.status == 'terlambat')
        .length;
    final belumDiperiksaBulanIni = pertumbuhan == null ||
        pertumbuhan.tanggalPemeriksaan.isBefore(awalBulan);
    final bermasalah = GrowthStatusHelper.isBermasalah(pertumbuhan?.statusGizi);

    return MonitoringBalitaItem(
      balita: balita,
      pertumbuhanTerakhir: pertumbuhan,
      usiaBulan: AgeCalculator.hitungUsiaBulan(balita.tanggalLahir, sekarang),
      jumlahImunisasiTerlambat: jumlahTerlambat,
      belumDiperiksaBulanIni: belumDiperiksaBulanIni,
      perluPerhatian: bermasalah || jumlahTerlambat > 0 || belumDiperiksaBulanIni,
    );
  }).toList();

  items.sort((a, b) {
    if (a.perluPerhatian != b.perluPerhatian) {
      return a.perluPerhatian ? -1 : 1;
    }
    return a.balita.nama.toLowerCase().compareTo(b.balita.nama.toLowerCase());
  });

  return items;
}
