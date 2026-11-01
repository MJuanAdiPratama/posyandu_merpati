import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/jadwal_imunisasi_model.dart';

class JadwalImunisasiRepository {
  final _client = SupabaseService.client;
  RealtimeChannel? _channel;

  // Update semua jadwal 'terjadwal' yang tanggalnya sudah lewat ke 'terlambat'
  Future<void> updateStatusTerlambat(String balitaId) async {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await _client
        .from('jadwal_imunisasi')
        .update({'status': 'terlambat'})
        .eq('balita_id', balitaId)
        .eq('status', 'terjadwal')
        .lt('tanggal_jadwal', today);
  }

  Future<List<JadwalImunisasiModel>> getByBalita(String balitaId) async {
    try {
      await updateStatusTerlambat(balitaId);
    } catch (_) {}
    final data = await _client
        .from('jadwal_imunisasi')
        .select('*, jenis_imunisasi(nama_imunisasi, usia_bulan), balita(nama)')
        .eq('balita_id', balitaId)
        .order('tanggal_jadwal');
    return (data as List).map((e) => JadwalImunisasiModel.fromJson(e)).toList();
  }

  Future<JadwalImunisasiModel> tambah(JadwalImunisasiModel jadwal) async {
    final data = await _client
        .from('jadwal_imunisasi')
        .insert(jadwal.toJson())
        .select('*, jenis_imunisasi(nama_imunisasi, usia_bulan)')
        .single();
    return JadwalImunisasiModel.fromJson(data);
  }

  Future<JadwalImunisasiModel> updateStatus(String id, String status) async {
    final data = await _client
        .from('jadwal_imunisasi')
        .update({'status': status})
        .eq('id', id)
        .select('*, jenis_imunisasi(nama_imunisasi, usia_bulan)')
        .single();
    return JadwalImunisasiModel.fromJson(data);
  }

  Future<JadwalImunisasiModel> updateTanggal(
    String id,
    DateTime tanggalBaru,
  ) async {
    final tgl =
        '${tanggalBaru.year}-${tanggalBaru.month.toString().padLeft(2, '0')}-${tanggalBaru.day.toString().padLeft(2, '0')}';
    final data = await _client
        .from('jadwal_imunisasi')
        .update({
          'tanggal_jadwal': tgl,
          // Reset agar jadwal yang sudah lewat/dijadwalkan ulang kembali
          // dianggap aktif dan reminder H-1 terkirim lagi untuk tanggal baru.
          'status': 'terjadwal',
          'reminder_terkirim': false,
        })
        .eq('id', id)
        .select('*, jenis_imunisasi(nama_imunisasi, usia_bulan), balita(nama)')
        .single();
    return JadwalImunisasiModel.fromJson(data);
  }

  Future<void> hapus(String id) async {
    await _client.from('jadwal_imunisasi').delete().eq('id', id);
  }

  // Klaim atomik sebelum kirim reminder H-1: hanya berhasil (true) jika
  // baris ini belum pernah diklaim, mencegah reminder terkirim dobel saat
  // beberapa device mengecek bersamaan.
  Future<bool> klaimReminder(String id) async {
    final data = await _client
        .from('jadwal_imunisasi')
        .update({'reminder_terkirim': true})
        .eq('id', id)
        .eq('reminder_terkirim', false)
        .select('id');
    return (data as List).isNotEmpty;
  }

  Future<void> tambahBatch(List<JadwalImunisasiModel> jadwalList) async {
    if (jadwalList.isEmpty) return;
    final records = jadwalList.map((j) => j.toJson()).toList();
    await _client.from('jadwal_imunisasi').insert(records);
  }

  // Jadwal imunisasi seluruh balita (untuk halaman Jadwal Imunisasi global kader)
  Future<List<JadwalImunisasiModel>> getSemua() async {
    final data = await _client
        .from('jadwal_imunisasi')
        .select(
          '*, jenis_imunisasi(nama_imunisasi, usia_bulan), '
          'balita(nama, jenis_kelamin, tanggal_lahir)',
        )
        .order('tanggal_jadwal');
    return (data as List).map((e) => JadwalImunisasiModel.fromJson(e)).toList();
  }

  Future<List<JadwalImunisasiModel>> getHariIniSemua() async {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final data = await _client
        .from('jadwal_imunisasi')
        .select('*, jenis_imunisasi(nama_imunisasi, usia_bulan), balita(nama)')
        .eq('tanggal_jadwal', today)
        .eq('status', 'terjadwal');
    return (data as List).map((e) => JadwalImunisasiModel.fromJson(e)).toList();
  }

  Future<List<JadwalImunisasiModel>> getHariIniByBalita(String balitaId) async {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final data = await _client
        .from('jadwal_imunisasi')
        .select('*, jenis_imunisasi(nama_imunisasi, usia_bulan), balita(nama)')
        .eq('balita_id', balitaId)
        .eq('tanggal_jadwal', today)
        .eq('status', 'terjadwal');
    return (data as List).map((e) => JadwalImunisasiModel.fromJson(e)).toList();
  }

  Future<List<JadwalImunisasiModel>> getBelumSelesaiByBalita(
    String balitaId,
  ) async {
    final data = await _client
        .from('jadwal_imunisasi')
        .select('*, jenis_imunisasi(nama_imunisasi, usia_bulan), balita(nama)')
        .eq('balita_id', balitaId)
        .inFilter('status', ['terjadwal', 'terlambat'])
        .order('tanggal_jadwal');
    return (data as List).map((e) => JadwalImunisasiModel.fromJson(e)).toList();
  }

  Future<bool> sudahAdaJadwal(String balitaId) async {
    final data = await _client
        .from('jadwal_imunisasi')
        .select('id')
        .eq('balita_id', balitaId)
        .limit(1);
    return (data as List).isNotEmpty;
  }

  void subscribeRealtime(String balitaId, void Function() onChange) {
    _channel?.unsubscribe();
    _channel = _client
        .channel('jadwal_imunisasi_$balitaId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'jadwal_imunisasi',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'balita_id',
            value: balitaId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  void unsubscribeRealtime() {
    _channel?.unsubscribe();
    _channel = null;
  }
}
