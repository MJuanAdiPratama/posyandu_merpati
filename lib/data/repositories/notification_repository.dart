import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final _client = SupabaseService.client;
  RealtimeChannel? _channel;

  Future<List<NotificationModel>> getDaftarNotifikasi(String userId) async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => NotificationModel.fromJson(e)).toList();
  }

  Future<void> tandaiDibaca(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> tandaiSemuaDibaca(String userId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Future<void> hapusNotifikasi(String id) async {
    await _client.from('notifications').delete().eq('id', id);
  }

  Future<void> hapusSemuaNotifikasi(String userId) async {
    await _client.from('notifications').delete().eq('user_id', userId);
  }

  Future<void> buatNotifikasiMassal({
    required List<String> userIds,
    required String title,
    required String message,
    required String type,
  }) async {
    if (userIds.isEmpty) return;
    final rows = userIds
        .map(
          (uid) => {
            'user_id': uid,
            'title': title,
            'message': message,
            'type': type,
            'is_read': false,
          },
        )
        .toList();
    await _client.from('notifications').insert(rows);
  }

  Future<void> buatNotifikasi({
    required String userId,
    String? balitaId,
    required String title,
    required String message,
    required String type,
    DateTime? scheduledAt,
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'balita_id': balitaId,
      'title': title,
      'message': message,
      'type': type,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'is_read': false,
    });
  }

  void subscribeRealtime(
    String userId,
    void Function(NotificationModel) onNew,
  ) {
    // Pastikan tidak ada channel lama yang masih aktif sebelum subscribe baru.
    unsubscribeRealtime();
    _channel = _client
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final record = payload.newRecord;
            if (record['user_id'] != userId) return;
            // Tampilan notifikasi sistem ditangani oleh FCM (edge function
            // send-notification), bukan di sini, agar tidak tampil dobel.
            // Subscription ini hanya untuk update list notifikasi di app.
            onNew(NotificationModel.fromJson(record));
          },
        )
        .subscribe();
  }

  void unsubscribeRealtime() {
    _channel?.unsubscribe();
    _channel = null;
  }
}
