import 'package:flutter/material.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/kader/screens/dashboard_kader_screen.dart';
import '../features/kader/screens/balita/daftar_balita_screen.dart';
import '../features/kader/screens/balita/tambah_balita_screen.dart';
import '../features/kader/screens/balita/edit_balita_screen.dart';
import '../features/kader/screens/balita/detail_balita_screen.dart';
import '../features/kader/screens/balita/verifikasi_balita_screen.dart';
import '../features/kader/screens/monitoring/monitoring_balita_screen.dart';
import '../features/kader/screens/imunisasi/input_imunisasi_screen.dart';
import '../features/kader/screens/imunisasi/jadwal_imunisasi_kader_screen.dart';
import '../features/kader/screens/imunisasi/jenis_imunisasi_screen.dart';
import '../features/kader/screens/jadwal/jadwal_posyandu_screen.dart';
import '../features/kader/screens/jadwal/tambah_jadwal_screen.dart';
import '../features/kader/screens/jadwal/edit_jadwal_screen.dart';
import '../features/kader/screens/laporan/laporan_screen.dart';
import '../features/kader/screens/manajemen_pengguna/manajemen_pengguna_screen.dart';
import '../features/kader/screens/edukasi/kelola_edukasi_screen.dart';
import '../features/kader/screens/edukasi/tambah_edukasi_screen.dart';
import '../features/kader/screens/edukasi/kategori_edukasi_screen.dart';
import '../features/kader/screens/pertumbuhan/input_pertumbuhan_screen.dart';
import '../features/kader/screens/profil/profil_kader_screen.dart';
import '../features/kader/screens/profil/edit_profil_screen.dart';
import '../features/kader/screens/profil/ganti_password_screen.dart';
import '../features/orang_tua/screens/dashboard_ortu_screen.dart';
import '../features/orang_tua/screens/jadwal/agenda_posyandu_screen.dart';
import '../features/orang_tua/screens/balita/registrasi_balita_screen.dart';
import '../features/orang_tua/screens/balita/pertumbuhan_screen.dart';
import '../features/orang_tua/screens/imunisasi/riwayat_imunisasi_screen.dart';
import '../features/orang_tua/screens/imunisasi/agenda_imunisasi_screen.dart';
import '../features/orang_tua/screens/notifikasi/notifikasi_screen.dart';
import '../features/orang_tua/screens/edukasi/edukasi_screen.dart';
import '../features/orang_tua/screens/edukasi/detail_edukasi_screen.dart';
import '../features/orang_tua/screens/profil/profil_ortu_screen.dart';
import '../features/shared/screens/kebijakan_privasi_screen.dart';
import '../features/shared/screens/pengaturan_notifikasi_screen.dart';
import '../features/shared/screens/pusat_bantuan_screen.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Kader
  static const String dashboardKader = '/kader/dashboard';
  static const String daftarBalita = '/kader/balita';
  static const String tambahBalita = '/kader/balita/tambah';
  static const String editBalita = '/kader/balita/edit';
  static const String detailBalita = '/kader/balita/detail';
  static const String verifikasiBalita = '/kader/balita/verifikasi';
  static const String monitoringBalita = '/kader/monitoring';
  static const String inputImunisasi = '/kader/imunisasi/input';
  static const String jadwalImunisasi = '/kader/imunisasi/jadwal';
  static const String jenisImunisasi = '/kader/imunisasi/jenis';
  static const String jadwalPosyandu = '/kader/jadwal';
  static const String tambahJadwal = '/kader/jadwal/tambah';
  static const String editJadwal = '/kader/jadwal/edit';
  static const String inputPertumbuhan = '/kader/pertumbuhan/input';
  static const String laporan = '/kader/laporan';
  static const String kelolaEdukasi = '/kader/edukasi';
  static const String tambahEdukasi = '/kader/edukasi/tambah';
  static const String kategoriEdukasi = '/kader/edukasi/kategori';
  static const String manajemenPengguna = '/kader/pengguna';
  static const String profilKader = '/kader/profil';
  static const String editProfil = '/kader/profil/edit';
  static const String gantiPassword = '/kader/profil/ganti-password';
  static const String pusatBantuan = '/pusat-bantuan';
  static const String kebijakanPrivasi = '/kebijakan-privasi';
  static const String pengaturanNotifikasi = '/pengaturan-notifikasi';

  // Orang Tua
  static const String dashboardOrtu = '/ortu/dashboard';
  static const String registrasiBalita = '/ortu/balita/registrasi';
  static const String agendaPosyandu = '/ortu/agenda-posyandu';
  static const String pertumbuhan = '/ortu/pertumbuhan';
  static const String riwayatImunisasi = '/ortu/imunisasi/riwayat';
  static const String agendaImunisasi = '/ortu/imunisasi/agenda';
  static const String notifikasi = '/ortu/notifikasi';
  static const String edukasi = '/ortu/edukasi';
  static const String detailEdukasi = '/ortu/edukasi/detail';
  static const String profilOrtu = '/ortu/profil';

  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    forgotPassword: (_) => const ForgotPasswordScreen(),
    resetPassword: (_) => const ResetPasswordScreen(),
    dashboardKader: (_) => const DashboardKaderScreen(),
    daftarBalita: (_) => const DaftarBalitaScreen(),
    tambahBalita: (_) => const TambahBalitaScreen(),
    editBalita: (_) => const EditBalitaScreen(),
    detailBalita: (_) => const DetailBalitaScreen(),
    verifikasiBalita: (_) => const VerifikasiBalitaScreen(),
    monitoringBalita: (_) => const MonitoringBalitaScreen(),
    inputImunisasi: (_) => const InputImunisasiScreen(),
    jadwalImunisasi: (_) => const JadwalImunisasiKaderScreen(),
    jenisImunisasi: (_) => const JenisImunisasiScreen(),
    jadwalPosyandu: (_) => const JadwalPosyanduScreen(),
    tambahJadwal: (_) => const TambahJadwalScreen(),
    editJadwal: (_) => const EditJadwalScreen(),
    inputPertumbuhan: (_) => const InputPertumbuhanScreen(),
    laporan: (_) => const LaporanScreen(),
    manajemenPengguna: (_) => const ManajemenPenggunaScreen(),
    kelolaEdukasi: (_) => const KelolaEdukasiScreen(),
    tambahEdukasi: (_) => const TambahEdukasiScreen(),
    kategoriEdukasi: (_) => const KategoriEdukasiScreen(),
    profilKader: (_) => const ProfilKaderScreen(),
    editProfil: (_) => const EditProfilScreen(),
    gantiPassword: (_) => const GantiPasswordScreen(),
    pusatBantuan: (_) => const PusatBantuanScreen(),
    kebijakanPrivasi: (_) => const KebijakanPrivasiScreen(),
    pengaturanNotifikasi: (_) => const PengaturanNotifikasiScreen(),
    dashboardOrtu: (_) => const DashboardOrtuScreen(),
    registrasiBalita: (_) => const RegistrasiBalitaScreen(),
    agendaPosyandu: (_) => const AgendaPosyanduScreen(),
    pertumbuhan: (_) => const PertumbuhanScreen(),
    riwayatImunisasi: (_) => const RiwayatImunisasiScreen(),
    agendaImunisasi: (_) => const AgendaImunisasiScreen(),
    notifikasi: (_) => const NotifikasiScreen(),
    edukasi: (_) => const EdukasiScreen(),
    detailEdukasi: (_) => const DetailEdukasiScreen(),
    profilOrtu: (_) => const ProfilOrtuScreen(),
  };
}
