import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/imunisasi_model.dart';

class ImunisasiRepository {
  final _client = SupabaseService.client;
  RealtimeChannel? _channel;

  Future<List<ImunisasiModel>> getByBalita(String balitaId) async {
    final data = await _client
        .from('imunisasi')
        .select(
          '*, jenis_imunisasi(nama_imunisasi), balita(nama), petugas:profiles(nama)',
        )
        .eq('balita_id', balitaId)
        .order('tanggal_imunisasi', ascending: false);
    return (data as List).map((e) => ImunisasiModel.fromJson(e)).toList();
  }

  Future<List<ImunisasiModel>> getBulanIni([DateTime? bulan]) async {
    final now = bulan ?? DateTime.now();
    final awal = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final akhir = now.month < 12
        ? '${now.year}-${(now.month + 1).toString().padLeft(2, '0')}-01'
        : '${now.year + 1}-01-01';
    final data = await _client
        .from('imunisasi')
        .select('*, jenis_imunisasi(nama_imunisasi), balita(nama)')
        .gte('tanggal_imunisasi', awal)
        .lt('tanggal_imunisasi', akhir)
        .order('tanggal_imunisasi', ascending: false);
    return (data as List).map((e) => ImunisasiModel.fromJson(e)).toList();
  }

  Future<Set<String>> getJenisIdsSudahDiberikan(String balitaId) async {
    final data = await _client
        .from('imunisasi')
        .select('jenis_imunisasi_id')
        .eq('balita_id', balitaId)
        .not('jenis_imunisasi_id', 'is', null);
    return (data as List).map((e) => e['jenis_imunisasi_id'] as String).toSet();
  }

  Future<ImunisasiModel> tambah(ImunisasiModel imunisasi) async {
    final data = await _client
        .from('imunisasi')
        .insert(imunisasi.toJson())
        .select('*, jenis_imunisasi(nama_imunisasi), balita(nama)')
        .single();
    return ImunisasiModel.fromJson(data);
  }

  Future<ImunisasiModel> update(
    String id, {
    required DateTime tanggalImunisasi,
    double? beratBadan,
    double? tinggiBadan,
    double? suhuBadan,
    double? lingkarKepala,
    String? catatan,
  }) async {
    final tgl =
        '${tanggalImunisasi.year}-${tanggalImunisasi.month.toString().padLeft(2, '0')}-${tanggalImunisasi.day.toString().padLeft(2, '0')}';
    final data = await _client
        .from('imunisasi')
        .update({
          'tanggal_imunisasi': tgl,
          'berat_badan': beratBadan,
          'tinggi_badan': tinggiBadan,
          'suhu_badan': suhuBadan,
          'lingkar_kepala': lingkarKepala,
          'catatan': catatan?.isNotEmpty == true ? catatan : null,
        })
        .eq('id', id)
        .select(
          '*, jenis_imunisasi(nama_imunisasi), balita(nama), petugas:profiles(nama)',
        )
        .single();
    return ImunisasiModel.fromJson(data);
  }

  Future<void> hapus(String id) async {
    await _client.from('imunisasi').delete().eq('id', id);
  }

  Future<int> getTotalBulanIni() async {
    final now = DateTime.now();
    final awal = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final akhir = now.month < 12
        ? '${now.year}-${(now.month + 1).toString().padLeft(2, '0')}-01'
        : '${now.year + 1}-01-01';
    final data = await _client
        .from('imunisasi')
        .select('id')
        .gte('tanggal_imunisasi', awal)
        .lt('tanggal_imunisasi', akhir);
    return (data as List).length;
  }

  void subscribeRealtime(String balitaId, void Function() onChange) {
    _channel?.unsubscribe();
    _channel = _client
        .channel('imunisasi_$balitaId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'imunisasi',
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
