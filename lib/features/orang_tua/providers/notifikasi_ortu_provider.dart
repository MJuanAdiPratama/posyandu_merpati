import 'package:flutter/material.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';

class NotifikasiOrtuProvider extends ChangeNotifier {
  final _repo = NotificationRepository();

  List<NotificationModel> _daftar = [];
  bool _isLoading = false;
  String? _subscribedUserId;

  // ID notifikasi yang sudah dihapus secara lokal.
  // Digunakan untuk memfilter hasil DB jika DELETE gagal silent (misal RLS).
  final Set<String> _idsDihapus = {};

  List<NotificationModel> get daftar => _daftar;
  bool get isLoading => _isLoading;
  int get jumlahBelumDibaca => _daftar.where((n) => !n.isRead).length;

  Future<void> muatNotifikasi(String userId) async {
    _setLoading(true);
    try {
      var loaded = await _repo.getDaftarNotifikasi(userId);
      // Filter notifikasi yang sudah dihapus lokal (antisipasi DELETE gagal di DB)
      if (_idsDihapus.isNotEmpty) {
        loaded = loaded.where((n) => !_idsDihapus.contains(n.id)).toList();
      }
      _daftar = loaded;
    } catch (_) {
      _daftar = [];
    } finally {
      _setLoading(false);
    }
  }

  void subscribeRealtime(String userId) {
    if (_subscribedUserId == userId) return;
    unsubscribe();
    _subscribedUserId = userId;
    _repo.subscribeRealtime(userId, (notif) {
      if (_daftar.any((n) => n.id == notif.id)) return;
      // Notifikasi baru yang benar-benar baru (bukan yang sudah dihapus)
      if (_idsDihapus.contains(notif.id)) return;
      _daftar.insert(0, notif);
      notifyListeners();
    });
  }

  void unsubscribe() {
    _repo.unsubscribeRealtime();
    _subscribedUserId = null;
  }

  void reset() {
    unsubscribe();
    _daftar = [];
    _isLoading = false;
    _idsDihapus.clear();
    notifyListeners();
  }

  Future<void> tandaiDibaca(String id) async {
    await _repo.tandaiDibaca(id);
    final idx = _daftar.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _daftar[idx] = _daftar[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> tandaiSemuaDibaca(String userId) async {
    await _repo.tandaiSemuaDibaca(userId);
    _daftar = _daftar.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  Future<void> hapus(String id) async {
    await _repo.hapusNotifikasi(id);
    _idsDihapus.add(id);
    _daftar.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  Future<void> hapusSemua(String userId) async {
    await _repo.hapusSemuaNotifikasi(userId);
    // Simpan semua ID saat ini agar tidak muncul lagi saat reload DB
    _idsDihapus.addAll(_daftar.map((n) => n.id));
    _daftar.clear();
    notifyListeners();
  }

  void tambahNotifikasi(NotificationModel notif) {
    _daftar.insert(0, notif);
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
