import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background message sudah ditampilkan otomatis oleh FCM system tray
  // Tidak perlu tampil manual di sini
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await Firebase.initializeApp();

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    final token = await _messaging.getToken();
    if (token != null) await _simpanToken(token);

    _messaging.onTokenRefresh.listen(_simpanToken);

    // Handle notifikasi saat app foreground
    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;
      if (notification != null) {
        await NotificationService.tampilkanNotifikasi(
          id: message.hashCode,
          title: notification.title ?? 'Posyandu Merpati',
          body: notification.body ?? '',
        );
      }

    });
  }

  static Future<void> simpanTokenSetelahLogin() async {
    final token = await _messaging.getToken();
    if (token != null) await _simpanToken(token);
  }

  static Future<void> hapusToken() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await Supabase.instance.client
        .from('user_devices')
        .delete()
        .eq('user_id', userId)
        .eq('fcm_token', token);

    await _messaging.deleteToken();
  }

  static Future<void> _simpanToken(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client.from('user_devices').upsert({
      'user_id': userId,
      'fcm_token': token,
      'platform': 'android',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,fcm_token');
  }
}
