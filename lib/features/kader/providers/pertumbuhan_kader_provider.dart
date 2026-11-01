import 'package:flutter/material.dart';
import '../../../data/models/pertumbuhan_model.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/pertumbuhan_repository.dart';

class PertumbuhanKaderProvider extends ChangeNotifier {
  final _repo = PertumbuhanRepository();
  final _notifRepo = NotificationRepository();

  List<PertumbuhanModel> _daftar = [];
  bool _isLoading = false;
  String? _error;

  List<PertumbuhanModel> get daftar => _daftar;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> muatByBalita(String balitaId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _daftar = await _repo.getByBalita(balitaId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> update(
    String id, {
    required DateTime tanggalPemeriksaan,
    required int usiaBulan,
    required double beratBadan,
    required double tinggiBadan,
    String? statusGizi,
    String? statusTinggiBadan,
    String? statusBeratBadan,
    String? catatan,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _repo.update(
        id,
        tanggalPemeriksaan: tanggalPemeriksaan,
        usiaBulan: usiaBulan,
        beratBadan: beratBadan,
        tinggiBadan: tinggiBadan,
        statusGizi: statusGizi,
        statusTinggiBadan: statusTinggiBadan,
        statusBeratBadan: statusBeratBadan,
        catatan: catatan,
      );
      final idx = _daftar.indexWhere((p) => p.id == id);
      if (idx != -1) _daftar[idx] = updated;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> hapus(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.hapus(id);
      _daftar.removeWhere((p) => p.id == id);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> simpan(
    PertumbuhanModel pertumbuhan, {
    String? parentId,
    String? namaBalita,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _repo.tambah(pertumbuhan);
      _daftar.add(saved);
      _daftar.sort(
        (a, b) => a.tanggalPemeriksaan.compareTo(b.tanggalPemeriksaan),
      );

      if (parentId != null) {
        try {
          final tgl = pertumbuhan.tanggalPemeriksaan;
          final nama = namaBalita ?? 'Balita';
          final status = pertumbuhan.statusGizi != null
              ? ' Status gizi: ${pertumbuhan.statusGizi}.'
              : '';
          await _notifRepo.buatNotifikasi(
            userId: parentId,
            balitaId: pertumbuhan.balitaId,
            title: 'Hasil Pemeriksaan Pertumbuhan',
            message:
                'Data pertumbuhan $nama pada ${tgl.day}/${tgl.month}/${tgl.year} telah dicatat.$status',
            type: 'pertumbuhan',
          );
        } catch (_) {
          // Notifikasi gagal tidak membatalkan penyimpanan
        }
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
