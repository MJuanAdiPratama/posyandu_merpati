import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/jadwal_posyandu_model.dart';

class JadwalPosyanduRepository {
  final _client = SupabaseService.client;
  RealtimeChannel? _channel;

  Future<List<JadwalPosyanduModel>> getDaftar() async {
    final data = await _client
        .from('jadwal_posyandu')
        .select()
        .order('tanggal', ascending: true);
    return (data as List).map((e) => JadwalPosyanduModel.fromJson(e)).toList();
  }

  Future<JadwalPosyanduModel?> getTerdekat() async {
    final today = _dateOnly(DateTime.now());
    final daftar = await getDaftar();
    for (final jadwal in daftar) {
      if (!_dateOnly(jadwal.tanggal).isBefore(today)) {
        return jadwal;
      }
    }
    return null;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<JadwalPosyanduModel> tambah(JadwalPosyanduModel jadwal) async {
    final data = await _client
        .from('jadwal_posyandu')
        .insert(jadwal.toJson())
        .select()
        .single();
    return JadwalPosyanduModel.fromJson(data);
  }

  Future<JadwalPosyanduModel> update(
    String id,
    Map<String, dynamic> data,
  ) async {
    final result = await _client
        .from('jadwal_posyandu')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return JadwalPosyanduModel.fromJson(result);
  }

  Future<void> hapus(String id) async {
    await _client.from('jadwal_posyandu').delete().eq('id', id);
  }

  // Klaim atomik sebelum kirim reminder H-1: hanya berhasil (true) jika
  // baris ini belum pernah diklaim, mencegah reminder terkirim dobel saat
  // beberapa device mengecek bersamaan.
  Future<bool> klaimReminder(String id) async {
    final data = await _client
        .from('jadwal_posyandu')
        .update({'reminder_terkirim': true})
        .eq('id', id)
        .eq('reminder_terkirim', false)
        .select('id');
    return (data as List).isNotEmpty;
  }

  void subscribeRealtime(void Function() onChange) {
    _channel?.unsubscribe();
    _channel = _client
        .channel('jadwal_posyandu_all')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'jadwal_posyandu',
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  void unsubscribeRealtime() {
    _channel?.unsubscribe();
    _channel = null;
  }
}
