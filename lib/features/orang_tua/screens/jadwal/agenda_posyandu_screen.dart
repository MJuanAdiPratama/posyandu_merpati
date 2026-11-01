import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/jadwal_posyandu_model.dart';
import '../../providers/agenda_posyandu_provider.dart';

class AgendaPosyanduScreen extends StatefulWidget {
  const AgendaPosyanduScreen({super.key});

  @override
  State<AgendaPosyanduScreen> createState() => _AgendaPosyanduScreenState();
}

class _AgendaPosyanduScreenState extends State<AgendaPosyanduScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<AgendaPosyanduProvider>();
      if (!provider.isLoading && !provider.isInitialized) {
        provider.muatDaftar();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientPageHeader(
            title: 'Agenda Posyandu',
            subtitle: 'Jadwal layanan Posyandu untuk keluarga.',
            icon: Icons.event_note_rounded,
            onBack: () => Navigator.pop(context),
            bottomPadding: 16,
            bottom: Container(
              height: 42,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.primaryDark,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                tabs: const [
                  Tab(text: 'Mendatang'),
                  Tab(text: 'Lewat'),
                ],
              ),
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -10),
              child: Consumer<AgendaPosyanduProvider>(
                builder: (_, provider, __) {
                  // Tampilkan loading sampai data pertama kali berhasil dimuat
                  if (!provider.isInitialized) {
                    return const LoadingWidget();
                  }
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _JadwalList(
                        daftar: provider.mendatang,
                        emptyMessage:
                            'Belum ada jadwal posyandu\nyang akan datang.',
                        emptyIcon: Icons.event_note_rounded,
                        onRefresh: provider.muatDaftar,
                      ),
                      _JadwalList(
                        daftar: provider.lewat,
                        emptyMessage: 'Belum ada riwayat\njadwal posyandu.',
                        emptyIcon: Icons.history_rounded,
                        onRefresh: provider.muatDaftar,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JadwalList extends StatelessWidget {
  final List<JadwalPosyanduModel> daftar;
  final String emptyMessage;
  final IconData emptyIcon;
  final Future<void> Function() onRefresh;

  const _JadwalList({
    required this.daftar,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (daftar.isEmpty) {
      return EmptyStateWidget(icon: emptyIcon, pesan: emptyMessage);
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: daftar.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _JadwalCard(
          jadwal: daftar[i],
          onTap: () => _showDetail(ctx, daftar[i]),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, JadwalPosyanduModel jadwal) {
    final isPast = jadwal.tanggal.isBefore(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _DateBox(tanggal: jadwal.tanggal, muted: isPast),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      jadwal.judul,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow(
                icon: Icons.calendar_month_outlined,
                text: DateFormat(
                  'EEEE, dd MMMM yyyy',
                  'id_ID',
                ).format(jadwal.tanggal),
              ),
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.schedule_outlined,
                text: jadwal.jamMulai != null
                    ? '${jadwal.jamMulai}${jadwal.jamSelesai != null ? ' – ${jadwal.jamSelesai}' : ''} WIB'
                    : 'Waktu belum ditentukan',
              ),
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.place_outlined,
                text: jadwal.lokasi ?? 'Lokasi belum ditentukan',
              ),
              if (jadwal.deskripsi != null && jadwal.deskripsi!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  jadwal.deskripsi!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _JadwalCard extends StatelessWidget {
  final JadwalPosyanduModel jadwal;
  final VoidCallback onTap;

  const _JadwalCard({required this.jadwal, required this.onTap});

  int get _selisihHari {
    final now = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final tgl = DateTime(
      jadwal.tanggal.year,
      jadwal.tanggal.month,
      jadwal.tanggal.day,
    );
    return tgl.difference(now).inDays;
  }

  String get _countdownLabel {
    final hari = _selisihHari;
    if (hari == 0) return 'Hari ini';
    if (hari == 1) return 'Besok';
    if (hari > 0) return '$hari hari lagi';
    if (hari == -1) return 'Kemarin';
    return '${hari.abs()} hari lalu';
  }

  Color get _countdownColor {
    final hari = _selisihHari;
    if (hari <= 0) return AppColors.textSecondary;
    if (hari <= 3) return AppColors.error;
    if (hari <= 7) return AppColors.warning;
    return AppColors.success;
  }

  bool get _isPast => _selisihHari < 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: _isPast
              ? AppColors.border
              : AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _DateBox(tanggal: jadwal.tanggal, muted: _isPast),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jadwal.judul,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _isPast
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (jadwal.jamMulai != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${jadwal.jamMulai}${jadwal.jamSelesai != null ? ' – ${jadwal.jamSelesai}' : ''} WIB',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (jadwal.lokasi != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              jadwal.lokasi!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _countdownColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _countdownColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _countdownLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _countdownColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final DateTime tanggal;
  final bool muted;

  const _DateBox({required this.tanggal, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.textDisabled : AppColors.primary;
    return Container(
      width: 52,
      height: 58,
      decoration: BoxDecoration(
        color: muted ? const Color(0xFFF5F5F5) : AppColors.surfaceMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('dd').format(tanggal),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          Text(
            DateFormat('MMM', 'id_ID').format(tanggal).toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
