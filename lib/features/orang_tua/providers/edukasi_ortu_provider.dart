import 'package:flutter/material.dart';
import '../../../data/models/edukasi_model.dart';
import '../../../data/repositories/edukasi_repository.dart';

class EdukasiOrtuProvider extends ChangeNotifier {
  final _repo = EdukasiRepository();

  List<EdukasiModel> _daftar = [];
  EdukasiModel? _selected;
  bool _isLoading = false;
  String? _filterKategori;
  String _searchQuery = '';

  String get searchQuery => _searchQuery;

  List<EdukasiModel> get daftar {
    var list = _filterKategori == null
        ? _daftar
        : _daftar.where((e) => e.kategori == _filterKategori).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((e) =>
              e.judul.toLowerCase().contains(q) ||
              (e.kategori?.toLowerCase().contains(q) ?? false) ||
              e.isi.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  List<EdukasiModel> get semuaDaftar => _daftar;
  EdukasiModel? get selected => _selected;
  bool get isLoading => _isLoading;
  String? get filterKategori => _filterKategori;

  List<String> get kategoriList =>
      _daftar
          .map((e) => e.kategori)
          .where((k) => k != null && k.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList()
        ..sort();

  void setFilter(String? kategori) {
    _filterKategori = kategori;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> muatDaftar() async {
    _setLoading(true);
    try {
      _daftar = await _repo.getDaftar();
    } catch (_) {
    } finally {
      _setLoading(false);
    }
  }

  void pilih(EdukasiModel edukasi) {
    _selected = edukasi;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
