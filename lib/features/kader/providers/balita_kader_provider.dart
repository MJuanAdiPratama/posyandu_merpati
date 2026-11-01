import 'package:flutter/material.dart';
import '../../../data/models/balita_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/balita_repository.dart';
import '../../../data/repositories/notification_repository.dart';

class BalitaKaderProvider extends ChangeNotifier {
  final _repo = BalitaRepository();
  final _authRepo = AuthRepository();
  final _notifRepo = NotificationRepository();

  List<BalitaModel> _daftar = [];
  List<BalitaModel> _pending = [];
  List<ProfileModel> _daftarOrtu = [];
  List<Map<String, String?>> _ortuRiwayat = [];
  BalitaModel? _selected;
  bool _isLoading = false;
  bool _isLoadingOrtu = false;
  bool _subscribed = false;
  String? _error;
  String? _errorOrtu;

  List<BalitaModel> get daftar => _daftar;
  List<BalitaModel> get pending => _pending;
  List<ProfileModel> get daftarOrtu => _daftarOrtu;
  List<Map<String, String?>> get ortuRiwayat => _ortuRiwayat;
  BalitaModel? get selected => _selected;
  bool get isLoading => _isLoading;
  bool get isLoadingOrtu => _isLoadingOrtu;
  String? get error => _error;
  String? get errorOrtu => _errorOrtu;

  Future<void> muatDaftarOrtu() async {
    _isLoadingOrtu = true;
    _errorOrtu = null;
    notifyListeners();
    try {
      _daftarOrtu = await _authRepo.getDaftarOrtu();
    } catch (e) {
      _errorOrtu = e.toString();
      _daftarOrtu = [];
    } finally {
      _isLoadingOrtu = false;
      notifyListeners();
    }
    // Muat juga riwayat dari tabel balita sebagai pelengkap
    muatOrtuRiwayat();
  }

  Future<void> muatOrtuRiwayat() async {
    try {
      _ortuRiwayat = await _repo.getDaftarOrtuRiwayat();
    } catch (_) {
      _ortuRiwayat = [];
    }
    notifyListeners();
  }

  Future<void> muatDaftar() async {
    _setLoading(true);
    try {
      _daftar = await _repo.getDaftarBalita();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
    if (!_subscribed) {
      _subscribed = true;
      _repo.subscribeRealtime(onChange: muatDaftar);
    }
  }

  Future<void> muatPending() async {
    _setLoading(true);
    try {
      _pending = await _repo.getBalitaPending();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> muatDetail(String id) async {
    _setLoading(true);
    try {
      _selected = await _repo.getDetailBalita(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> tambah(BalitaModel balita) async {
    _setLoading(true);
    try {
      final baru = await _repo.tambahBalita(balita);
      _daftar.insert(0, baru);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final updated = await _repo.updateBalita(id, data);
      final idx = _daftar.indexWhere((b) => b.id == id);
      if (idx != -1) _daftar[idx] = updated;
      _selected = updated;
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
      await _repo.hapusBalita(id);
      _daftar.removeWhere((b) => b.id == id);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifikasi(BalitaModel balita, String status) async {
    _setLoading(true);
    try {
      await _repo.verifikasiBalita(balita.id, status);
      _pending.removeWhere((b) => b.id == balita.id);
      _error = null;

      if (balita.parentId != null) {
        try {
          final disetujui = status == 'disetujui';
          await _notifRepo.buatNotifikasi(
            userId: balita.parentId!,
            balitaId: balita.id,
            title: disetujui ? 'Balita Diverifikasi' : 'Verifikasi Ditolak',
            message: disetujui
                ? '${balita.nama} telah diverifikasi dan dapat menggunakan layanan posyandu.'
                : '${balita.nama} tidak dapat diverifikasi. Silakan hubungi kader untuk informasi lebih lanjut.',
            type: 'verifikasi',
          );
        } catch (_) {
          // Notifikasi gagal tidak membatalkan verifikasi
        }
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void pilihBalita(BalitaModel balita) {
    _selected = balita;
    notifyListeners();
  }

  @override
  void dispose() {
    _repo.unsubscribeRealtime();
    super.dispose();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
