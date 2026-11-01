import '../../core/services/supabase_service.dart';
import '../models/jenis_imunisasi_model.dart';

class JenisImunisasiRepository {
  final _client = SupabaseService.client;

  Future<List<JenisImunisasiModel>> getDaftar() async {
    final data = await _client
        .from('jenis_imunisasi')
        .select()
        .order('usia_bulan');
    return (data as List).map((e) => JenisImunisasiModel.fromJson(e)).toList();
  }

  Future<JenisImunisasiModel> tambah(JenisImunisasiModel item) async {
    final data = await _client
        .from('jenis_imunisasi')
        .insert({
          'nama_imunisasi': item.namaImunisasi,
          'usia_bulan': item.usiaBulan,
          'deskripsi': item.deskripsi,
          'kandungan': item.kandungan,
        })
        .select()
        .single();
    return JenisImunisasiModel.fromJson(data);
  }

  Future<JenisImunisasiModel> update(
    String id,
    Map<String, dynamic> data,
  ) async {
    final result = await _client
        .from('jenis_imunisasi')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return JenisImunisasiModel.fromJson(result);
  }

  Future<void> hapus(String id) async {
    await _client.from('jenis_imunisasi').delete().eq('id', id);
  }
}
