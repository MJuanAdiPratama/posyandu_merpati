import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_config.dart';
import '../../core/services/supabase_service.dart';
import '../models/profile_model.dart';

class EmailConfirmationRequiredException implements Exception {
  final String message;

  EmailConfirmationRequiredException(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  final _client = SupabaseService.client;

  Future<ProfileModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) throw Exception('Login gagal');
    return _ambilAtauBuatProfil(response.user!);
  }

  Future<ProfileModel> register({
    required String email,
    required String password,
    required String nama,
    String? noHp,
    String? alamat,
  }) async {
    final metadata = {
      'nama': nama,
      'no_hp': noHp,
      'alamat': alamat,
      'role': 'orang_tua',
    };
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
    if (response.user == null) throw Exception('Registrasi gagal');

    final hasSession =
        response.session != null || _client.auth.currentSession != null;
    if (!hasSession) {
      throw EmailConfirmationRequiredException(
        'Registrasi berhasil. Silakan cek email untuk verifikasi akun, lalu login.',
      );
    }

    return _ambilAtauBuatProfil(response.user!, metadata: metadata);
  }

  Future<ProfileModel> getProfil() async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('Tidak ada sesi');
    return _ambilAtauBuatProfil(user);
  }

  Future<ProfileModel> updateProfil({
    required String nama,
    String? noHp,
    String? alamat,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('Tidak ada sesi');

    await _client
        .from('profiles')
        .update({'nama': nama, 'no_hp': noHp, 'alamat': alamat})
        .eq('id', userId);

    return _ambilProfil(userId);
  }

  Future<void> gantiPassword(String passwordBaru) async {
    await _client.auth.updateUser(UserAttributes(password: passwordBaru));
  }

  Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: SupabaseConfig.resetPasswordRedirectUrl,
    );
  }

  Future<List<ProfileModel>> getDaftarOrtu() async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('role', 'orang_tua')
        .order('nama', ascending: true);
    return (data as List).map((e) => ProfileModel.fromJson(e)).toList();
  }

  Future<List<String>> getIdSemuaKader() async {
    final data = await _client
        .from('profiles')
        .select('id')
        .eq('role', 'kader');
    return (data as List).map((e) => e['id'] as String).toList();
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<ProfileModel> _ambilProfil(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return ProfileModel.fromJson(data);
  }

  Future<ProfileModel> _ambilAtauBuatProfil(
    User user, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      return await _ambilProfil(user.id);
    } on PostgrestException catch (e) {
      if (!_isProfilTidakAdaAtauForbidden(e)) rethrow;
    }

    final data = _profileDataDariUser(user, metadata: metadata);
    try {
      await _client.from('profiles').upsert(data);
      return _ambilProfil(user.id);
    } on PostgrestException catch (e) {
      if (_isForbidden(e)) {
        return _profileDariUser(user, metadata: metadata);
      }
      rethrow;
    }
  }

  Map<String, dynamic> _profileDataDariUser(
    User user, {
    Map<String, dynamic>? metadata,
  }) {
    final meta = {...?user.userMetadata, ...?metadata};
    return {
      'id': user.id,
      'nama': (meta['nama'] as String?)?.trim().isNotEmpty == true
          ? meta['nama']
          : user.email?.split('@').first ?? 'Orang Tua',
      'email': user.email ?? metadata?['email'] ?? '',
      'no_hp': meta['no_hp'],
      'alamat': meta['alamat'],
      'role': meta['role'] ?? 'orang_tua',
    };
  }

  ProfileModel _profileDariUser(User user, {Map<String, dynamic>? metadata}) {
    final data = _profileDataDariUser(user, metadata: metadata);
    return ProfileModel(
      id: user.id,
      nama: data['nama'] as String,
      email: data['email'] as String,
      noHp: data['no_hp'] as String?,
      alamat: data['alamat'] as String?,
      role: data['role'] as String,
      createdAt: DateTime.parse(user.createdAt),
    );
  }

  bool _isProfilTidakAdaAtauForbidden(PostgrestException e) {
    return _isForbidden(e) || e.code == 'PGRST116';
  }

  bool _isForbidden(PostgrestException e) {
    return e.code == '42501' ||
        e.message.toLowerCase().contains('forbidden') ||
        e.message.toLowerCase().contains('row-level security');
  }
}
