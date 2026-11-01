import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/models/edukasi_kategori_model.dart';
import '../../../data/models/edukasi_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/edukasi_repository.dart';
import '../../../data/repositories/notification_repository.dart';

class EdukasiKaderProvider extends ChangeNotifier {
  final _repo = EdukasiRepository();
  final _authRepo = AuthRepository();
  final _notifRepo = NotificationRepository();
  static const List<String> kategoriFallback = [
    'Gizi',
    'Imunisasi',
    'Tumbuh Kembang',
    'Kesehatan',
    'Pengasuhan',
  ];

  List<EdukasiModel> _daftar = [];
  List<EdukasiKategoriModel> _kategori = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  String get searchQuery => _searchQuery;

  List<EdukasiModel> get semuaDaftar => _daftar;

  List<EdukasiModel> get daftar {
    var list = _daftar;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((e) =>
              e.judul.toLowerCase().contains(q) ||
              (e.kategori?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return list;
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<EdukasiKategoriModel> get kategori => _kategori;
  List<String> get pilihanKategori {
    final names = _kategori
        .map((e) => e.nama.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (names.isEmpty) return kategoriFallback;
    return names;
  }

  bool _isUploadingGambar = false;

  bool get isLoading => _isLoading;
  bool get isUploadingGambar => _isUploadingGambar;
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

  Future<void> muatKategori() async {
    try {
      _kategori = await _repo.getKategori();
      _error = null;
    } catch (_) {
      _kategori = [];
    } finally {
      notifyListeners();
    }
  }

  Future<String?> uploadGambar(String filePath) async {
    _isUploadingGambar = true;
    notifyListeners();
    try {
      final url = await _repo.uploadGambar(filePath);
      _error = null;
      return url;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isUploadingGambar = false;
      notifyListeners();
    }
  }

  Future<bool> tambah({
    required String judul,
    required String isi,
    String? ringkasan,
    String? kategoriId,
    String? kategori,
    String? gambarUrl,
  }) async {
    _setLoading(true);
    try {
      final edukasi = EdukasiModel(
        id: '',
        judul: judul,
        isi: isi,
        ringkasan: ringkasan,
        kategoriId: kategoriId,
        kategori: kategori,
        gambarUrl: gambarUrl,
        createdBy: SupabaseService.currentUserId,
        createdAt: DateTime.now(),
      );
      final baru = await _repo.tambah(edukasi);
      _daftar.insert(0, baru);
      _error = null;
      _kirimNotifikasiEdukasi(baru);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _kirimNotifikasiEdukasi(EdukasiModel edukasi) async {
    try {
      final daftarOrtu = await _authRepo.getDaftarOrtu();
      final ortuIds = daftarOrtu.map((o) => o.id).toList();
      if (ortuIds.isEmpty) return;
      await _notifRepo.buatNotifikasiMassal(
        userIds: ortuIds,
        title: 'Artikel Edukasi Baru',
        message: edukasi.judul,
        type: 'pengumuman',
      );
    } catch (_) {
      // Gagal kirim notifikasi tidak menggagalkan simpan artikel
    }
  }

  Future<bool> update(
    String id,
    String judul,
    String isi,
    String? kategoriId,
    String? kategori, {
    String? ringkasan,
    String? gambarUrl,
    bool hapusGambar = false,
    String? gambarUrlLama,
  }) async {
    _setLoading(true);
    try {
      final payload = <String, dynamic>{
        'judul': judul,
        'isi': isi,
        'ringkasan': ringkasan,
        'kategori': kategori,
      };
      if (kategoriId != null) payload['kategori_id'] = kategoriId;
      if (gambarUrl != null) payload['gambar_url'] = gambarUrl;
      if (hapusGambar) payload['gambar_url'] = null;

      final updated = await _repo.update(id, payload);

      // Hapus gambar lama dari storage jika diganti atau dihapus
      if (gambarUrlLama != null && (gambarUrl != null || hapusGambar)) {
        await _repo.hapusGambar(gambarUrlLama);
      }

      final idx = _daftar.indexWhere((e) => e.id == id);
      if (idx != -1) _daftar[idx] = updated;
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
      _daftar.removeWhere((e) => e.id == id);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> tambahKategori(String nama, String? deskripsi) async {
    try {
      final kat = EdukasiKategoriModel(
        id: '',
        nama: nama,
        deskripsi: deskripsi?.isEmpty == true ? null : deskripsi,
        createdAt: DateTime.now(),
      );
      final baru = await _repo.tambahKategori(kat);
      _kategori
        ..add(baru)
        ..sort((a, b) => a.nama.compareTo(b.nama));
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateKategori(String id, String nama, String? deskripsi) async {
    try {
      final updated = await _repo.updateKategori(id, {
        'nama': nama,
        'deskripsi': deskripsi?.isEmpty == true ? null : deskripsi,
      });
      final idx = _kategori.indexWhere((k) => k.id == id);
      if (idx != -1) _kategori[idx] = updated;
      _kategori.sort((a, b) => a.nama.compareTo(b.nama));
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> hapusKategori(String id) async {
    try {
      await _repo.hapusKategori(id);
      _kategori.removeWhere((k) => k.id == id);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
