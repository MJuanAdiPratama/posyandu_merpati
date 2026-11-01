import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/age_calculator.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/imunisasi_model.dart';
import '../../../../data/models/jadwal_imunisasi_model.dart';
import '../../providers/agenda_imunisasi_provider.dart';
import '../../providers/ortu_balita_provider.dart';
import '../../providers/riwayat_imunisasi_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Imunisasi (Riwayat + Agenda dalam satu tab)
// ─────────────────────────────────────────────────────────────────────────────

class ImunisasiTab extends StatefulWidget {
  const ImunisasiTab({super.key});

  @override
  State<ImunisasiTab> createState() => _ImunisasiTabState();
}

class _ImunisasiTabState extends State<ImunisasiTab>
    with SingleTickerProviderStateMixin {
  late TabController _tc;
  String? _loadedBalitaId;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final balita = context.read<OrtuBalitaProvider>().selected;
    if (balita != null && balita.id != _loadedBalitaId) {
      _loadedBalitaId = balita.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<RiwayatImunisasiProvider>().muatByBalita(balita.id);
        context.read<AgendaImunisasiProvider>().muatByBalita(balita.id);
      });
    }
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balita = context.watch<OrtuBalitaProvider>().selected;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientPageHeader(
            title: 'Imunisasi',
            subtitle: 'Riwayat dan agenda imunisasi balita.',
            icon: Icons.vaccines_rounded,
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
                controller: _tc,
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
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 16),
                        SizedBox(width: 5),
                        Text('Riwayat'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_note_rounded, size: 16),
                        SizedBox(width: 5),
                        Text('Agenda'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -10),
              child: TabBarView(
                controller: _tc,
                children: [
                  _RiwayatBody(balita: balita),
                  _AgendaBody(balita: balita),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Body Riwayat ─────────────────────────────────────────────────────────────

class _RiwayatBody extends StatefulWidget {
  final dynamic balita;
  const _RiwayatBody({required this.balita});

  @override
  State<_RiwayatBody> createState() => _RiwayatBodyState();
}

class _RiwayatBodyState extends State<_RiwayatBody>
    with SingleTickerProviderStateMixin {
  late TabController _filterTc;
  String? _loadedBalitaId;

  @override
  void initState() {
    super.initState();
    _filterTc = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _filterTc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balita = widget.balita;
    if (balita != null && balita.id != _loadedBalitaId) {
      _loadedBalitaId = balita.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<RiwayatImunisasiProvider>().muatByBalita(balita.id);
      });
    }

    return Consumer<RiwayatImunisasiProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading) return const LoadingWidget();
        if (provider.error != null) {
          return EmptyStateWidget(
            icon: Icons.error_outline_rounded,
            pesan: 'Gagal memuat riwayat imunisasi:\n${provider.error}',
          );
        }

        final semua = provider.daftar;
        final lengkap = semua
            .where(
              (i) =>
                  (i.beratBadan != null && i.tinggiBadan != null) ||
                  (i.catatan != null && i.catatan!.isNotEmpty),
            )
            .toList();
        final belumLengkap = semua.where((i) => !lengkap.contains(i)).toList();

        return Column(
          children: [
            // Header balita
            if (balita != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: SoftHeaderCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: balita.jenisKelamin == 'Perempuan'
                            ? const Color(0xFFFFE4EE)
                            : AppColors.surfaceTeal,
                        child: Icon(
                          balita.jenisKelamin == 'Perempuan'
                              ? Icons.girl_rounded
                              : Icons.boy_rounded,
                          color: balita.jenisKelamin == 'Perempuan'
                              ? const Color(0xFFE91E8C)
                              : AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              balita.nama,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${balita.jenisKelamin} • ${AgeCalculator.formatUsiaDetail(balita.tanggalLahir)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
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

            // Filter tab
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                height: 38,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _filterTc,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.primaryDark,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(fontSize: 11),
                  tabs: const [
                    Tab(text: 'Semua'),
                    Tab(text: 'Lengkap'),
                    Tab(text: 'Belum Lengkap'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Daftar
            Expanded(
              child: TabBarView(
                controller: _filterTc,
                children: [
                  _RiwayatList(
                    daftar: semua,
                    tanggalLahir: balita?.tanggalLahir,
                    emptyPesan: 'Belum ada riwayat imunisasi',
                  ),
                  _RiwayatList(
                    daftar: lengkap,
                    tanggalLahir: balita?.tanggalLahir,
                    emptyPesan: 'Belum ada imunisasi dengan data lengkap',
                  ),
                  _RiwayatList(
                    daftar: belumLengkap,
                    tanggalLahir: balita?.tanggalLahir,
                    emptyPesan: 'Semua imunisasi sudah memiliki data lengkap',
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
        ...daftar.asMap().entries.map(
          (e) => _RiwayatTimelineCard(
            item: e.value,
            isLast: e.key == daftar.length - 1,
            tanggalLahir: tanggalLahir,
          ),
        ),
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

class _RiwayatTimelineCard extends StatelessWidget {
  final ImunisasiModel item;
  final bool isLast;
  final DateTime? tanggalLahir;

  const _RiwayatTimelineCard({
    required this.item,
    required this.isLast,
    required this.tanggalLahir,
  });

  @override
  Widget build(BuildContext context) {
    final usia = tanggalLahir != null
        ? AgeCalculator.hitungUsiaBulan(tanggalLahir!, item.tanggalImunisasi)
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 96,
                color: AppColors.success.withValues(alpha: 0.25),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fmtDate(item.tanggalImunisasi),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.namaImunisasi ?? 'Imunisasi',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (usia != null)
                    _InfoRow(
                      icon: Icons.cake_outlined,
                      label: 'Usia: $usia bulan',
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
                  if (item.beratBadan != null || item.tinggiBadan != null) ...[
                    const SizedBox(height: 6),
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

  String _fmtDate(DateTime d) {
    const bulan = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${d.day} ${bulan[d.month]} ${d.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Body Agenda ───────────────────────────────────────────────────────────────

class _AgendaBody extends StatelessWidget {
  final dynamic balita;
  const _AgendaBody({required this.balita});

  @override
  Widget build(BuildContext context) {
    return Consumer<AgendaImunisasiProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading) return const LoadingWidget();
        if (provider.daftar.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.event_note,
            pesan: 'Belum ada agenda imunisasi',
          );
        }

        final sorted = [...provider.daftar]
          ..sort(
            (a, b) => (a.usiaBulanImunisasi ?? 0).compareTo(
              b.usiaBulanImunisasi ?? 0,
            ),
          );

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            // Header balita
            if (balita != null)
              SoftHeaderCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: balita.jenisKelamin == 'Perempuan'
                          ? const Color(0xFFFFE4EE)
                          : AppColors.surfaceTeal,
                      child: Icon(
                        balita.jenisKelamin == 'Perempuan'
                            ? Icons.girl_rounded
                            : Icons.boy_rounded,
                        color: balita.jenisKelamin == 'Perempuan'
                            ? const Color(0xFFE91E8C)
                            : AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            balita.nama,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Usia: ${AgeCalculator.formatUsiaDetail(balita.tanggalLahir)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'Jadwal Berdasarkan Usia',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 10),
            ...sorted.map((j) => _AgendaCard(jadwal: j)),
          ],
        );
      },
    );
  }
}

class _AgendaCard extends StatelessWidget {
  final JadwalImunisasiModel jadwal;
  const _AgendaCard({required this.jadwal});

  Color get _statusColor {
    switch (jadwal.status) {
      case 'selesai':
        return AppColors.success;
      case 'terlambat':
        return AppColors.error;
      default:
        return AppColors.accent;
    }
  }

  String get _statusLabel {
    switch (jadwal.status) {
      case 'selesai':
        return 'Selesai';
      case 'terlambat':
        return 'Terlambat';
      default:
        return 'Akan Datang';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    final isSelesai = jadwal.status == 'selesai';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Kolom kiri: usia
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                bottomLeft: Radius.circular(13),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelesai
                      ? Icons.check_circle_rounded
                      : Icons.calendar_today_rounded,
                  color: color,
                  size: 20,
                ),
                const SizedBox(height: 5),
                Text(
                  jadwal.usiaBulanImunisasi == 0
                      ? '0 bln\n(lahir)'
                      : '${jadwal.usiaBulanImunisasi}\nbulan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Kolom kanan: info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
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
                            fontSize: 13,
                          ),
                        ),
                      ),
                      StatusBadge(label: _statusLabel, color: color),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    jadwal.usiaBulanImunisasi == 0
                        ? 'Segera setelah lahir'
                        : 'Usia ${jadwal.usiaBulanImunisasi} bulan',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        isSelesai
                            ? Icons.check_circle_outline_rounded
                            : Icons.access_time_rounded,
                        size: 12,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isSelesai ? '' : 'Perkiraan: '}${_fmtDate(jadwal.tanggalJadwal)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const bulan = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${d.day} ${bulan[d.month]} ${d.year}';
  }
}
