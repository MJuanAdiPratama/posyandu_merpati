import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/fcm_service.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  ProfileModel? _profil;
  bool _isLoading = false;
  String? _error;
  bool _needsEmailConfirmation = false;

  ProfileModel? get profil => _profil;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get needsEmailConfirmation => _needsEmailConfirmation;
  bool get isLoggedIn => _profil != null;
  bool get isKader => _profil?.role == 'kader';
  bool get isOrangTua => _profil?.role == 'orang_tua';

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      _needsEmailConfirmation = false;
      _profil = await _repo.login(email: email, password: password);
      _error = null;
      FcmService.simpanTokenSetelahLogin();
      return true;
    } catch (e) {
      _error = _pesanError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String nama,
    String? noHp,
    String? alamat,
  }) async {
    _setLoading(true);
    try {
      _needsEmailConfirmation = false;
      _profil = await _repo.register(
        email: email,
        password: password,
        nama: nama,
        noHp: noHp,
        alamat: alamat,
      );
      _error = null;
      return true;
    } on EmailConfirmationRequiredException catch (e) {
      _needsEmailConfirmation = true;
      _error = e.message;
      return false;
    } catch (e) {
      _needsEmailConfirmation = false;
      _error = _pesanError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> muatProfil() async {
    try {
      _profil = await _repo.getProfil();
      notifyListeners();
    } catch (_) {
      _profil = null;
      notifyListeners();
    }
  }

  Future<bool> updateProfil({
    required String nama,
    String? noHp,
    String? alamat,
  }) async {
    _setLoading(true);
    try {
      _profil = await _repo.updateProfil(
        nama: nama,
        noHp: noHp,
        alamat: alamat,
      );
      _error = null;
      return true;
    } catch (e) {
      _error = _pesanError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> gantiPassword(String passwordBaru) async {
    _setLoading(true);
    try {
      await _repo.gantiPassword(passwordBaru);
      _error = null;
      return true;
    } catch (e) {
      _error = _pesanError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPasswordForEmail(String email) async {
    _setLoading(true);
    try {
      await _repo.resetPasswordForEmail(email);
      _error = null;
      return true;
    } catch (e) {
      _error = _pesanError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await FcmService.hapusToken();
    await _repo.logout();
    _profil = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  String _pesanError(Object e) {
    if (e is AuthException) {
      final pesan = e.message.toLowerCase();
      if (pesan.contains('invalid login credentials')) {
        return 'Email atau password salah.';
      }
      if (pesan.contains('email not confirmed')) {
        return 'Email belum diverifikasi. Silakan cek email Anda.';
      }
      if (pesan.contains('user already registered') ||
          pesan.contains('already registered')) {
        return 'Email sudah terdaftar. Silakan login.';
      }
      if (pesan.contains('password should be at least')) {
        return 'Password minimal 6 karakter.';
      }
      if (pesan.contains('invalid email')) {
        return 'Format email tidak valid.';
      }
      if (pesan.contains('rate limit') || pesan.contains('too many')) {
        return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
      }
      return 'Terjadi kesalahan autentikasi. Silakan coba lagi.';
    }
    if (e is PostgrestException) {
      return 'Terjadi kesalahan pada server. Silakan coba lagi.';
    }
    return e.toString().replaceAll('Exception: ', '');
  }
}
