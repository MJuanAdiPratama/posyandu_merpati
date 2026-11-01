import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/jadwal_posyandu_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/jadwal_posyandu_repository.dart';
import '../../../data/repositories/notification_repository.dart';

class JadwalPosyanduProvider extends ChangeNotifier {
  final _repo = JadwalPosyanduRepository();
  final _authRepo = AuthRepository();
  final _notifRepo = NotificationRepository();

  List<JadwalPosyanduModel> _daftar = [];
  JadwalPosyanduModel? _selected;
  bool _isLoading = false;
  String? _error;
  bool _subscribed = false;

  List<JadwalPosyanduModel> get daftar => _daftar;
  JadwalPosyanduModel? get selected => _selected;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Realtime: data otomatis sinkron tanpa perlu muat ulang manual tiap pindah tab
  void subscribeRealtime() {
    if (_subscribed) return;
    _subscribed = true;
    _repo.subscribeRealtime(muatDaftar);
  }

  void unsubscribe() {
    _repo.unsubscribeRealtime();
    _subscribed = false;
  }

  void pilihJadwal(JadwalPosyanduModel jadwal) {
    _selected = jadwal;
    notifyListeners();
  }

  Future<void> muatDaftar() async {
    _setLoading(true);
    try {
      _daftar = await _repo.getDaftar();
      _error = null;
      await _cekDanKirimReminderH1();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Reminder H-1: kirim notifikasi ke semua orang tua + kader jika ada
  // jadwal posyandu besok yang belum diingatkan. Klaim atomik di repository
  // mencegah reminder yang sama terkirim dobel saat beberapa device/role
  // mengecek hampir bersamaan.
  Future<void> _cekDanKirimReminderH1() async {
    final now = DateTime.now();
    final besok = DateTime(now.year, now.month, now.day + 1);
    final jadwalBesok = _daftar.where((j) {
      final tgl = DateTime(j.tanggal.year, j.tanggal.month, j.tanggal.day);
      return !j.reminderTerkirim && tgl.isAtSameMomentAs(besok);
    });

    for (final jadwal in jadwalBesok) {
      try {
        final klaim = await _repo.klaimReminder(jadwal.id);
        if (!klaim) continue;

        final daftarOrtu = await _authRepo.getDaftarOrtu();
        final kaderIds = await _authRepo.getIdSemuaKader();
        final allIds = {
          ...daftarOrtu.map((o) => o.id),
          ...kaderIds,
        }.toList();
        if (allIds.isEmpty) continue;

        await _notifRepo.buatNotifikasiMassal(
          userIds: allIds,
          title: 'Pengingat Posyandu Besok',
          message:
              '${jadwal.judul} dijadwalkan besok'
              '${jadwal.lokasi != null ? ' di ${jadwal.lokasi}' : ''}.',
          type: 'reminder',
        );
      } catch (_) {
        // Reminder gagal tidak mengganggu pemuatan jadwal
      }
    }
  }

  Future<bool> tambah(JadwalPosyanduModel jadwal) async {
    _setLoading(true);
    try {
      final baru = await _repo.tambah(jadwal);
      _daftar.add(baru);
      _daftar.sort((a, b) => a.tanggal.compareTo(b.tanggal));
      _error = null;
      _kirimNotifikasiJadwal(baru);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _kirimNotifikasiJadwal(JadwalPosyanduModel jadwal) async {
    try {
      final daftarOrtu = await _authRepo.getDaftarOrtu();
      final kaderIds = await _authRepo.getIdSemuaKader();
      final allIds = {
        ...daftarOrtu.map((o) => o.id),
        ...kaderIds,
      }.toList();
      if (allIds.isEmpty) return;
      final tanggalFmt = DateFormat(
        'dd MMMM yyyy',
        'id_ID',
      ).format(jadwal.tanggal);
      await _notifRepo.buatNotifikasiMassal(
        userIds: allIds,
        title: 'Jadwal Posyandu Baru',
        message:
            '${jadwal.judul} — $tanggalFmt'
            '${jadwal.lokasi != null ? ' di ${jadwal.lokasi}' : ''}',
        type: 'pengumuman',
      );
    } catch (_) {
      // Gagal kirim notifikasi tidak menggagalkan simpan jadwal
    }
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final updated = await _repo.update(id, data);
      final idx = _daftar.indexWhere((j) => j.id == id);
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
