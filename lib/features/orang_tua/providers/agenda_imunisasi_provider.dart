import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/models/jadwal_imunisasi_model.dart';
import '../../../data/repositories/jadwal_imunisasi_repository.dart';
import '../../../data/repositories/notification_repository.dart';

class AgendaImunisasiProvider extends ChangeNotifier {
  final _repo = JadwalImunisasiRepository();
  final _notifRepo = NotificationRepository();

  List<JadwalImunisasiModel> _daftar = [];
  bool _isLoading = false;
  String? _subscribedBalitaId;
  int? _lastNotifDay;
  String? _error;

  List<JadwalImunisasiModel> get daftar => _daftar;

  List<JadwalImunisasiModel> get mendatang {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return _daftar
        .where(
          (j) =>
              j.status == 'terjadwal' &&
              !DateTime(
                j.tanggalJadwal.year,
                j.tanggalJadwal.month,
                j.tanggalJadwal.day,
              ).isBefore(today),
        )
        .toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> muatByBalita(String balitaId) async {
    _setLoading(true);
    try {
      _daftar = await _repo.getByBalita(balitaId);
      _error = null;
      await _cekDanNotifHariIni();
      await _cekDanKirimReminderH1();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
    if (_subscribedBalitaId != balitaId) {
      _subscribedBalitaId = balitaId;
      _repo.subscribeRealtime(balitaId, () => muatByBalita(balitaId));
    }
  }

  // Reminder H-1: kirim notifikasi ke orang tua jika ada jadwal imunisasi
  // besok yang belum diingatkan. Klaim atomik di repository mencegah
  // reminder yang sama terkirim dobel.
  Future<void> _cekDanKirimReminderH1() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    final now = DateTime.now();
    final besok = DateTime(now.year, now.month, now.day + 1);
    final jadwalBesok = _daftar.where((j) {
      final tgl = DateTime(
        j.tanggalJadwal.year,
        j.tanggalJadwal.month,
        j.tanggalJadwal.day,
      );
      return j.status == 'terjadwal' &&
          !j.reminderTerkirim &&
          tgl.isAtSameMomentAs(besok);
    });

    for (final jadwal in jadwalBesok) {
      try {
        final klaim = await _repo.klaimReminder(jadwal.id);
        if (!klaim) continue;
        await _notifRepo.buatNotifikasi(
          userId: userId,
          balitaId: jadwal.balitaId,
          title: 'Pengingat Imunisasi Besok',
          message:
              '${jadwal.namaBalita ?? "Balita"} dijadwalkan imunisasi '
              '${jadwal.namaImunisasi ?? ""} besok.',
          type: 'reminder',
        );
      } catch (_) {
        // Reminder gagal tidak mengganggu pemuatan agenda
      }
    }
  }

  Future<void> _cekDanNotifHariIni() async {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final hariIni = _daftar.where((j) {
      final jadwalDate = DateTime(
        j.tanggalJadwal.year,
        j.tanggalJadwal.month,
        j.tanggalJadwal.day,
      );
      return j.status == 'terjadwal' && jadwalDate.isAtSameMomentAs(today);
    }).toList();

    final todayNum = DateTime.now().day;
    if (hariIni.isNotEmpty && _lastNotifDay != todayNum) {
      _lastNotifDay = todayNum;
      for (final jadwal in hariIni) {
        await NotificationService.tampilkanNotifikasi(
          id: jadwal.hashCode.abs() % 9000 + 1000,
          title: 'Jadwal Imunisasi Hari Ini',
          body:
              '${jadwal.namaBalita ?? "Balita"} perlu imunisasi ${jadwal.namaImunisasi ?? ""} hari ini',
        );
      }
    }
  }

  void reset() {
    _repo.unsubscribeRealtime();
    _daftar = [];
    _isLoading = false;
    _subscribedBalitaId = null;
    _lastNotifDay = null;
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
