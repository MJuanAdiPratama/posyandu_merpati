import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/age_calculator.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/imunisasi_model.dart';
import '../../providers/ortu_balita_provider.dart';
import '../../providers/riwayat_imunisasi_provider.dart';

class RiwayatImunisasiScreen extends StatefulWidget {
  const RiwayatImunisasiScreen({super.key});

  @override
  State<RiwayatImunisasiScreen> createState() => _RiwayatImunisasiScreenState();
}

class _RiwayatImunisasiScreenState extends State<RiwayatImunisasiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _loadedBalitaId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balita = context.watch<OrtuBalitaProvider>().selected;
    if (balita != null && balita.id != _loadedBalitaId) {
      _loadedBalitaId = balita.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<RiwayatImunisasiProvider>().muatByBalita(balita.id);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientPageHeader(
            title: 'Riwayat Imunisasi',
            subtitle: 'Lihat catatan imunisasi dan kelengkapan data balita.',
            icon: Icons.vaccines_rounded,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -18),
              child: Consumer<RiwayatImunisasiProvider>(
                builder: (_, provider, __) {
                  if (provider.isLoading) return const LoadingWidget();

                  if (balita != null &&
                      balita.statusVerifikasi != 'disetujui') {
                    return EmptyStateWidget(
                      icon: Icons.hourglass_top_rounded,
                      pesan: balita.statusVerifikasi == 'ditolak'
                          ? 'Data balita ditolak.\nHubungi kader posyandu untuk informasi lebih lanjut.'
                          : 'Data balita sedang menunggu verifikasi kader.\nRiwayat imunisasi akan tersedia setelah diverifikasi.',
                    );
                  }

                  if (provider.error != null) {
                    return EmptyStateWidget(
                      icon: Icons.error_outline_rounded,
                      pesan:
                          'Gagal memuat riwayat imunisasi:\n${provider.error}',
                    );
                  }

                  final semua = provider.daftar;
                  // "Lengkap" = imunisasi yang punya catatan atau data berat/tinggi
                  final lengkap = semua
                      .where(
                        (i) =>
                            (i.beratBadan != null && i.tinggiBadan != null) ||
                            (i.catatan != null && i.catatan!.isNotEmpty),
                      )
                      .toList();

                  return Column(
                    children: [
                      // ── Header balita ─────────────────────────────────────────
                      if (balita != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: SoftHeaderCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
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
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 10),
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
                                        '${balita.jenisKelamin} • ${AgeCalculator.formatUsiaDetail(balita.tanggalLahir)}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(
                                  label: '${semua.length} imunisasi',
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // ── Filter Tabs ───────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelColor: AppColors.primaryDark,
                            unselectedLabelColor: AppColors.textSecondary,
                            labelStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            tabs: const [
                              Tab(text: 'Semua'),
                              Tab(text: 'Lengkap'),
                              Tab(text: 'Belum Lengkap'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Tab content ───────────────────────────────────────────
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _RiwayatList(
                              daftar: semua,
                              tanggalLahir: balita?.tanggalLahir,
                              emptyPesan: 'Belum ada riwayat imunisasi',
                            ),
                            _RiwayatList(
                              daftar: lengkap,
                              tanggalLahir: balita?.tanggalLahir,
                              emptyPesan:
                                  'Belum ada imunisasi dengan data lengkap',
                            ),
                            _RiwayatList(
                              daftar: semua
                                  .where((i) => !lengkap.contains(i))
                                  .toList(),
                              tanggalLahir: balita?.tanggalLahir,
                              emptyPesan:
                                  'Semua imunisasi sudah memiliki data lengkap',
                            ),
                          ],
                        ),
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

class _RiwayatList extends StatelessWidget {
  final List<ImunisasiModel> daftar;
  final DateTime? tanggalLahir;
  final String emptyPesan;

  const _RiwayatList({
    required this.daftar,
    required this.tanggalLahir,
    required this.emptyPesan,
  });

  @override
  Widget build(BuildContext context) {
    if (daftar.isEmpty) {
      return EmptyStateWidget(icon: Icons.vaccines, pesan: emptyPesan);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        ...daftar.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == daftar.length - 1;
          return _TimelineCard(
            item: item,
            isLast: isLast,
            tanggalLahir: tanggalLahir,
          );
        }),
        // ── Catatan kaki ─────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.accent,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Catatan: Simpan kartu imunisasi fisik sebagai cadangan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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

class _TimelineCard extends StatelessWidget {
  final ImunisasiModel item;
  final bool isLast;
  final DateTime? tanggalLahir;

  const _TimelineCard({
    required this.item,
    required this.isLast,
    required this.tanggalLahir,
  });

  @override
  Widget build(BuildContext context) {
    final usiaSaatImun = tanggalLahir != null
        ? AgeCalculator.hitungUsiaBulan(tanggalLahir!, item.tanggalImunisasi)
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Timeline indicator ────────────────────────────────────────
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 100,
                color: AppColors.success.withValues(alpha: 0.25),
              ),
          ],
        ),
        const SizedBox(width: 10),

        // ── Card ──────────────────────────────────────────────────────
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tanggal
                  Text(
                    DateFormat(
                      'dd MMM yyyy',
                      'id_ID',
                    ).format(item.tanggalImunisasi),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Nama imunisasi
                  Text(
                    item.namaImunisasi ?? 'Imunisasi',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Baris info
                  if (usiaSaatImun != null)
                    _InfoRow(
                      icon: Icons.cake_outlined,
                      label: 'Usia: $usiaSaatImun bulan',
                    ),
                  const _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Lokasi: Posyandu Merpati',
                  ),
                  _InfoRow(
                    icon: Icons.notes_rounded,
                    label:
                        'Keterangan: ${item.catatan?.isNotEmpty == true ? item.catatan : 'Tidak ada keluhan'}',
                  ),
                  // Berat & tinggi chips
                  if (item.beratBadan != null || item.tinggiBadan != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (item.beratBadan != null)
                          _DataChip(
                            '${item.beratBadan} kg',
                            Icons.monitor_weight_outlined,
                          ),
                        if (item.tinggiBadan != null)
                          _DataChip(
                            '${item.tinggiBadan} cm',
                            Icons.height_rounded,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _DataChip(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
