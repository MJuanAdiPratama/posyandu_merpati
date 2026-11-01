import '../../core/services/supabase_service.dart';
import '../models/profile_model.dart';

class ManajemenPenggunaRepository {
  final _client = SupabaseService.client;

  Future<List<ProfileModel>> getDaftarPengguna({String? filterRole}) async {
    final query = _client.from('profiles').select();
    final data = filterRole != null
        ? await query.eq('role', filterRole).order('nama', ascending: true)
        : await query.order('nama', ascending: true);
    return (data as List).map((e) => ProfileModel.fromJson(e)).toList();
  }

  Future<void> updateStatusAktif(String userId, bool isActive) async {
    await _client
        .from('profiles')
        .update({'is_active': isActive})
        .eq('id', userId);
  }

  Future<void> updateRole(String userId, String role) async {
    await _client.from('profiles').update({'role': role}).eq('id', userId);
  }
}
