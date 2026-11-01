import 'package:flutter/material.dart';

import '../../../data/models/balita_model.dart';
import '../../../data/models/jadwal_imunisasi_model.dart';
import '../../../data/models/monitoring_balita_item.dart';
import '../../../data/models/pertumbuhan_model.dart';
import '../../../data/repositories/balita_repository.dart';
import '../../../data/repositories/jadwal_imunisasi_repository.dart';
import '../../../data/repositories/pertumbuhan_repository.dart';
import 'monitoring_balita_merger.dart';

class MonitoringBalitaProvider extends ChangeNotifier {
  final _balitaRepo = BalitaRepository();
  final _pertumbuhanRepo = PertumbuhanRepository();
  final _jadwalRepo = JadwalImunisasiRepository();

  List<MonitoringBalitaItem> _daftar = [];
  bool _isLoading = false;
  String? _error;

  List<MonitoringBalitaItem> get daftar => _daftar;
  int get jumlahPerluPerhatian => _daftar.where((i) => i.perluPerhatian).length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> muatData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final List<BalitaModel> semuaBalita = await _balitaRepo.getDaftarBalita();
      final Map<String, PertumbuhanModel> pertumbuhanTerakhir =
          await _pertumbuhanRepo.getSemuaTerakhir();
      final List<JadwalImunisasiModel> semuaJadwal =
          await _jadwalRepo.getSemua();
      _daftar = gabungkanMonitoringBalita(
        semuaBalita: semuaBalita,
        pertumbuhanTerakhir: pertumbuhanTerakhir,
        semuaJadwal: semuaJadwal,
        sekarang: DateTime.now(),
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
