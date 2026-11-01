import 'package:flutter/material.dart';
import '../../../data/models/jadwal_posyandu_model.dart';
import '../../../data/repositories/jadwal_posyandu_repository.dart';

class AgendaPosyanduProvider extends ChangeNotifier {
  final _repo = JadwalPosyanduRepository();

  List<JadwalPosyanduModel> _daftar = [];
  bool _isLoading = false;
  bool _subscribed = false;
  bool _initialized = false;
  String? _error;

  List<JadwalPosyanduModel> get daftar => _daftar;
  bool get isLoading => _isLoading;
  bool get isInitialized => _initialized;
  String? get error => _error;

  List<JadwalPosyanduModel> get mendatang {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _daftar.where((j) => !j.tanggal.isBefore(today)).toList()
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));
  }

  List<JadwalPosyanduModel> get lewat {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _daftar.where((j) => j.tanggal.isBefore(today)).toList()
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
  }

  JadwalPosyanduModel? get terdekat =>
      mendatang.isNotEmpty ? mendatang.first : null;

  Future<void> muatDaftar() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _daftar = await _repo.getDaftar();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _initialized = true;
      notifyListeners();
    }
    if (!_subscribed) {
      _subscribed = true;
      _repo.subscribeRealtime(muatDaftar);
    }
  }

  @override
  void dispose() {
    _repo.unsubscribeRealtime();
    super.dispose();
  }
}
