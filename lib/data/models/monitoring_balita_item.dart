import 'balita_model.dart';
import 'pertumbuhan_model.dart';

/// View model gabungan untuk layar Monitoring Balita, dihitung saat runtime
/// dari BalitaModel + data pertumbuhan terakhir + jumlah jadwal imunisasi
/// terlambat. Bukan representasi baris tabel database, sehingga tidak
/// memiliki fromJson/toJson.
class MonitoringBalitaItem {
  final BalitaModel balita;
  final PertumbuhanModel? pertumbuhanTerakhir;
  final int usiaBulan;
  final int jumlahImunisasiTerlambat;
  final bool belumDiperiksaBulanIni;
  final bool perluPerhatian;

  MonitoringBalitaItem({
    required this.balita,
    required this.pertumbuhanTerakhir,
    required this.usiaBulan,
    required this.jumlahImunisasiTerlambat,
    required this.belumDiperiksaBulanIni,
    required this.perluPerhatian,
  });

  String get statusGizi => pertumbuhanTerakhir?.statusGizi ?? 'Belum ada data';
}
