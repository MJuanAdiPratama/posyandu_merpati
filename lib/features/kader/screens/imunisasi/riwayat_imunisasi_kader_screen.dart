import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/age_calculator.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/imunisasi_model.dart';
import '../../../../data/models/jadwal_imunisasi_model.dart';
import '../../providers/balita_kader_provider.dart';
import '../../providers/imunisasi_provider.dart';
import '../../providers/jadwal_imunisasi_kader_provider.dart';
import 'detail_imunisasi_kader_screen.dart';

enum _FilterImunisasi { semua, selesai, bulanIni }

class RiwayatImunisasiKaderScreen extends StatefulWidget {
  const RiwayatImunisasiKaderScreen({super.key});

  @override
  State<RiwayatImunisasiKaderScreen> createState() =>
      _RiwayatImunisasiKaderScreenState();
}

class _RiwayatImunisasiKaderScreenState
    extends State<RiwayatImunisasiKaderScreen> {
  _FilterImunisasi _filter = _FilterImunisasi.semua;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final balita = context.read<BalitaKaderProvider>().selected;
      if (balita != null) {
        context.read<ImunisasiProvider>().muatByBalita(balita.id);
        context
            .read<JadwalImunisasiKaderProvider>()
            .muatTersediaByBalita(balita.id);
      }
    });
  }

  List<ImunisasiModel> _terapkanFilter(List<ImunisasiModel> list) {
    final now = DateTime.now();
    switch (_filter) {
      case _FilterImunisasi.semua:
        return list;
      case _FilterImunisasi.selesai:
        return list;
      case _FilterImunisasi.bulanIni:
        return list
            .where((i) =>
                i.tanggalImunisasi.year == now.year &&
                i.tanggalImunisasi.month == now.month)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final balita = context.watch<BalitaKaderProvider>().selected;
    final provider = context.watch<ImunisasiProvider>();
    final jadwalProvider = context.watch<JadwalImunisasiKaderProvider>();
    final df = DateFormat('dd MMM yyyy', 'id_ID');

    final filtered = _terapkanFilter(provider.daftar);

    // Jadwal pending (belum selesai) diurutkan dari terdekat
    final jadwalPending = jadwalProvider.jadwalTersedia
        .where((j) => j.status != 'selesai')
        .toList()
      ..sort((a, b) => a.tanggalJadwal.compareTo(b.tanggalJadwal));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'Riwayat Imunisasi',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: provider.isLoading
          ? const LoadingWidget()
          : Column(
              children: [
                // Balita info card
                if (balita != null)
                  _BalitaInfoCard(
                    nama: balita.nama,
                    tanggalLahir: balita.tanggalLahir,
                    jenisKelamin: balita.jenisKelamin,
                  ),
                // Filter tabs
                _FilterTabs(
                  current: _filter,
                  jumlahBulanIni: provider.daftar
                      .where((i) =>
                          i.tanggalImunisasi.year == DateTime.now().year &&
                          i.tanggalImunisasi.month == DateTime.now().month)
                      .length,
                  onChange: (f) => setState(() => _filter = f),
                ),
                // List
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.vaccines_outlined,
                          pesan: _filter == _FilterImunisasi.bulanIni
                              ? 'Belum ada imunisasi bulan ini'
                              : 'Belum ada riwayat imunisasi',
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            if (balita != null) {
                              await provider.muatByBalita(balita.id);
                            }
                          },
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 32),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) {
                              final item = filtered[i];
                              final isLast = i == filtered.length - 1;

                              // Jadwal berikutnya hanya untuk item pertama
                              JadwalImunisasiModel? jadwalBerikutnya;
                              if (i == 0 && jadwalPending.isNotEmpty) {
                                jadwalBerikutnya = jadwalPending.first;
                              }

                              return _TimelineItem(
                                item: item,
                                isLast: isLast,
                                tanggalLahir: balita?.tanggalLahir,
                                df: df,
                                jadwalBerikutnya: jadwalBerikutnya,
                                onTap: () {
                                  Navigator.push(
                                    ctx,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          MultiProvider(
                                            providers: [
                                              ChangeNotifierProvider.value(
                                                value: ctx
                                                    .read<ImunisasiProvider>(),
                                              ),
                                            ],
                                            child: DetailImunisasiKaderScreen(
                                              item: item,
                                              tanggalLahir:
                                                  balita?.tanggalLahir,
                                              jadwalBerikutnya:
                                                  jadwalBerikutnya,
                                            ),
                                          ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Filter Riwayat',
                style:
                    TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            ..._FilterImunisasi.values.map((f) {
              final label = f == _FilterImunisasi.semua
                  ? 'Semua Imunisasi'
                  : f == _FilterImunisasi.selesai
                      ? 'Selesai'
                      : 'Bulan Ini';
              return ListTile(
                leading: Icon(
                  f == _FilterImunisasi.semua
                      ? Icons.list_rounded
                      : f == _FilterImunisasi.selesai
                          ? Icons.check_circle_rounded
                          : Icons.calendar_month_rounded,
                  color: _filter == f
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                title: Text(
                  label,
                  style: TextStyle(
                    fontWeight: _filter == f
                        ? FontWeight.w700
                        : FontWeight.normal,
                    color: _filter == f
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                trailing: _filter == f
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _filter = f);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Balita Info Card ───────────────────────────────────────────────────────

class _BalitaInfoCard extends StatelessWidget {
  final String nama;
  final DateTime tanggalLahir;
  final String jenisKelamin;

  const _BalitaInfoCard({
    required this.nama,
    required this.tanggalLahir,
    required this.jenisKelamin,
  });

  @override
  Widget build(BuildContext context) {
    final usiaBulan =
        AgeCalculator.hitungUsiaBulanSekarang(tanggalLahir);
    final usiaFormatted = AgeCalculator.formatUsia(usiaBulan);
    final laki = jenisKelamin == 'laki-laki';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMint,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.child_care_rounded,
                  size: 28,
                  color: AppColors.primary,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: laki ? AppColors.info : Colors.pink,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Icon(
                    laki ? Icons.male_rounded : Icons.female_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'Usia $usiaFormatted',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '•',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    Icon(
                      laki ? Icons.male_rounded : Icons.female_rounded,
                      size: 15,
                      color: laki ? AppColors.info : Colors.pink,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      laki ? 'Laki-laki' : 'Perempuan',
                      style: TextStyle(
                        fontSize: 12,
                        color: laki ? AppColors.info : Colors.pink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.vaccines_rounded,
              size: 22,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Tabs ────────────────────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  final _FilterImunisasi current;
  final int jumlahBulanIni;
  final ValueChanged<_FilterImunisasi> onChange;

  const _FilterTabs({
    required this.current,
    required this.jumlahBulanIni,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _FilterChip(
            label: 'Semua',
            icon: Icons.list_rounded,
            isActive: current == _FilterImunisasi.semua,
            onTap: () => onChange(_FilterImunisasi.semua),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Selesai',
            icon: Icons.check_circle_rounded,
            isActive: current == _FilterImunisasi.selesai,
            onTap: () => onChange(_FilterImunisasi.selesai),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Bulan Ini',
            icon: Icons.calendar_month_rounded,
            isActive: current == _FilterImunisasi.bulanIni,
            badge: jumlahBulanIni > 0 ? jumlahBulanIni : null,
            onTap: () => onChange(_FilterImunisasi.bulanIni),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final int? badge;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : AppColors.border,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.3)
                      : AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isActive ? Colors.white : AppColors.warning,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Timeline Item ──────────────────────────────────────────────────────────

class _TimelineItem extends StatelessWidget {
  final ImunisasiModel item;
  final bool isLast;
  final DateTime? tanggalLahir;
  final DateFormat df;
  final JadwalImunisasiModel? jadwalBerikutnya;
  final VoidCallback onTap;

  const _TimelineItem({
    required this.item,
    required this.isLast,
    required this.tanggalLahir,
    required this.df,
    required this.onTap,
    this.jadwalBerikutnya,
  });

  @override
  Widget build(BuildContext context) {
    final usiaBulan = tanggalLahir != null
        ? AgeCalculator.hitungUsiaBulan(
            tanggalLahir!, item.tanggalImunisasi)
        : null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + circle
          SizedBox(
            width: 36,
            child: Column(
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
                    size: 16,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.success.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Card content
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.namaImunisasi ?? 'Imunisasi',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  AppColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            'Selesai',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      df.format(item.tanggalImunisasi),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (usiaBulan != null) ...[
                          const Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Usia: ${AgeCalculator.formatUsia(usiaBulan)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '•',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (item.namaPetugas != null) ...[
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              'Petugas: ${item.namaPetugas}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (jadwalBerikutnya != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Jadwal berikutnya: ',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'dd MMM yyyy',
                              'id_ID',
                            ).format(jadwalBerikutnya!.tanggalJadwal),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
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
      ),
    );
  }
}
