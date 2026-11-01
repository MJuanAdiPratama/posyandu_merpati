import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/age_calculator.dart';
import '../../../core/utils/growth_status_helper.dart';
import '../../../data/models/balita_model.dart';
import '../../../data/models/imunisasi_model.dart';
import '../../../data/repositories/imunisasi_repository.dart';
import '../../../data/repositories/jadwal_imunisasi_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/pertumbuhan_repository.dart';
import '../../../data/models/pertumbuhan_model.dart';

class ImunisasiProvider extends ChangeNotifier {
  final _repo = ImunisasiRepository();
  final _pertumbuhanRepo = PertumbuhanRepository();
  final _jadwalImunisasiRepo = JadwalImunisasiRepository();
  final _notifRepo = NotificationRepository();

  List<ImunisasiModel> _daftar = [];
  Set<String> _sudahDiberikan = {};
  bool _isLoading = false;
  String? _error;

  List<ImunisasiModel> get daftar => _daftar;
  Set<String> get sudahDiberikan => _sudahDiberikan;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> muatByBalita(String balitaId) async {
    _setLoading(true);
    try {
      _daftar = await _repo.getByBalita(balitaId);
      _sudahDiberikan = await _repo.getJenisIdsSudahDiberikan(balitaId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> muatSudahDiberikan(String balitaId) async {
    try {
      _sudahDiberikan = await _repo.getJenisIdsSudahDiberikan(balitaId);
      notifyListeners();
    } catch (_) {}
  }

  void resetSudahDiberikan() {
    _sudahDiberikan = {};
    notifyListeners();
  }

  Future<bool> simpanImunisasi({
    required BalitaModel balita,
    required String? jenisImunisasiId,
    required DateTime tanggalImunisasi,
    double? beratBadan,
    double? tinggiBadan,
    double? suhuBadan,
    double? lingkarKepala,
    String? catatan,
    String? jadwalId,
  }) async {
    _setLoading(true);
    try {
      if (balita.statusVerifikasi != 'disetujui') {
        _error =
            'Balita belum diverifikasi. Verifikasi data balita terlebih dahulu.';
        return false;
      }

      // Cek duplikat: vaksin yang sama untuk balita yang sama
      if (jenisImunisasiId != null) {
        final sudah = await _repo.getJenisIdsSudahDiberikan(balita.id);
        if (sudah.contains(jenisImunisasiId)) {
          _error = 'Balita ini sudah mendapatkan vaksin tersebut sebelumnya.';
          return false;
        }
      }

      final petugasId = SupabaseService.currentUserId;
      final imunisasi = ImunisasiModel(
        id: '',
        balitaId: balita.id,
        jenisImunisasiId: jenisImunisasiId,
        tanggalImunisasi: tanggalImunisasi,
        beratBadan: beratBadan,
        tinggiBadan: tinggiBadan,
        suhuBadan: suhuBadan,
        lingkarKepala: lingkarKepala,
        catatan: catatan,
        petugasId: petugasId,
        createdAt: DateTime.now(),
      );

      final saved = await _repo.tambah(imunisasi);
      _daftar.insert(0, saved);

      // Simpan pertumbuhan jika BB dan TB diisi
      if (beratBadan != null && tinggiBadan != null) {
        final usiaBulan = AgeCalculator.hitungUsiaBulan(
          balita.tanggalLahir,
          tanggalImunisasi,
        );
        final statusGizi = GrowthStatusHelper.hitungStatusGizi(
          beratBadan: beratBadan,
          tinggiBadan: tinggiBadan,
          usiaBulan: usiaBulan,
          jenisKelamin: balita.jenisKelamin,
        );
        final statusTB = GrowthStatusHelper.hitungStatusTinggiBadan(
          tinggiBadan: tinggiBadan,
          usiaBulan: usiaBulan,
          jenisKelamin: balita.jenisKelamin,
        );
        final statusBB = GrowthStatusHelper.hitungStatusBeratBadan(
          beratBadan: beratBadan,
          usiaBulan: usiaBulan,
          jenisKelamin: balita.jenisKelamin,
        );

        final pertumbuhan = PertumbuhanModel(
          id: '',
          balitaId: balita.id,
          tanggalPemeriksaan: tanggalImunisasi,
          usiaBulan: usiaBulan,
          beratBadan: beratBadan,
          tinggiBadan: tinggiBadan,
          lingkarKepala: lingkarKepala,
          statusGizi: statusGizi,
          statusTinggiBadan: statusTB,
          statusBeratBadan: statusBB,
          catatan: catatan,
          createdAt: DateTime.now(),
        );
        await _pertumbuhanRepo.tambah(pertumbuhan);
      }

      // Tandai jadwal sebagai selesai
      if (jadwalId != null) {
        // Input dari jadwal: tandai jadwal yang dipilih
        await _jadwalImunisasiRepo.updateStatus(jadwalId, 'selesai');
      } else if (jenisImunisasiId != null) {
        // Input standalone: cari jadwal yang matching DAN sudah waktunya
        try {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final semuaJadwal = await _jadwalImunisasiRepo.getByBalita(balita.id);
          final matching = semuaJadwal
              .where(
                (j) =>
                    j.jenisImunisasiId == jenisImunisasiId &&
                    j.status != 'selesai' &&
                    !DateTime(
                      j.tanggalJadwal.year,
                      j.tanggalJadwal.month,
                      j.tanggalJadwal.day,
                    ).isAfter(today),
              )
              .firstOrNull;
          if (matching != null) {
            await _jadwalImunisasiRepo.updateStatus(matching.id, 'selesai');
          }
        } catch (_) {
          // Non-fatal
        }
      }

      // Kirim notifikasi ke orang tua (non-fatal jika gagal karena RLS)
      if (balita.parentId != null) {
        try {
          await _notifRepo.buatNotifikasi(
            userId: balita.parentId!,
            balitaId: balita.id,
            title: 'Hasil Imunisasi',
            message:
                'Imunisasi untuk ${balita.nama} telah dicatat pada ${tanggalImunisasi.day}/${tanggalImunisasi.month}/${tanggalImunisasi.year}.',
            type: 'hasil_imunisasi',
          );
        } catch (_) {
          // Notifikasi gagal tidak membatalkan pencatatan imunisasi
        }
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

  Future<bool> updateImunisasi(
    String id, {
    required DateTime tanggalImunisasi,
    double? beratBadan,
    double? tinggiBadan,
    String? catatan,
  }) async {
    _setLoading(true);
    try {
      final updated = await _repo.update(
        id,
        tanggalImunisasi: tanggalImunisasi,
        beratBadan: beratBadan,
        tinggiBadan: tinggiBadan,
        catatan: catatan,
      );
      final idx = _daftar.indexWhere((i) => i.id == id);
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

  Future<bool> hapusImunisasi(String id) async {
    _setLoading(true);
    try {
      final item = _daftar.firstWhere((i) => i.id == id);
      await _repo.hapus(id);
      _daftar.removeWhere((i) => i.id == id);
      if (item.jenisImunisasiId != null) {
        _sudahDiberikan.remove(item.jenisImunisasiId!);
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

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
