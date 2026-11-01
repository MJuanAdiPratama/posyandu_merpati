import 'package:flutter/material.dart';
import '../../../data/models/jadwal_imunisasi_model.dart';
import '../../../data/repositories/jadwal_imunisasi_repository.dart';

class JadwalImunisasiKaderProvider extends ChangeNotifier {
  final _repo = JadwalImunisasiRepository();

  List<JadwalImunisasiModel> _daftar = [];
  List<JadwalImunisasiModel> _jadwalHariIni = [];
  List<JadwalImunisasiModel> _jadwalTersedia = [];
  List<JadwalImunisasiModel> _semuaJadwal = [];
  bool _isLoading = false;
  bool _isLoadingTersedia = false;
  bool _isLoadingSemua = false;
  String? _error;
  String? _errorSemua;

  List<JadwalImunisasiModel> get daftar => _daftar;
  List<JadwalImunisasiModel> get jadwalHariIni => _jadwalHariIni;
  List<JadwalImunisasiModel> get jadwalTersedia => _jadwalTersedia;
  List<JadwalImunisasiModel> get semuaJadwal => _semuaJadwal;
  bool get isLoading => _isLoading;
  bool get isLoadingTersedia => _isLoadingTersedia;
  bool get isLoadingSemua => _isLoadingSemua;
  String? get error => _error;
  String? get errorSemua => _errorSemua;

  // Jadwal imunisasi seluruh balita (untuk halaman Jadwal Imunisasi global kader)
  Future<void> muatSemuaJadwal() async {
    _isLoadingSemua = true;
    notifyListeners();
    try {
      _semuaJadwal = await _repo.getSemua();
      _errorSemua = null;
    } catch (e) {
      _errorSemua = e.toString();
    } finally {
      _isLoadingSemua = false;
      notifyListeners();
    }
  }

  // Jadwal belum selesai dengan tanggal <= hari ini (bisa langsung diinput)
  List<JadwalImunisasiModel> get jadwalBisaInput {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return _jadwalTersedia
        .where(
          (j) =>
              j.status != 'selesai' &&
              !DateTime(
                j.tanggalJadwal.year,
                j.tanggalJadwal.month,
                j.tanggalJadwal.day,
              ).isAfter(today),
        )
        .toList();
  }

  // Set jenis_imunisasi_id dari SEMUA jadwal (termasuk selesai) untuk exclude di dialog
  Set<String> get jenisIdsTersedia => _jadwalTersedia
      .where((j) => j.jenisImunisasiId != null)
      .map((j) => j.jenisImunisasiId!)
      .toSet();

  List<JadwalImunisasiModel> get belumSelesai =>
      _daftar.where((j) => j.status != 'selesai').toList();

  Future<void> muatTersediaByBalita(String balitaId) async {
    _isLoadingTersedia = true;
    notifyListeners();
    try {
      // Load semua jadwal agar selesai pun ikut masuk ke jenisIdsTersedia
      _jadwalTersedia = await _repo.getByBalita(balitaId);
    } catch (_) {
      _jadwalTersedia = [];
    } finally {
      _isLoadingTersedia = false;
      notifyListeners();
    }
  }

  Future<JadwalImunisasiModel?> tambahJadwalCepat(
    String balitaId,
    String jenisImunisasiId,
    DateTime tanggal,
  ) async {
    try {
      final jadwal = JadwalImunisasiModel(
        id: '',
        balitaId: balitaId,
        jenisImunisasiId: jenisImunisasiId,
        tanggalJadwal: tanggal,
        status: 'terjadwal',
        createdAt: DateTime.now(),
      );
      final saved = await _repo.tambah(jadwal);
      _jadwalTersedia.add(saved);
      _jadwalTersedia.sort(
        (a, b) => a.tanggalJadwal.compareTo(b.tanggalJadwal),
      );
      if (_daftar.isNotEmpty) {
        _daftar.add(saved);
        _daftar.sort((a, b) => a.tanggalJadwal.compareTo(b.tanggalJadwal));
      }
      _error = null;
      notifyListeners();
      return saved;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> muatHariIniByBalita(String balitaId) async {
    try {
      _jadwalHariIni = await _repo.getHariIniByBalita(balitaId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> muat(String balitaId) async {
    _setLoading(true);
    try {
      _daftar = await _repo.getByBalita(balitaId);
      _daftar.sort((a, b) => a.tanggalJadwal.compareTo(b.tanggalJadwal));
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void tandaiSelesai(String jadwalId) {
    final idx = _daftar.indexWhere((j) => j.id == jadwalId);
    if (idx != -1) {
      _daftar[idx] = JadwalImunisasiModel(
        id: _daftar[idx].id,
        balitaId: _daftar[idx].balitaId,
        jenisImunisasiId: _daftar[idx].jenisImunisasiId,
        tanggalJadwal: _daftar[idx].tanggalJadwal,
        status: 'selesai',
        createdAt: _daftar[idx].createdAt,
        namaImunisasi: _daftar[idx].namaImunisasi,
        usiaBulanImunisasi: _daftar[idx].usiaBulanImunisasi,
        namaBalita: _daftar[idx].namaBalita,
      );
      notifyListeners();
    }
  }

  Future<bool> ubahTanggal(String id, DateTime tanggalBaru) async {
    _setLoading(true);
    try {
      final updated = await _repo.updateTanggal(id, tanggalBaru);
      final idx = _daftar.indexWhere((j) => j.id == id);
      if (idx != -1) _daftar[idx] = updated;
      _daftar.sort((a, b) => a.tanggalJadwal.compareTo(b.tanggalJadwal));
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
      _daftar.removeWhere((j) => j.id == id);
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
