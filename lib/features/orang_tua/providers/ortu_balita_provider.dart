import 'package:flutter/material.dart';
import '../../../data/models/balita_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/balita_repository.dart';
import '../../../data/repositories/notification_repository.dart';

class OrtuBalitaProvider extends ChangeNotifier {
  final _repo = BalitaRepository();
  final _authRepo = AuthRepository();
  final _notifRepo = NotificationRepository();

  List<BalitaModel> _daftar = [];
  BalitaModel? _selected;
  bool _isLoading = false;
  String? _subscribedParentId;
  String? _error;

  List<BalitaModel> get daftar => _daftar;
  BalitaModel? get selected => _selected;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> muatByParent(String parentId) async {
    _setLoading(true);
    try {
      _daftar = await _repo.getBalitaByParent(parentId);
      if (_selected != null) {
        _selected = _daftar.firstWhere(
          (b) => b.id == _selected!.id,
          orElse: () => _daftar.isNotEmpty ? _daftar.first : _selected!,
        );
        if (_daftar.isEmpty) _selected = null;
      } else {
        _selected = _daftar.isNotEmpty ? _daftar.first : null;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
    if (_subscribedParentId != parentId) {
      _subscribedParentId = parentId;
      _repo.subscribeRealtime(
        parentId: parentId,
        onChange: () => muatByParent(parentId),
      );
    }
  }

  Future<bool> daftarBalita(BalitaModel balita) async {
    _setLoading(true);
    try {
      final baru = await _repo.tambahBalita(balita);
      _daftar.insert(0, baru);
      _selected ??= baru;
      _error = null;

      try {
        final kaderIds = await _authRepo.getIdSemuaKader();
        await _notifRepo.buatNotifikasiMassal(
          userIds: kaderIds,
          title: 'Pendaftaran Balita Baru',
          message: '${baru.nama} telah didaftarkan dan menunggu verifikasi.',
          type: 'verifikasi',
        );
      } catch (_) {
        // Notifikasi gagal tidak membatalkan pendaftaran
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

  void reset() {
    _repo.unsubscribeRealtime();
    _daftar = [];
    _selected = null;
    _isLoading = false;
    _subscribedParentId = null;
    _error = null;
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
