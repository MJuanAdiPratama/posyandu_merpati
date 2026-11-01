import 'package:flutter/material.dart';
import '../../../data/models/balita_model.dart';
import '../../../data/models/jadwal_imunisasi_model.dart';
import '../../../data/models/jenis_imunisasi_model.dart';
import '../../../data/repositories/jadwal_imunisasi_repository.dart';
import '../../../data/repositories/jenis_imunisasi_repository.dart';

class JadwalDraftItem {
  final JenisImunisasiModel jenisImunisasi;
  final DateTime tanggalJadwal;
  final String status;
  bool dipilih;

  JadwalDraftItem({
    required this.jenisImunisasi,
    required this.tanggalJadwal,
    required this.status,
    this.dipilih = true,
  });
}

class GenerateJadwalProvider extends ChangeNotifier {
  final _jenisRepo = JenisImunisasiRepository();
  final _jadwalRepo = JadwalImunisasiRepository();

  List<JadwalDraftItem> _daftar = [];
  bool _isLoading = false;
  String? _error;

  List<JadwalDraftItem> get daftar => _daftar;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get jumlahDipilih => _daftar.where((j) => j.dipilih).length;
  bool get semuaDipilih =>
      _daftar.isNotEmpty && _daftar.every((j) => j.dipilih);

  Future<void> muatDraft(BalitaModel balita) async {
    _setLoading(true);
    try {
      final jenisList = await _jenisRepo.getDaftar();
      final now = DateTime.now();

      _daftar = jenisList.map((jenisImunisasi) {
        final tanggalJadwal = DateTime(
          balita.tanggalLahir.year,
          balita.tanggalLahir.month + jenisImunisasi.usiaBulan,
          balita.tanggalLahir.day,
        );
        final status = tanggalJadwal.isBefore(now) ? 'terlambat' : 'terjadwal';
        return JadwalDraftItem(
          jenisImunisasi: jenisImunisasi,
          tanggalJadwal: tanggalJadwal,
          status: status,
        );
      }).toList();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void toggle(int index) {
    _daftar[index].dipilih = !_daftar[index].dipilih;
    notifyListeners();
  }

  void toggleSemua(bool value) {
    for (final item in _daftar) {
      item.dipilih = value;
    }
    notifyListeners();
  }

  Future<bool> simpan(String balitaId) async {
    _setLoading(true);
    try {
      final terpilih = _daftar.where((j) => j.dipilih).toList();
      final now = DateTime.now();

      final jadwalList = terpilih
          .map(
            (item) => JadwalImunisasiModel(
              id: '',
              balitaId: balitaId,
              jenisImunisasiId: item.jenisImunisasi.id,
              tanggalJadwal: item.tanggalJadwal,
              status: item.status,
              createdAt: now,
            ),
          )
          .toList();

      await _jadwalRepo.tambahBatch(jadwalList);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
