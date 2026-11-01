import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../data/models/jadwal_posyandu_model.dart';
import '../../../../routes/app_routes.dart';
import '../../providers/jadwal_posyandu_provider.dart';
import '../../providers/laporan_provider.dart';
import '../widgets/small_date_badge.dart';

// ─── Jadwal & Laporan Tab ────────────────────────────────────────────────────

class JadwalLaporanTab extends StatelessWidget {
  const JadwalLaporanTab({super.key});

  void _showJadwalDetail(
    BuildContext context,
    JadwalPosyanduModel jadwal,
    bool isPast,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SmallDateBadge(date: jadwal.tanggal, muted: isPast),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          jadwal.judul,
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        StatusBadge(
                          label: isPast ? 'Selesai' : 'Akan datang',
                          color: isPast
                              ? AppColors.textSecondary
                              : AppColors.success,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InfoTextRow(
                icon: Icons.calendar_month_outlined,
                text: DateFormat(
                  'EEEE, dd MMMM yyyy',
                  'id_ID',
                ).format(jadwal.tanggal),
              ),
              const SizedBox(height: 8),
              InfoTextRow(
                icon: Icons.schedule_outlined,
                text:
                    '${jadwal.jamMulai ?? '--:--'}${jadwal.jamSelesai != null ? ' - ${jadwal.jamSelesai}' : ''} WIB',
              ),
              const SizedBox(height: 8),
              InfoTextRow(
                icon: Icons.place_outlined,
                text: jadwal.lokasi ?? 'Lokasi belum diisi',
              ),
              if (jadwal.deskripsi != null && jadwal.deskripsi!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  jadwal.deskripsi!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: const Text('Kelola Jadwal'),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.jadwalPosyandu);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JadwalPosyanduProvider>(
      builder: (_, provider, __) {
        final daftar = provider.daftar;
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: provider.muatDaftar,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              const _JadwalLaporanHeader(),
              Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    children: [
                      const SizedBox(height: 26),
                      SectionTitle(
                        title: 'Jadwal Posyandu Terdekat',
                        action: 'Lihat semua',
                        onAction: () async {
                          await context
                              .read<JadwalPosyanduProvider>()
                              .muatDaftar();
                          if (!context.mounted) return;
                          Navigator.pushNamed(
                            context,
                            AppRoutes.jadwalPosyandu,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      if (provider.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        () {
                          final today = DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                          );
                          final mendatang = daftar
                              .where((j) => !j.tanggal.isBefore(today))
                              .toList();
                          if (mendatang.isEmpty) {
                            return _EmptyInlineCard(
                              icon: Icons.event_busy_rounded,
                              title: 'Belum ada jadwal Posyandu mendatang',
                              subtitle:
                                  'Tekan tombol + untuk menambah agenda baru.',
                            );
                          }
                          return Column(
                            children: mendatang.take(3).map((jadwal) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _JadwalPreviewCard(
                                  title: jadwal.judul,
                                  date: jadwal.tanggal,
                                  time:
                                      '${jadwal.jamMulai ?? '--:--'}${jadwal.jamSelesai != null ? ' - ${jadwal.jamSelesai}' : ''} WIB',
                                  location:
                                      jadwal.lokasi ?? 'Lokasi belum diisi',
                                  isPast: false,
                                  onTap: () =>
                                      _showJadwalDetail(context, jadwal, false),
                                ),
                              );
                            }).toList(),
                          );
                        }(),
                      const SizedBox(height: 18),
                      const _LaporanEksporPanel(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _JadwalLaporanHeader extends StatelessWidget {
  const _JadwalLaporanHeader();

  @override
  Widget build(BuildContext context) {
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
      child: const SafeArea(
        bottom: false,
        child: Row(
          children: [
            SizedBox(width: 48),
            Expanded(
              child: Text(
                'Jadwal & Laporan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

class _LaporanEksporPanel extends StatefulWidget {
  const _LaporanEksporPanel();

  @override
  State<_LaporanEksporPanel> createState() => _LaporanEksporPanelState();
}

class _LaporanEksporPanelState extends State<_LaporanEksporPanel> {
  String _jenis = 'imunisasi';
  DateTime _periodeBulan = DateTime.now();

  String get _periodeLabel =>
      DateFormat('MMMM yyyy', 'id_ID').format(_periodeBulan);

  Future<void> _pilihPeriode() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _periodeBulan,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Pilih Bulan & Tahun Laporan',
    );
    if (picked != null) {
      setState(() => _periodeBulan = DateTime(picked.year, picked.month));
    }
  }

  Future<void> _ekspor(String format) async {
    final provider = context.read<LaporanProvider>();
    final isPdf = format == 'pdf';
    final file = _jenis == 'balita'
        ? isPdf
              ? await provider.eksporBalitaPDF()
              : await provider.eksporBalitaExcel()
        : isPdf
        ? await provider.eksporImunisasiPDF(_periodeBulan)
        : await provider.eksporImunisasiExcel(_periodeBulan);

    if (!mounted) return;
    if (file == null) {
      CustomSnackbar.gagal(context, provider.error ?? 'Gagal mengekspor data');
      return;
    }

    CustomSnackbar.sukses(
      context,
      isPdf ? 'PDF berhasil dibuat' : 'Excel/CSV berhasil dibuat',
    );
    if (isPdf) {
      await Printing.sharePdf(bytes: await file.readAsBytes());
    } else {
      await OpenFile.open(file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LaporanProvider>(
      builder: (_, provider, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'Laporan & Ekspor Data'),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Jenis Laporan',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _jenis,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'imunisasi',
                          child: Text('Laporan Imunisasi Bulanan'),
                        ),
                        DropdownMenuItem(
                          value: 'balita',
                          child: Text('Laporan Data Balita'),
                        ),
                      ],
                      onChanged: provider.isLoading
                          ? null
                          : (value) {
                              if (value != null) setState(() => _jenis = value);
                            },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Periode',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _jenis == 'imunisasi' && !provider.isLoading
                            ? _pilihPeriode
                            : null,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _jenis == 'imunisasi'
                                      ? _periodeLabel
                                      : 'Semua data',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Icon(
                                _jenis == 'imunisasi'
                                    ? Icons.edit_calendar_rounded
                                    : Icons.calendar_today_rounded,
                                color: _jenis == 'imunisasi'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (provider.isLoading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(color: AppColors.primary),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ExportButton(
                            icon: Icons.picture_as_pdf_rounded,
                            label: 'Export PDF',
                            color: AppColors.error,
                            onTap: provider.isLoading
                                ? null
                                : () => _ekspor('pdf'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ExportButton(
                            icon: Icons.table_chart_rounded,
                            label: 'Export Excel/CSV',
                            color: AppColors.success,
                            onTap: provider.isLoading
                                ? null
                                : () => _ekspor('excel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JadwalPreviewCard extends StatelessWidget {
  final String title;
  final DateTime date;
  final String time;
  final String location;
  final bool isPast;
  final VoidCallback? onTap;

  const _JadwalPreviewCard({
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.isPast,
    this.onTap,
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
          child: Row(
            children: [
              SmallDateBadge(date: date, muted: isPast),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: isPast
                                  ? AppColors.textDisabled
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        StatusBadge(
                          label: isPast ? 'Selesai' : 'Akan datang',
                          color: isPast
                              ? AppColors.textSecondary
                              : AppColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    InfoTextRow(icon: Icons.schedule_outlined, text: time),
                    const SizedBox(height: 4),
                    InfoTextRow(icon: Icons.place_outlined, text: location),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyInlineCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyInlineCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconBadge(icon: icon, color: AppColors.textSecondary, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
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
      ),
    );
  }
}
