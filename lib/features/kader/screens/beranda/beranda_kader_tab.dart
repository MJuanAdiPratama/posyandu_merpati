import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../routes/app_routes.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../orang_tua/providers/notifikasi_ortu_provider.dart';
import '../../providers/balita_kader_provider.dart';
import '../../providers/dashboard_kader_provider.dart';
import '../../providers/jadwal_posyandu_provider.dart';
import '../../providers/monitoring_balita_provider.dart';
import '../widgets/small_date_badge.dart';

// ─── Dashboard Tab (Beranda) ──────────────────────────────────────────────────

class BerandaKaderTab extends StatelessWidget {
  const BerandaKaderTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardKaderProvider>();
    final auth = context.watch<AuthProvider>();
    final monitoring = context.watch<MonitoringBalitaProvider>();

    if (dashboard.isLoading) return const LoadingWidget();

    final jadwalValue = dashboard.jadwalTerdekat != null
        ? DateFormat('d MMM', 'id_ID').format(dashboard.jadwalTerdekat!.tanggal)
        : '--';
    final jadwalCaption = dashboard.jadwalTerdekat?.judul ?? 'Belum ada jadwal';

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await Future.wait([
          context.read<DashboardKaderProvider>().muatDashboard(),
          context.read<BalitaKaderProvider>().muatDaftar(),
          context.read<JadwalPosyanduProvider>().muatDaftar(),
          context.read<MonitoringBalitaProvider>().muatData(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _KaderHeroHeader(nama: auth.profil?.nama ?? 'Kader'),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.24,
                      children: [
                        _StatCard(
                          label: 'Total Balita',
                          value: '${dashboard.totalBalita}',
                          caption: '+ data terdaftar',
                          icon: Icons.groups_rounded,
                          color: AppColors.primary,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.daftarBalita,
                          ),
                        ),
                        _StatCard(
                          label: 'Imunisasi Bulan Ini',
                          value: '${dashboard.imunisasiBulanIni}',
                          caption: 'laporan bulan berjalan',
                          icon: Icons.vaccines_rounded,
                          color: AppColors.info,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.laporan),
                        ),
                        _StatCard(
                          label: 'Pending Verifikasi',
                          value: '${dashboard.pendingVerifikasi}',
                          caption: 'Perlu ditindaklanjuti',
                          icon: Icons.fact_check_rounded,
                          color: AppColors.warning,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.verifikasiBalita,
                          ),
                        ),
                        _StatCard(
                          label: 'Jadwal Terdekat',
                          value: jadwalValue,
                          caption: jadwalCaption,
                          icon: Icons.calendar_month_rounded,
                          color: const Color(0xFF7E57C2),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.jadwalPosyandu,
                          ),
                        ),
                        _StatCard(
                          label: 'Perlu Perhatian',
                          value: '${monitoring.jumlahPerluPerhatian}',
                          caption: 'Balita butuh tindak lanjut',
                          icon: Icons.health_and_safety_rounded,
                          color: AppColors.warning,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.monitoringBalita,
                          ),
                        ),
                      ],
                    ),
                    if (dashboard.jadwalImunisasiHariIni.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _JadwalImunisasiHariIniCard(
                        daftar: dashboard.jadwalImunisasiHariIni,
                      ),
                    ],
                    const SizedBox(height: 18),
                    const SectionTitle(title: 'Aksi Cepat'),
                    const SizedBox(height: 6),
                    _ShortcutGrid(pending: dashboard.pendingVerifikasi),
                    const SizedBox(height: 18),
                    _NearestPosyanduCard(
                      title: dashboard.jadwalTerdekat?.judul,
                      date: dashboard.jadwalTerdekat?.tanggal,
                      time: dashboard.jadwalTerdekat == null
                          ? null
                          : '${dashboard.jadwalTerdekat!.jamMulai ?? '--:--'}${dashboard.jadwalTerdekat!.jamSelesai != null ? ' - ${dashboard.jadwalTerdekat!.jamSelesai}' : ''} WIB',
                      location: dashboard.jadwalTerdekat?.lokasi,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KaderHeroHeader extends StatelessWidget {
  final String nama;

  const _KaderHeroHeader({required this.nama});

  @override
  Widget build(BuildContext context) {
    final firstName = nama.split(' ').first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 42),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 48),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Posyandu Merpati',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                    ),
                  ),
                ),
                const _KaderNotificationButton(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, Kader $firstName!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Semangat menjalankan tugas hari ini.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const PosyanduLogo(size: 46),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KaderNotificationButton extends StatelessWidget {
  const _KaderNotificationButton();

  @override
  Widget build(BuildContext context) {
    return Consumer<NotifikasiOrtuProvider>(
      builder: (_, notif, __) {
        final unread = notif.jumlahBelumDibaca;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
              ),
              tooltip: 'Notifikasi',
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.notifikasi),
            ),
            if (unread > 0)
              Positioned(
                right: 5,
                top: 7,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 17,
                    minHeight: 17,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NearestPosyanduCard extends StatelessWidget {
  final String? title;
  final DateTime? date;
  final String? time;
  final String? location;

  const _NearestPosyanduCard({
    required this.title,
    required this.date,
    required this.time,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surfaceMint,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, AppRoutes.jadwalPosyandu),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (date != null)
                SmallDateBadge(date: date!, muted: false)
              else
                IconBadge(
                  icon: Icons.event_busy_rounded,
                  color: AppColors.textSecondary,
                  size: 54,
                ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jadwal Posyandu Terdekat',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title ?? 'Belum ada jadwal mendatang',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    InfoTextRow(
                      icon: Icons.schedule_outlined,
                      text: time ?? 'Waktu belum diisi',
                    ),
                    const SizedBox(height: 2),
                    InfoTextRow(
                      icon: Icons.place_outlined,
                      text: location ?? 'Lokasi belum diisi',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Jadwal Imunisasi Hari Ini Card ──────────────────────────────────────────

class _JadwalImunisasiHariIniCard extends StatelessWidget {
  final List<dynamic> daftar;

  const _JadwalImunisasiHariIniCard({required this.daftar});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.vaccines_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Jadwal Imunisasi Hari Ini — ${daftar.length} balita',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...daftar.take(3).map((j) {
              final nama = j.namaBalita ?? '-';
              final vaksin = j.namaImunisasi ?? '-';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$nama — $vaksin',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (daftar.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '+ ${daftar.length - 3} lainnya',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: color == AppColors.warning
                      ? AppColors.warning
                      : AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shortcut Grid ────────────────────────────────────────────────────────────

class _ShortcutGrid extends StatelessWidget {
  final int pending;

  const _ShortcutGrid({required this.pending});

  Future<void> _open(BuildContext context, String route) async {
    await Navigator.pushNamed(context, route);
    if (!context.mounted) return;
    context.read<DashboardKaderProvider>().muatDashboard();
    context.read<BalitaKaderProvider>().muatDaftar();
    context.read<JadwalPosyanduProvider>().muatDaftar();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        _ShortcutTile(
          icon: Icons.groups_rounded,
          title: 'Data Balita',
          color: AppColors.primary,
          onTap: () => _open(context, AppRoutes.daftarBalita),
        ),
        _ShortcutTile(
          icon: Icons.vaccines_rounded,
          title: 'Input Imunisasi',
          color: AppColors.info,
          onTap: () => _open(context, AppRoutes.inputImunisasi),
        ),
        _ShortcutTile(
          icon: Icons.verified_user_rounded,
          title: pending > 0 ? 'Verifikasi ($pending)' : 'Verifikasi',
          color: AppColors.warning,
          onTap: () => _open(context, AppRoutes.verifikasiBalita),
        ),
        _ShortcutTile(
          icon: Icons.calendar_month_rounded,
          title: 'Jadwal Posyandu',
          color: const Color(0xFF7E57C2),
          onTap: () => _open(context, AppRoutes.jadwalPosyandu),
        ),
        _ShortcutTile(
          icon: Icons.description_rounded,
          title: 'Laporan',
          color: AppColors.primaryDark,
          onTap: () => _open(context, AppRoutes.laporan),
        ),
        _ShortcutTile(
          icon: Icons.menu_book_rounded,
          title: 'Edukasi',
          color: const Color(0xFFFF6384),
          onTap: () => _open(context, AppRoutes.kelolaEdukasi),
        ),
      ],
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ShortcutTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconBadge(icon: icon, color: color, size: 42),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.15,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
