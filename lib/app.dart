import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_strings.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/kader/providers/balita_kader_provider.dart';
import 'features/kader/providers/dashboard_kader_provider.dart';
import 'features/kader/providers/edukasi_kader_provider.dart';
import 'features/kader/providers/imunisasi_provider.dart';
import 'features/kader/providers/jadwal_posyandu_provider.dart';
import 'features/kader/providers/laporan_provider.dart';
import 'features/kader/providers/pertumbuhan_kader_provider.dart';
import 'features/kader/providers/jadwal_imunisasi_kader_provider.dart';
import 'features/kader/providers/manajemen_pengguna_provider.dart';
import 'features/kader/providers/monitoring_balita_provider.dart';
import 'features/kader/providers/jenis_imunisasi_provider.dart';
import 'features/orang_tua/providers/agenda_imunisasi_provider.dart';
import 'features/orang_tua/providers/agenda_posyandu_provider.dart';
import 'features/orang_tua/providers/edukasi_ortu_provider.dart';
import 'features/orang_tua/providers/notifikasi_ortu_provider.dart';
import 'features/orang_tua/providers/ortu_balita_provider.dart';
import 'features/orang_tua/providers/pertumbuhan_provider.dart';
import 'features/orang_tua/providers/riwayat_imunisasi_provider.dart';
import 'routes/app_routes.dart';

class PosyanduApp extends StatefulWidget {
  const PosyanduApp({super.key});

  @override
  State<PosyanduApp> createState() => _PosyanduAppState();
}

class _PosyanduAppState extends State<PosyanduApp> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = SupabaseService.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        AppRoutes.navigatorKey.currentState?.pushNamed(
          AppRoutes.resetPassword,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardKaderProvider()),
        ChangeNotifierProvider(create: (_) => BalitaKaderProvider()),
        ChangeNotifierProvider(create: (_) => MonitoringBalitaProvider()),
        ChangeNotifierProvider(create: (_) => ImunisasiProvider()),
        ChangeNotifierProvider(create: (_) => JadwalImunisasiKaderProvider()),
        ChangeNotifierProvider(create: (_) => JenisImunisasiProvider()),
        ChangeNotifierProvider(create: (_) => JadwalPosyanduProvider()),
        ChangeNotifierProvider(create: (_) => EdukasiKaderProvider()),
        ChangeNotifierProvider(create: (_) => LaporanProvider()),
        ChangeNotifierProvider(create: (_) => ManajemenPenggunaProvider()),
        ChangeNotifierProvider(create: (_) => PertumbuhanKaderProvider()),
        ChangeNotifierProvider(create: (_) => OrtuBalitaProvider()),
        ChangeNotifierProvider(create: (_) => PertumbuhanProvider()),
        ChangeNotifierProvider(create: (_) => RiwayatImunisasiProvider()),
        ChangeNotifierProvider(create: (_) => AgendaImunisasiProvider()),
        ChangeNotifierProvider(create: (_) => AgendaPosyanduProvider()),
        ChangeNotifierProvider(create: (_) => NotifikasiOrtuProvider()),
        ChangeNotifierProvider(create: (_) => EdukasiOrtuProvider()),
      ],
      child: MaterialApp(
        navigatorKey: AppRoutes.navigatorKey,
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
        locale: const Locale('id', 'ID'),
        routes: AppRoutes.routes,
        home: const SplashScreen(),
      ),
    );
  }
}
