import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/edukasi_kategori_model.dart';
import '../models/edukasi_model.dart';

class EdukasiRepository {
  final _client = SupabaseService.client;

  Future<List<EdukasiModel>> getDaftar() async {
    final data = await _client
        .from('edukasi')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => EdukasiModel.fromJson(e)).toList();
  }

  Future<List<EdukasiKategoriModel>> getKategori() async {
    final data = await _client
        .from('edukasi_kategori')
        .select()
        .order('nama', ascending: true);
    return (data as List).map((e) => EdukasiKategoriModel.fromJson(e)).toList();
  }

  Future<EdukasiModel> getDetail(String id) async {
    final data = await _client.from('edukasi').select().eq('id', id).single();
    return EdukasiModel.fromJson(data);
  }

  Future<EdukasiModel> tambah(EdukasiModel edukasi) async {
    final data = await _client
        .from('edukasi')
        .insert(edukasi.toJson())
        .select()
        .single();
    return EdukasiModel.fromJson(data);
  }

  Future<EdukasiModel> update(String id, Map<String, dynamic> data) async {
    final result = await _client
        .from('edukasi')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return EdukasiModel.fromJson(result);
  }

  Future<void> hapus(String id) async {
    await _client.from('edukasi').delete().eq('id', id);
  }

  Future<EdukasiKategoriModel> tambahKategori(
    EdukasiKategoriModel kategori,
  ) async {
    final data = await _client
        .from('edukasi_kategori')
        .insert(kategori.toJson())
        .select()
        .single();
    return EdukasiKategoriModel.fromJson(data);
  }

  Future<EdukasiKategoriModel> updateKategori(
    String id,
    Map<String, dynamic> data,
  ) async {
    final result = await _client
        .from('edukasi_kategori')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return EdukasiKategoriModel.fromJson(result);
  }

  Future<void> hapusKategori(String id) async {
    await _client.from('edukasi_kategori').delete().eq('id', id);
  }

  static const _bucket = 'edukasi-images';

  Future<String> uploadGambar(String filePath) async {
    final file = File(filePath);
    final ext = filePath.split('.').last.toLowerCase();
    final storagePath = 'edukasi/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage
        .from(_bucket)
        .upload(
          storagePath,
          file,
          fileOptions: FileOptions(contentType: 'image/$ext', upsert: false),
        );
    return _client.storage.from(_bucket).getPublicUrl(storagePath);
  }

  Future<void> hapusGambar(String gambarUrl) async {
    try {
      final uri = Uri.parse(gambarUrl);
      final segments = uri.pathSegments;
      final bucketIdx = segments.indexOf(_bucket);
      if (bucketIdx == -1) return;
      final storagePath = segments.sublist(bucketIdx + 1).join('/');
      await _client.storage.from(_bucket).remove([storagePath]);
    } catch (_) {}
  }
}
