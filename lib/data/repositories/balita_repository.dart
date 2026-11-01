import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/balita_model.dart';

class BalitaRepository {
  final _client = SupabaseService.client;
  RealtimeChannel? _channel;

  /// Ambil daftar unik nama orang tua dari tabel balita (paling terbaru per nama).
  Future<List<Map<String, String?>>> getDaftarOrtuRiwayat() async {
    final data = await _client
        .from('balita')
        .select('nama_ortu, kontak_ortu, alamat')
        .not('nama_ortu', 'is', null)
        .order('created_at', ascending: false);
    final seen = <String>{};
    final result = <Map<String, String?>>[];
    for (final row in data as List) {
      final nama = (row['nama_ortu'] as String?)?.trim() ?? '';
      if (nama.isEmpty || seen.contains(nama.toLowerCase())) continue;
      seen.add(nama.toLowerCase());
      result.add({
        'nama': nama,
        'no_hp': row['kontak_ortu'] as String?,
        'alamat': row['alamat'] as String?,
      });
    }
    result.sort((a, b) => (a['nama'] ?? '').compareTo(b['nama'] ?? ''));
    return result;
  }

  Future<List<BalitaModel>> getDaftarBalita() async {
    final data = await _client
        .from('balita')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => BalitaModel.fromJson(e)).toList();
  }

  Future<List<BalitaModel>> getBalitaByParent(String parentId) async {
    final data = await _client
        .from('balita')
        .select()
        .eq('parent_id', parentId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => BalitaModel.fromJson(e)).toList();
  }

  Future<List<BalitaModel>> getBalitaPending() async {
    final data = await _client
        .from('balita')
        .select()
        .eq('status_verifikasi', 'pending')
        .order('created_at', ascending: false);
    return (data as List).map((e) => BalitaModel.fromJson(e)).toList();
  }

  Future<BalitaModel> getDetailBalita(String id) async {
    final data = await _client.from('balita').select().eq('id', id).single();
    return BalitaModel.fromJson(data);
  }

  Future<BalitaModel> tambahBalita(BalitaModel balita) async {
    final data = await _client
        .from('balita')
        .insert(balita.toJson())
        .select()
        .single();
    return BalitaModel.fromJson(data);
  }

  Future<BalitaModel> updateBalita(String id, Map<String, dynamic> data) async {
    final result = await _client
        .from('balita')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return BalitaModel.fromJson(result);
  }

  Future<void> hapusBalita(String id) async {
    await _client.from('balita').delete().eq('id', id);
  }

  Future<BalitaModel> verifikasiBalita(String id, String status) async {
    final data = await _client
        .from('balita')
        .update({'status_verifikasi': status})
        .eq('id', id)
        .select()
        .single();
    return BalitaModel.fromJson(data);
  }

  Future<int> getTotalBalita() async {
    final data = await _client.from('balita').select('id');
    return (data as List).length;
  }

  // Filter by parent_id untuk ortu, null untuk kader (semua balita)
  void subscribeRealtime({
    String? parentId,
    required void Function() onChange,
  }) {
    _channel?.unsubscribe();
    final channelName = parentId != null ? 'balita_$parentId' : 'balita_all';
    var builder = _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'balita',
          filter: parentId != null
              ? PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'parent_id',
                  value: parentId,
                )
              : null,
          callback: (_) => onChange(),
        );
    _channel = builder.subscribe();
  }

  void unsubscribeRealtime() {
    _channel?.unsubscribe();
    _channel = null;
  }
}
