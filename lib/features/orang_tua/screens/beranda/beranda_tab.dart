import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/age_calculator.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/jadwal_imunisasi_model.dart';
import '../../../../routes/app_routes.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/agenda_imunisasi_provider.dart';
import '../../providers/agenda_posyandu_provider.dart';
import '../../providers/notifikasi_ortu_provider.dart';
import '../../providers/ortu_balita_provider.dart';
import '../../providers/pertumbuhan_provider.dart';
import '../../providers/riwayat_imunisasi_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Beranda
// ─────────────────────────────────────────────────────────────────────────────

class BerandaTab extends StatelessWidget {
  final VoidCallback? onOpenProfile;

  const BerandaTab({super.key, this.onOpenProfile});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final balitaProvider = context.watch<OrtuBalitaProvider>();
    final pertumbuhanProvider = context.watch<PertumbuhanProvider>();
    final agendaImunisasiProvider = context.watch<AgendaImunisasiProvider>();

    if (balitaProvider.isLoading) return const LoadingWidget();

    final balita = balitaProvider.selected;
    final pertumbuhan = pertumbuhanProvider.terakhir;
    final riwayatPertumbuhan = pertumbuhanProvider.daftar;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        final userId = auth.profil?.id;
        final pertumbuhanProv = context.read<PertumbuhanProvider>();
        final agendaImunisasiProv = context.read<AgendaImunisasiProvider>();
        final riwayatImunisasiProv = context.read<RiwayatImunisasiProvider>();
        final agendaPosyanduProv = context.read<AgendaPosyanduProvider>();
        if (userId != null) {
          await balitaProvider.muatByParent(userId);
          if (balitaProvider.selected != null) {
            final balitaId = balitaProvider.selected!.id;
            await Future.wait([
              pertumbuhanProv.muatByBalita(balitaId),
              agendaImunisasiProv.muatByBalita(balitaId),
              riwayatImunisasiProv.muatByBalita(balitaId),
            ]);
          } else {
            pertumbuhanProv.reset();
            agendaImunisasiProv.reset();
            riwayatImunisasiProv.reset();
          }
        }
        await agendaPosyanduProv.muatDaftar();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OrtuHeroHeader(
              nama: auth.profil?.nama ?? 'Orang Tua',
              onOpenProfile: onOpenProfile,
            ),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (balitaProvider.daftar.length > 1)
                      _BalitaSelector(provider: balitaProvider),
                    if (balitaProvider.daftar.isEmpty)
                      _EmptyBalitaCard()
                    else if (balita != null)
                      _BalitaDashboardCard(
                        balita: balita,
                        pertumbuhan: pertumbuhan,
                      ),
                    const SizedBox(height: 14),
                    _GrowthChartCard(daftar: riwayatPertumbuhan),
                    const SizedBox(height: 14),
                    _StatusSummaryCard(pertumbuhan: pertumbuhan),
                    const SizedBox(height: 14),
                    _AgendaImunisasiHomeCard(
                      daftar: agendaImunisasiProvider.mendatang,
                      isLoading: agendaImunisasiProvider.isLoading,
                    ),
                    const SizedBox(height: 18),
                    const _QuickAccessRow(),
                    const SizedBox(height: 12),
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

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Header dashboard orang tua
// ─────────────────────────────────────────────────────────────────────────────

class _OrtuHeroHeader extends StatelessWidget {
  final String nama;
  final VoidCallback? onOpenProfile;

  const _OrtuHeroHeader({required this.nama, this.onOpenProfile});

