import 'package:flutter/material.dart';
import '../../../data/models/jadwal_imunisasi_model.dart';
import '../../../data/models/jadwal_posyandu_model.dart';
import '../../../data/repositories/balita_repository.dart';
import '../../../data/repositories/imunisasi_repository.dart';
import '../../../data/repositories/jadwal_imunisasi_repository.dart';
import '../../../data/repositories/jadwal_posyandu_repository.dart';

class DashboardKaderProvider extends ChangeNotifier {
  final _balitaRepo = BalitaRepository();
  final _imunisasiRepo = ImunisasiRepository();
  final _jadwalRepo = JadwalPosyanduRepository();
  final _jadwalImunisasiRepo = JadwalImunisasiRepository();

  int _totalBalita = 0;
  int _imunisasiBulanIni = 0;
  int _pendingVerifikasi = 0;
  JadwalPosyanduModel? _jadwalTerdekat;
  List<JadwalImunisasiModel> _jadwalImunisasiHariIni = [];
  bool _isLoading = false;

  int get totalBalita => _totalBalita;
  int get imunisasiBulanIni => _imunisasiBulanIni;
  int get pendingVerifikasi => _pendingVerifikasi;
  JadwalPosyanduModel? get jadwalTerdekat => _jadwalTerdekat;
  List<JadwalImunisasiModel> get jadwalImunisasiHariIni =>
      _jadwalImunisasiHariIni;
  bool get isLoading => _isLoading;

  Future<void> muatDashboard() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _balitaRepo.getTotalBalita(),
        _imunisasiRepo.getTotalBulanIni(),
        _balitaRepo.getBalitaPending(),
        _jadwalRepo.getTerdekat(),
        _jadwalImunisasiRepo.getHariIniSemua(),
      ]);
      _totalBalita = results[0] as int;
      _imunisasiBulanIni = results[1] as int;
      _pendingVerifikasi = (results[2] as List).length;
      _jadwalTerdekat = results[3] as JadwalPosyanduModel?;
      _jadwalImunisasiHariIni = results[4] as List<JadwalImunisasiModel>;
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
