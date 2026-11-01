import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../data/models/balita_model.dart';
import '../../../../data/repositories/balita_repository.dart';
import '../../providers/laporan_provider.dart';

class LaporanScreen extends StatelessWidget {
  const LaporanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: AppStrings.laporan),
      body: Consumer<LaporanProvider>(
        builder: (_, provider, __) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.isLoading)
                const LinearProgressIndicator(color: AppColors.primary),
              const KaderHeroPanel(
                title: 'Laporan Admin',
                subtitle:
                    'Ekspor data Posyandu dalam format PDF, Excel, atau CSV untuk arsip layanan.',
                icon: Icons.assessment_rounded,
              ),
              const SizedBox(height: 14),
              const SectionTitle(title: 'Pilih Jenis Laporan'),
              const SizedBox(height: 10),
              _LaporanCard(
                title: 'Laporan Data Balita',
                subtitle: 'Semua profil balita dan status verifikasi',
                icon: Icons.child_care,
                color: AppColors.primary,
                onPdf: () => _eksporPDF(context, provider, 'balita'),
                onExcel: () => _eksporExcel(context, provider, 'balita'),
              ),
              const SizedBox(height: 8),
              _LaporanCard(
                title: 'Laporan Imunisasi Bulan Ini',
                subtitle: 'Catatan imunisasi pada bulan berjalan',
                icon: Icons.vaccines,
                color: AppColors.secondary,
                onPdf: () => _eksporPDF(context, provider, 'imunisasi'),
                onExcel: () => _eksporExcel(context, provider, 'imunisasi'),
              ),
              const SizedBox(height: 8),
              _LaporanCard(
                title: 'Laporan Pertumbuhan Balita',
                subtitle: 'Riwayat berat dan tinggi badan per balita',
                icon: Icons.show_chart,
                color: const Color(0xFF7E57C2),
                onPdf: () => _eksporDenganPilihBalita(
                  context,
                  provider,
                  'pertumbuhan',
                  'pdf',
                ),
                onExcel: () => _eksporDenganPilihBalita(
                  context,
                  provider,
                  'pertumbuhan',
                  'excel',
                ),
              ),
              const SizedBox(height: 8),
              _LaporanCard(
                title: 'Laporan Jadwal Imunisasi',
                subtitle: 'Jadwal imunisasi lanjutan per balita',
                icon: Icons.event_note,
                color: const Color(0xFFFF7043),
                onPdf: () => _eksporDenganPilihBalita(
                  context,
                  provider,
                  'jadwal_imunisasi',
                  'pdf',
                ),
                onExcel: () => _eksporDenganPilihBalita(
                  context,
                  provider,
                  'jadwal_imunisasi',
                  'excel',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _eksporPDF(
    BuildContext context,
    LaporanProvider provider,
    String jenis,
  ) async {
    File? file;
    if (jenis == 'balita') {
      file = await provider.eksporBalitaPDF();
    } else {
      file = await provider.eksporImunisasiPDF();
    }
    if (!context.mounted) return;
    if (file != null) {
      CustomSnackbar.sukses(context, 'PDF berhasil dibuat');
      await Printing.sharePdf(bytes: await file.readAsBytes());
    } else {
      CustomSnackbar.gagal(
        context,
        provider.error ?? AppStrings.gagalMenyimpan,
      );
    }
  }

  Future<void> _eksporExcel(
    BuildContext context,
    LaporanProvider provider,
    String jenis,
  ) async {
    File? file;
    if (jenis == 'balita') {
      file = await provider.eksporBalitaExcel();
    } else {
      file = await provider.eksporImunisasiExcel();
    }
    if (!context.mounted) return;
    if (file != null) {
      CustomSnackbar.sukses(context, 'Excel berhasil dibuat');
      await OpenFile.open(file.path);
    } else {
      CustomSnackbar.gagal(
        context,
        provider.error ?? AppStrings.gagalMenyimpan,
      );
    }
  }

  Future<void> _eksporDenganPilihBalita(
    BuildContext context,
    LaporanProvider provider,
    String jenis,
    String format,
  ) async {
    List<BalitaModel> daftarBalita;
    try {
      daftarBalita = await BalitaRepository().getDaftarBalita();
    } catch (_) {
      if (!context.mounted) return;
      CustomSnackbar.gagal(context, 'Gagal memuat daftar balita');
      return;
    }

    if (!context.mounted) return;
    if (daftarBalita.isEmpty) {
      CustomSnackbar.gagal(context, 'Belum ada data balita');
      return;
    }

    final balitaTerpilih = await showDialog<BalitaModel>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Pilih Balita'),
        children: daftarBalita
            .map(
              (b) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, b),
                child: Text(b.nama),
              ),
            )
            .toList(),
      ),
    );

    if (balitaTerpilih == null || !context.mounted) return;

    File? file;
    if (jenis == 'pertumbuhan') {
      file = format == 'pdf'
          ? await provider.eksporPertumbuhanPDFByBalita(
              balitaTerpilih.id,
              balitaTerpilih.nama,
            )
          : await provider.eksporPertumbuhanExcelByBalita(
              balitaTerpilih.id,
              balitaTerpilih.nama,
            );
    } else {
      file = format == 'pdf'
          ? await provider.eksporJadwalImunisasiPDFByBalita(
              balitaTerpilih.id,
              balitaTerpilih.nama,
            )
          : await provider.eksporJadwalImunisasiExcelByBalita(
              balitaTerpilih.id,
              balitaTerpilih.nama,
            );
    }

    if (!context.mounted) return;
    if (file != null) {
      final label = format == 'pdf' ? 'PDF' : 'Excel';
      CustomSnackbar.sukses(context, '$label berhasil dibuat');
      if (format == 'pdf') {
        await Printing.sharePdf(bytes: await file.readAsBytes());
      } else {
        await OpenFile.open(file.path);
      }
    } else {
      CustomSnackbar.gagal(
        context,
        provider.error ?? AppStrings.gagalMenyimpan,
      );
    }
  }
}

class _LaporanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onPdf;
  final VoidCallback onExcel;

  const _LaporanCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onPdf,
    required this.onExcel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(icon: icon, color: color, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        subtitle,
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      Icons.picture_as_pdf,
                      color: AppColors.error,
                    ),
                    label: const Text(
                      'Ekspor PDF',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onPressed: onPdf,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      Icons.table_chart,
                      color: AppColors.success,
                    ),
                    label: const Text(
                      'Excel/CSV',
                      style: TextStyle(color: AppColors.success),
                    ),
                    onPressed: onExcel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.success),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