  @override
  Widget build(BuildContext context) {
    final firstName = nama.split(' ').first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 38),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00B7B0), AppColors.primary],
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const _NotificationButton(),
                IconButton(
                  onPressed:
                      onOpenProfile ??
                      () => Navigator.pushNamed(context, AppRoutes.profilOrtu),
                  icon: const Icon(
                    Icons.account_circle_outlined,
                    color: Colors.white,
                  ),
                  tooltip: 'Profil',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.family_restroom_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, $firstName!',
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
                        'Pantau kesehatan balita dengan mudah.',
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

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

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

class _BalitaSelector extends StatelessWidget {
  final OrtuBalitaProvider provider;

  const _BalitaSelector({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Balita',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: provider.daftar.map((b) {
                final selected = provider.selected?.id == b.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: selected,
                    label: Text(b.nama.split(' ').first),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceMint,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                    onSelected: (_) {
                      provider.pilihBalita(b);
                      context.read<PertumbuhanProvider>().muatByBalita(b.id);
                      context.read<AgendaImunisasiProvider>().muatByBalita(
                        b.id,
                      );
                      context.read<RiwayatImunisasiProvider>().muatByBalita(
                        b.id,
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthChartCard extends StatelessWidget {
  final List<dynamic> daftar;

  const _GrowthChartCard({required this.daftar});

  @override
  Widget build(BuildContext context) {
    final points = daftar.length > 6
        ? daftar.sublist(daftar.length - 6)
        : daftar;

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Grafik Pertumbuhan',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
              _SmallPill(
                label: '${points.length} data terakhir',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (points.length < 2)
            const SizedBox(
              height: 154,
              child: Center(
                child: Text(
                  'Data pertumbuhan belum cukup untuk grafik',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 174,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (points.length - 1).toDouble(),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: AppColors.divider, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 10,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          final date = points[index].tanggalPemeriksaan;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM', 'id_ID').format(date),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColors.primaryDark,
                    ),
                  ),
                  lineBarsData: [
                    _chartLine(
                      points,
                      AppColors.success,
                      (item) => item.beratBadan,
                    ),
                    _chartLine(
                      points,
                      AppColors.info,
                      (item) => item.tinggiBadan,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
          const Row(
            children: [
              _LegendDot(color: AppColors.success, label: 'Berat Badan (kg)'),
              SizedBox(width: 14),
              _LegendDot(color: AppColors.info, label: 'Tinggi Badan (cm)'),
            ],
          ),
        ],
      ),
    );
  }

  LineChartBarData _chartLine(
    List<dynamic> points,
    Color color,
    double Function(dynamic item) valueOf,
  ) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < points.length; i++)
          FlSpot(i.toDouble(), valueOf(points[i])),
      ],
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }
}

class _StatusSummaryCard extends StatelessWidget {
  final dynamic pertumbuhan;

  const _StatusSummaryCard({required this.pertumbuhan});

  @override
  Widget build(BuildContext context) {
    final status = pertumbuhan?.statusGizi ?? 'Belum ada data';
    final color = _statusColor(status);

    return _DashboardCard(
      onTap: () => Navigator.pushNamed(context, AppRoutes.pertumbuhan),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.accessibility_new_rounded,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Gizi',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pertumbuhan == null
                      ? 'Input pemeriksaan pertama akan tampil di sini'
                      : 'Terakhir diperiksa ${DateFormat('d MMM yyyy', 'id_ID').format(pertumbuhan.tanggalPemeriksaan)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _AgendaImunisasiHomeCard extends StatelessWidget {
  final List<JadwalImunisasiModel> daftar;
  final bool isLoading;

  const _AgendaImunisasiHomeCard({
    required this.daftar,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final item = daftar.isNotEmpty ? daftar.first : null;

    return _DashboardCard(
      onTap: () => Navigator.pushNamed(context, AppRoutes.agendaImunisasi),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Agenda Imunisasi',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.agendaImunisasi),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (item == null)
            const Padding(
              padding: EdgeInsets.only(top: 6, bottom: 8),
              child: Text(
                'Belum ada agenda imunisasi mendatang',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Row(
              children: [
                _DateBadge(date: item.tanggalJadwal),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.namaImunisasi ?? 'Imunisasi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const InfoTextRow(
                        icon: Icons.place_outlined,
                        text: 'Posyandu Merpati',
                      ),
                      const SizedBox(height: 3),
                      InfoTextRow(
                        icon: Icons.calendar_today_outlined,
                        text: DateFormat(
                          'EEEE, d MMMM yyyy',
                          'id_ID',
                        ).format(item.tanggalJadwal),
                      ),
                    ],
                  ),
                ),
                _SmallPill(label: _agendaLabel(item), color: AppColors.info),
              ],
            ),
        ],
      ),
    );
  }

  String _agendaLabel(JadwalImunisasiModel item) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(
      item.tanggalJadwal.year,
      item.tanggalJadwal.month,
      item.tanggalJadwal.day,
    );
    final days = date.difference(today).inDays;
    if (days <= 0) return 'Segera';
    if (days == 1) return 'Besok';
    return '$days hari';
  }
}

class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _ServiceTile(
            icon: Icons.fact_check_outlined,
            label: 'Riwayat\nImunisasi',
            color: AppColors.primary,
            route: AppRoutes.riwayatImunisasi,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _ServiceTile(
            icon: Icons.event_available_rounded,
            label: 'Jadwal\nPosyandu',
            color: AppColors.info,
            route: AppRoutes.agendaPosyandu,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _ServiceTile(
            icon: Icons.menu_book_rounded,
            label: 'Edukasi',
            color: Color(0xFF7E57C2),
            route: AppRoutes.edukasi,
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _DashboardCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.all(14), child: child),
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime date;

  const _DateBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 62,
      decoration: BoxDecoration(
        color: AppColors.surfaceMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('dd').format(date),
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            DateFormat('MMM', 'id_ID').format(date),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            DateFormat('yyyy').format(date),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  if (status.contains('Buruk') ||
      status.contains('Stunting') && !status.contains('Risiko')) {
    return AppColors.error;
  }
  if (status.contains('Kurang') || status.contains('Risiko')) {
    return AppColors.warning;
  }
  if (status.contains('Lebih') || status.contains('Obesitas')) {
    return AppColors.statusGiziLebih;
  }
  if (status == 'Belum ada data') return AppColors.textSecondary;
  return AppColors.success;
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Empty state jika belum ada balita
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyBalitaCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.child_care_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada balita terdaftar',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Daftarkan balita Anda untuk mulai memantau\npertumbuhan, imunisasi, dan status gizi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Daftar Balita Sekarang'),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.registrasiBalita),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Balita dashboard card (info lengkap + pertumbuhan)
// ─────────────────────────────────────────────────────────────────────────────

class _BalitaDashboardCard extends StatelessWidget {
  final dynamic balita;
  final dynamic pertumbuhan;

  const _BalitaDashboardCard({required this.balita, required this.pertumbuhan});

  Color get _verifikasiColor => balita.statusVerifikasi == 'disetujui'
      ? AppColors.success
      : AppColors.warning;

  String get _verifikasiLabel => balita.statusVerifikasi == 'disetujui'
      ? 'Terverifikasi'
      : balita.statusVerifikasi == 'pending'
      ? 'Menunggu'
      : balita.statusVerifikasi;

  bool get _isPerempuan => balita.jenisKelamin == 'Perempuan';

  @override
  Widget build(BuildContext context) {
    final usia = AgeCalculator.formatUsiaDetail(balita.tanggalLahir);
    final statusGizi = pertumbuhan?.statusGizi ?? 'Belum ada data';
    final statusGiziColor = _statusColor(statusGizi);

    return _DashboardCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: _isPerempuan
                      ? const Color(0xFFFFE4EE)
                      : AppColors.surfaceTeal,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _isPerempuan ? Icons.girl_rounded : Icons.boy_rounded,
                  color: _isPerempuan
                      ? const Color(0xFFE91E8C)
                      : AppColors.primary,
                  size: 42,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      balita.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Usia $usia',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          _isPerempuan
                              ? Icons.female_rounded
                              : Icons.male_rounded,
                          color: AppColors.primary,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            balita.jenisKelamin,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.health_and_safety_rounded,
                  color: AppColors.primary.withValues(alpha: 0.8),
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceMint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Gizi Terakhir',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (pertumbuhan != null)
                        Text(
                          'Diukur ${DateFormat('d MMM yyyy', 'id_ID').format(pertumbuhan.tanggalPemeriksaan)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        )
                      else
                        const Text(
                          'Belum ada pemeriksaan',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusGiziColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sentiment_satisfied_alt_rounded,
                        color: statusGiziColor,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusGizi,
                        style: TextStyle(
                          color: statusGiziColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              StatusBadge(label: _verifikasiLabel, color: _verifikasiColor),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.pertumbuhan),
                child: const Text('Lihat Detail'),
              ),
            ],
          ),
          if (pertumbuhan != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                _MiniMetric(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Berat',
                  value: '${pertumbuhan.beratBadan.toStringAsFixed(1)} kg',
                ),
                const SizedBox(width: 8),
                _MiniMetric(
                  icon: Icons.height_rounded,
                  label: 'Tinggi',
                  value: '${pertumbuhan.tinggiBadan.toStringAsFixed(1)} cm',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Service tile di grid
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _ServiceTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 104,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.9),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
