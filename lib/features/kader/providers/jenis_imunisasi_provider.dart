import 'package:flutter/material.dart';
import '../../../data/models/jenis_imunisasi_model.dart';
import '../../../data/repositories/jenis_imunisasi_repository.dart';

class JenisImunisasiProvider extends ChangeNotifier {
  final _repo = JenisImunisasiRepository();

  List<JenisImunisasiModel> _daftar = [];
  bool _isLoading = false;
  String? _error;

  List<JenisImunisasiModel> get daftar => _daftar;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> muatDaftar() async {
    _setLoading(true);
    try {
      _daftar = await _repo.getDaftar();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> tambah(
    String nama,
    int usiaBulan,
    String? deskripsi,
    String? kandungan,
  ) async {
    _setLoading(true);
    try {
      final item = JenisImunisasiModel(
        id: '',
        namaImunisasi: nama,
        usiaBulan: usiaBulan,
        deskripsi: deskripsi,
        kandungan: kandungan,
        createdAt: DateTime.now(),
      );
      final baru = await _repo.tambah(item);
      _daftar.add(baru);
      _daftar.sort((a, b) => a.usiaBulan.compareTo(b.usiaBulan));
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> update(
    String id,
    String nama,
    int usiaBulan,
    String? deskripsi,
    String? kandungan,
  ) async {
    _setLoading(true);
    try {
      await _repo.update(id, {
        'nama_imunisasi': nama,
        'usia_bulan': usiaBulan,
        'deskripsi': deskripsi,
        'kandungan': kandungan,
      });
      final idx = _daftar.indexWhere((m) => m.id == id);
      if (idx != -1) {
        _daftar[idx] = JenisImunisasiModel(
          id: id,
          namaImunisasi: nama,
          usiaBulan: usiaBulan,
          deskripsi: deskripsi,
          kandungan: kandungan,
          createdAt: _daftar[idx].createdAt,
        );
      }
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> hapus(String id) async {
    _setLoading(true);
    try {
      await _repo.hapus(id);
      _daftar.removeWhere((m) => m.id == id);
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
