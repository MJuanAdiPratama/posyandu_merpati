import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/age_calculator.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/balita_model.dart';
import '../../providers/balita_kader_provider.dart';
import 'generate_jadwal_screen.dart';

class VerifikasiBalitaScreen extends StatefulWidget {
  const VerifikasiBalitaScreen({super.key});

  @override
  State<VerifikasiBalitaScreen> createState() => _VerifikasiBalitaScreenState();
}

class _VerifikasiBalitaScreenState extends State<VerifikasiBalitaScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BalitaKaderProvider>().muatPending();
      context.read<BalitaKaderProvider>().muatDaftar();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BalitaKaderProvider>(
      builder: (_, provider, __) {
        final terverifikasi = provider.daftar
            .where((b) => b.statusVerifikasi == 'disetujui')
            .toList();

        return Scaffold(
          appBar: GradientAppBar(
            title: AppStrings.verifikasiBalita,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'Pending (${provider.pending.length})'),
                Tab(text: 'Terverifikasi (${terverifikasi.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // ── Tab 1: Pending ────────────────────────────────────────────
              _buildPendingTab(provider),

              // ── Tab 2: Terverifikasi ──────────────────────────────────────
              _buildTerverifikasiTab(provider, terverifikasi),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingTab(BalitaKaderProvider provider) {
    if (provider.isLoading) return const LoadingWidget();

    if (provider.pending.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.check_circle_outline,
        pesan: 'Tidak ada balita yang menunggu verifikasi',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.muatPending,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          KaderHeroPanel(
            title: 'Antrean Verifikasi',
            subtitle:
                '${provider.pending.length} data balita perlu diperiksa admin.',
            icon: Icons.fact_check_rounded,
          ),
          const SizedBox(height: 14),
          const SectionTitle(title: 'Data Pending'),
          const SizedBox(height: 10),
          ...provider.pending.map((balita) {
            final usia = AgeCalculator.formatUsiaDariTanggalLahir(
              balita.tanggalLahir,
            );
            final isBoy = balita.jenisKelamin == 'Laki-laki';
            final terdaftar = DateFormat(
              'dd MMM yyyy',
              'id_ID',
            ).format(balita.createdAt);

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: isBoy
                              ? AppColors.secondary.withValues(alpha: 0.16)
                              : const Color(0xFFFFEEF5),
                          child: Icon(
                            isBoy ? Icons.boy : Icons.girl,
                            color: isBoy
                                ? AppColors.secondary
                                : const Color(0xFFE85D8E),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                balita.nama,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'NIK ${balita.nik}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const StatusBadge(
                          label: 'Pending',
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InfoTextRow(
                      icon: Icons.wc_rounded,
                      text: '${balita.jenisKelamin}, $usia',
                    ),
                    const SizedBox(height: 5),
                    InfoTextRow(
                      icon: Icons.family_restroom_rounded,
                      text: 'Pendaftar: ${balita.namaOrtu}',
                    ),
                    const SizedBox(height: 5),
                    InfoTextRow(
                      icon: Icons.calendar_today_outlined,
                      text: 'Didaftarkan: $terdaftar',
                    ),
                    if (balita.alamat != null && balita.alamat!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      InfoTextRow(
                        icon: Icons.place_outlined,
                        text: balita.alamat!,
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.error,
                              size: 18,
                            ),
                            label: const Text(
                              AppStrings.tolak,
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () => _konfirmasi(
                              context,
                              provider,
                              balita,
                              'ditolak',
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              AppStrings.setujui,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () => _konfirmasi(
                              context,
                              provider,
                              balita,
                              'disetujui',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTerverifikasiTab(
    BalitaKaderProvider provider,
    List<BalitaModel> terverifikasi,
  ) {
    if (provider.isLoading) return const LoadingWidget();

    if (terverifikasi.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.verified_user_outlined,
        pesan: 'Belum ada balita yang terverifikasi',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.muatDaftar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          KaderHeroPanel(
            title: 'Balita Terverifikasi',
            subtitle:
                '${terverifikasi.length} data balita sudah aktif untuk layanan.',
            icon: Icons.verified_user_rounded,
          ),
          const SizedBox(height: 14),
          const SectionTitle(title: 'Data Aktif'),
          const SizedBox(height: 10),
          ...terverifikasi.map((balita) {
            final isBoy = balita.jenisKelamin == 'Laki-laki';
            final usia = AgeCalculator.formatUsiaDariTanggalLahir(
              balita.tanggalLahir,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: isBoy
                            ? AppColors.secondary.withValues(alpha: 0.16)
                            : const Color(0xFFFFEEF5),
                        child: Icon(
                          isBoy ? Icons.boy : Icons.girl,
                          color: isBoy
                              ? AppColors.secondary
                              : const Color(0xFFE85D8E),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              balita.nama,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'NIK ${balita.nik}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${balita.jenisKelamin}, $usia',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const StatusBadge(
                        label: 'Terverifikasi',
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _konfirmasi(
    BuildContext context,
    BalitaKaderProvider provider,
    BalitaModel balita,
    String status,
  ) async {
    final label = status == 'disetujui' ? 'menyetujui' : 'menolak';
    final isApprove = status == 'disetujui';
    final ok = await showConfirmationDialog(
      context: context,
      title: 'Konfirmasi ${isApprove ? 'Setujui' : 'Tolak'}',
      message: 'Apakah Anda yakin ingin $label data balita ini?',
      confirmText: isApprove ? AppStrings.setujui : AppStrings.tolak,
      confirmColor: isApprove ? AppColors.success : AppColors.error,
      icon: isApprove
          ? Icons.check_circle_outline_rounded
          : Icons.cancel_outlined,
    );
    if (ok == true && context.mounted) {
      final berhasil = await provider.verifikasi(balita, status);
      if (!context.mounted) return;
      if (berhasil) {
        if (status == 'disetujui') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GenerateJadwalScreen(balita: balita),
            ),
          );
          if (!context.mounted) return;
        } else {
          CustomSnackbar.sukses(context, 'Data balita berhasil ditolak');
        }
        provider.muatDaftar();
      } else {
        CustomSnackbar.gagal(context, AppStrings.gagalMenyimpan);
      }
    }
  }
}
