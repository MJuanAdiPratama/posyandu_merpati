import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/pertumbuhan_model.dart';

class PertumbuhanRepository {
  final _client = SupabaseService.client;
  RealtimeChannel? _channel;

  Future<List<PertumbuhanModel>> getByBalita(String balitaId) async {
    final data = await _client
        .from('pertumbuhan')
        .select()
        .eq('balita_id', balitaId)
        .order('tanggal_pemeriksaan', ascending: true);
    return (data as List).map((e) => PertumbuhanModel.fromJson(e)).toList();
  }

  Future<PertumbuhanModel> tambah(PertumbuhanModel pertumbuhan) async {
    final data = await _client
        .from('pertumbuhan')
        .insert(pertumbuhan.toJson())
        .select()
        .single();
    return PertumbuhanModel.fromJson(data);
  }

  Future<PertumbuhanModel?> getTerakhir(String balitaId) async {
    final data = await _client
        .from('pertumbuhan')
        .select()
        .eq('balita_id', balitaId)
        .order('tanggal_pemeriksaan', ascending: false)
        .limit(1);
    final list = data as List;
    if (list.isEmpty) return null;
    return PertumbuhanModel.fromJson(list.first);
  }

  /// Ambil data pertumbuhan terbaru untuk setiap balita (untuk layar
  /// Monitoring Balita yang butuh ringkasan seluruh balita sekaligus).
  Future<Map<String, PertumbuhanModel>> getSemuaTerakhir() async {
    final data = await _client
        .from('pertumbuhan')
        .select()
        .order('tanggal_pemeriksaan', ascending: false);
    final hasil = <String, PertumbuhanModel>{};
    for (final row in data as List) {
      final model = PertumbuhanModel.fromJson(row);
      hasil.putIfAbsent(model.balitaId, () => model);
    }
    return hasil;
  }

  Future<PertumbuhanModel> update(
    String id, {
    required DateTime tanggalPemeriksaan,
    required int usiaBulan,
    required double beratBadan,
    required double tinggiBadan,
    String? statusGizi,
    String? statusTinggiBadan,
    String? statusBeratBadan,
    String? catatan,
  }) async {
    final tgl =
        '${tanggalPemeriksaan.year}-${tanggalPemeriksaan.month.toString().padLeft(2, '0')}-${tanggalPemeriksaan.day.toString().padLeft(2, '0')}';
    final data = await _client
        .from('pertumbuhan')
        .update({
          'tanggal_pemeriksaan': tgl,
          'usia_bulan': usiaBulan,
          'berat_badan': beratBadan,
          'tinggi_badan': tinggiBadan,
          'status_gizi': statusGizi,
          'status_tinggi_badan': statusTinggiBadan,
          'status_berat_badan': statusBeratBadan,
          'catatan': catatan?.isNotEmpty == true ? catatan : null,
        })
        .eq('id', id)
        .select()
        .single();
    return PertumbuhanModel.fromJson(data);
  }

  Future<void> hapus(String id) async {
    await _client.from('pertumbuhan').delete().eq('id', id);
  }

  void subscribeRealtime(String balitaId, void Function() onChange) {
    _channel?.unsubscribe();
    _channel = _client
        .channel('pertumbuhan_$balitaId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'pertumbuhan',
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
