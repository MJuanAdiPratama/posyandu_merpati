import 'package:flutter_test/flutter_test.dart';
import 'package:posyandu_merpati/app.dart';
import 'package:posyandu_merpati/core/constants/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: _EmptyLocalStorage(),
        pkceAsyncStorage: _MemoryAsyncStorage(),
      ),
    );
    Supabase.instance.client.auth.stopAutoRefresh();

    await tester.pumpWidget(const PosyanduApp());
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();

    expect(find.byType(PosyanduApp), findsOneWidget);
  });
}

class _EmptyLocalStorage extends LocalStorage {
  @override
  Future<String?> accessToken() async => null;

  @override
  Future<bool> hasAccessToken() async => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> persistSession(String persistSessionString) async {}

  @override
  Future<void> removePersistedSession() async {}
}

class _MemoryAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> getItem({required String key}) async => _data[key];

  @override
  Future<void> removeItem({required String key}) async {
    _data.remove(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _data[key] = value;
  }
}
