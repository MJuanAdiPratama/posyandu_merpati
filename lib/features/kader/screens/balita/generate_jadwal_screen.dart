import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/age_calculator.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/balita_model.dart';
import '../../providers/generate_jadwal_provider.dart';

class GenerateJadwalScreen extends StatelessWidget {
  final BalitaModel balita;

  const GenerateJadwalScreen({super.key, required this.balita});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GenerateJadwalProvider(),
      child: _GenerateJadwalBody(balita: balita),
    );
  }
}

class _GenerateJadwalBody extends StatefulWidget {
  final BalitaModel balita;
  const _GenerateJadwalBody({required this.balita});

  @override
  State<_GenerateJadwalBody> createState() => _GenerateJadwalBodyState();
}

class _GenerateJadwalBodyState extends State<_GenerateJadwalBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GenerateJadwalProvider>().muatDraft(widget.balita);
    });
  }

  Future<void> _simpan() async {
    final provider = context.read<GenerateJadwalProvider>();
    if (provider.jumlahDipilih == 0) {
      CustomSnackbar.gagal(context, 'Pilih minimal satu jadwal imunisasi');
      return;
    }
    final berhasil = await provider.simpan(widget.balita.id);
    if (!mounted) return;
    if (berhasil) {
      CustomSnackbar.sukses(
        context,
        '${provider.jumlahDipilih} jadwal imunisasi berhasil disimpan',
      );
      Navigator.pop(context, true);
    } else {
      CustomSnackbar.gagal(context, provider.error ?? 'Gagal menyimpan jadwal');
    }
  }

  @override
  Widget build(BuildContext context) {
    final balita = widget.balita;
    final usia = AgeCalculator.formatUsiaDetail(balita.tanggalLahir);
    final df = DateFormat('dd MMM yyyy', 'id_ID');

    return Scaffold(
      appBar: GradientAppBar(title: 'Jadwal Imunisasi'),
      body: Consumer<GenerateJadwalProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading && provider.daftar.isEmpty) {
            return const LoadingWidget();
          }

          return Column(
            children: [
              // ── Info balita ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SoftHeaderCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: balita.jenisKelamin == 'Perempuan'
                                  ? const Color(0xFFFFE4EE)
                                  : AppColors.surfaceTeal,
                              shape: BoxShape.circle,
                            ),
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
                                Text(
                                  '${balita.jenisKelamin} • $usia',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Centang jadwal imunisasi yang ingin diaktifkan. '
                                'Jadwal yang sudah lewat akan ditandai Terlambat.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Header pilih semua ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${provider.jumlahDipilih} dari ${provider.daftar.length} dipilih',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          provider.toggleSemua(!provider.semuaDipilih),
                      child: Text(
                        provider.semuaDipilih
                            ? 'Batal Pilih Semua'
                            : 'Pilih Semua',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Daftar jadwal ────────────────────────────────────────────
              Expanded(
                child: provider.daftar.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada jenis imunisasi.\nTambahkan jenis imunisasi terlebih dahulu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: provider.daftar.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final item = provider.daftar[i];
                          final isTerlambat = item.status == 'terlambat';
                          final statusColor = isTerlambat
                              ? AppColors.error
                              : AppColors.success;

                          return InkWell(
                            onTap: () => provider.toggle(i),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: item.dipilih
                                    ? AppColors.primary.withValues(alpha: 0.05)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: item.dipilih
                                      ? AppColors.primary.withValues(alpha: 0.4)
                                      : AppColors.border,
                                  width: item.dipilih ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Checkbox
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Checkbox(
                                      value: item.dipilih,
                                      onChanged: (_) => provider.toggle(i),
                                      activeColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  // Badge usia
                                  Container(
                                    width: 52,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${item.jenisImunisasi.usiaBulan}',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                            color: statusColor,
                                          ),
                                        ),
                                        Text(
                                          item.jenisImunisasi.usiaBulan == 0
                                              ? 'lahir'
                                              : 'bln',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: statusColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Info
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.jenisImunisasi.namaImunisasi,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                              color: item.dipilih
                                                  ? AppColors.textPrimary
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today_outlined,
                                                size: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                df.format(item.tanggalJadwal),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isTerlambat
                                                  ? 'Terlambat'
                                                  : 'Terjadwal',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // ── Tombol simpan ────────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (provider.isLoading || provider.jumlahDipilih == 0)
                          ? null
                          : _simpan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: provider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Simpan ${provider.jumlahDipilih} Jadwal',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
