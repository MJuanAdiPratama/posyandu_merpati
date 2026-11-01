import 'package:flutter/material.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/manajemen_pengguna_repository.dart';

class ManajemenPenggunaProvider extends ChangeNotifier {
  final _repo = ManajemenPenggunaRepository();

  List<ProfileModel> _daftarPengguna = [];
  bool _isLoading = false;
  String? _error;
  String _filterRole = 'semua';

  List<ProfileModel> get daftarPengguna => _daftarPengguna;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterRole => _filterRole;

  Future<void> muat() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final role = _filterRole == 'semua' ? null : _filterRole;
      _daftarPengguna = await _repo.getDaftarPengguna(filterRole: role);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilterRole(String role) {
    _filterRole = role;
    muat();
  }

  Future<bool> toggleStatusAktif(ProfileModel pengguna) async {
    try {
      final statusBaru = !pengguna.isActive;
      await _repo.updateStatusAktif(pengguna.id, statusBaru);
      final idx = _daftarPengguna.indexWhere((p) => p.id == pengguna.id);
      if (idx != -1) {
        _daftarPengguna[idx] = pengguna.copyWith(isActive: statusBaru);
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> ubahRole(ProfileModel pengguna, String roleBaru) async {
    try {
      await _repo.updateRole(pengguna.id, roleBaru);
      final idx = _daftarPengguna.indexWhere((p) => p.id == pengguna.id);
      if (idx != -1) {
        _daftarPengguna[idx] = pengguna.copyWith(role: roleBaru);
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
