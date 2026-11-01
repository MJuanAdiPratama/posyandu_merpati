import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/age_calculator.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/jadwal_imunisasi_model.dart';
import '../../providers/agenda_imunisasi_provider.dart';
import '../../providers/ortu_balita_provider.dart';

class AgendaImunisasiScreen extends StatefulWidget {
  const AgendaImunisasiScreen({super.key});

  @override
  State<AgendaImunisasiScreen> createState() => _AgendaImunisasiScreenState();
}

class _AgendaImunisasiScreenState extends State<AgendaImunisasiScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final balita = context.read<OrtuBalitaProvider>().selected;
      if (balita != null) {
        context.read<AgendaImunisasiProvider>().muatByBalita(balita.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final balita = context.watch<OrtuBalitaProvider>().selected;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientPageHeader(
            title: 'Agenda Imunisasi',
            subtitle: 'Pantau jadwal imunisasi sesuai usia balita.',
            icon: Icons.event_note_rounded,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -18),
              child: Consumer<AgendaImunisasiProvider>(
                builder: (_, provider, __) {
                  if (provider.isLoading) return const LoadingWidget();

                  if (balita != null &&
                      balita.statusVerifikasi != 'disetujui') {
                    return EmptyStateWidget(
                      icon: Icons.hourglass_top_rounded,
                      pesan: balita.statusVerifikasi == 'ditolak'
                          ? 'Data balita ditolak.\nHubungi kader posyandu untuk informasi lebih lanjut.'
                          : 'Data balita sedang menunggu verifikasi kader.\nAgenda imunisasi akan tersedia setelah diverifikasi.',
                    );
                  }

                  if (provider.daftar.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        if (balita != null) {
                          await provider.muatByBalita(balita.id);
                        }
                      },
                      child: const EmptyStateWidget(
                        icon: Icons.event_note,
                        pesan: 'Belum ada agenda imunisasi',
                      ),
                    );
                  }

                  // Urutkan berdasarkan usia bulan
                  final sorted = [...provider.daftar]
                    ..sort(
                      (a, b) => (a.usiaBulanImunisasi ?? 0).compareTo(
                        b.usiaBulanImunisasi ?? 0,
                      ),
                    );

                  final selesai = sorted
                      .where((j) => j.status == 'selesai')
                      .toList();
                  final mendatang = sorted
                      .where((j) => j.status != 'selesai')
                      .toList();

                  return RefreshIndicator(
                    onRefresh: () async {
                      if (balita != null) {
                        await provider.muatByBalita(balita.id);
                      }
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      children: [
                        // ── Header balita ─────────────────────────────────────────
                        if (balita != null)
                          SoftHeaderCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor:
                                      balita.jenisKelamin == 'Perempuan'
                                      ? const Color(0xFFFFE4EE)
                                      : AppColors.surfaceTeal,
                                  child: Icon(
                                    balita.jenisKelamin == 'Perempuan'
                                        ? Icons.girl_rounded
                                        : Icons.boy_rounded,
                                    color: balita.jenisKelamin == 'Perempuan'
                                        ? const Color(0xFFE91E8C)
                                        : AppColors.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        balita.nama,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Usia: ${AgeCalculator.formatUsiaDetail(balita.tanggalLahir)}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    StatusBadge(
                                      label: '${selesai.length} selesai',
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(height: 4),
                                    StatusBadge(
                                      label: '${mendatang.length} akan datang',
                                      color: AppColors.accent,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),

                        // ── Jadwal Berdasarkan Usia ───────────────────────────────
                        const SectionTitle(title: 'Jadwal Berdasarkan Usia'),
                        const SizedBox(height: 10),

                        ...sorted.map(
                          (j) => _AgendaCard(
                            jadwal: j,
                            tanggalLahir: balita?.tanggalLahir,
                          ),
                        ),
                      ],
                    ),
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

class _AgendaCard extends StatelessWidget {
  final JadwalImunisasiModel jadwal;
  final DateTime? tanggalLahir;

  const _AgendaCard({required this.jadwal, required this.tanggalLahir});

  bool get _isHariIni {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final jadwalDate = DateTime(
      jadwal.tanggalJadwal.year,
      jadwal.tanggalJadwal.month,
      jadwal.tanggalJadwal.day,
    );
    return jadwal.status == 'terjadwal' && jadwalDate.isAtSameMomentAs(today);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'selesai':
        return AppColors.success;
      case 'terlambat':
        return AppColors.error;
      case 'dibatalkan':
        return AppColors.textDisabled;
      default:
        return AppColors.accent;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'selesai':
        return 'Selesai';
      case 'terlambat':
        return 'Terlambat';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return 'Akan Datang';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'selesai':
        return Icons.check_circle_rounded;
      case 'terlambat':
        return Icons.warning_amber_rounded;
      case 'dibatalkan':
        return Icons.cancel_outlined;
      default:
        return Icons.calendar_today_rounded;
    }
  }

  String _usiaBulanLabel(int? usiaBulan) {
    if (usiaBulan == null) return '-';
    if (usiaBulan == 0) return '0 bulan\n(lahir)';
    return '$usiaBulan bulan';
  }

  @override
  Widget build(BuildContext context) {
    final status = jadwal.status;
    final statusColor = _statusColor(status);
    final isSelesai = status == 'selesai';
    final isMendatang = !isSelesai;

    final hariIni = _isHariIni;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hariIni)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.today_rounded, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Hari Ini — Segera ke Posyandu!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hariIni
                  ? AppColors.warning.withValues(alpha: 0.6)
                  : isSelesai
                  ? AppColors.success.withValues(alpha: 0.25)
                  : AppColors.accent.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Usia label (kiri) ─────────────────────────────────────
              Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(13),
                    bottomLeft: Radius.circular(13),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_statusIcon(status), color: statusColor, size: 22),
                    const SizedBox(height: 6),
                    Text(
                      _usiaBulanLabel(jadwal.usiaBulanImunisasi),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Info imunisasi (kanan) ────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              jadwal.namaImunisasi ?? 'Imunisasi',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          StatusBadge(
                            label: _statusLabel(status),
                            color: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Sub-label usia
                      Text(
                        jadwal.usiaBulanImunisasi == 0
                            ? 'Segera setelah lahir'
                            : 'Usia ${jadwal.usiaBulanImunisasi} bulan',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      // Tanggal jadwal atau perkiraan
                      if (isMendatang) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Perkiraan: ${DateFormat('dd MMM yyyy', 'id_ID').format(jadwal.tanggalJadwal)}',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 13,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat(
                                'dd MMM yyyy',
                                'id_ID',
                              ).format(jadwal.tanggalJadwal),
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
