import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/age_calculator.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../data/models/imunisasi_model.dart';
import '../../../../data/models/jadwal_imunisasi_model.dart';
import '../../providers/imunisasi_provider.dart';

class DetailImunisasiKaderScreen extends StatelessWidget {
  final ImunisasiModel item;
  final DateTime? tanggalLahir;
  final JadwalImunisasiModel? jadwalBerikutnya;

  const DetailImunisasiKaderScreen({
    super.key,
    required this.item,
    this.tanggalLahir,
    this.jadwalBerikutnya,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMMM yyyy', 'id_ID');
    final usiaBulan = tanggalLahir != null
        ? AgeCalculator.hitungUsiaBulan(tanggalLahir!, item.tanggalImunisasi)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'Detail Imunisasi',
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (v) async {
              if (v == 'hapus') {
                _konfirmasiHapus(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'hapus',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text('Hapus', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top card — nama vaksin + tanggal + usia
            _VaksinHeaderCard(item: item, df: df, usiaBulan: usiaBulan),
            const SizedBox(height: 16),

            // Informasi Detail
            _SectionCard(
              title: 'Informasi Detail',
              children: [
                _InfoRow(
                  icon: Icons.child_care_rounded,
                  label: 'Balita',
                  value: item.namaBalita ?? '-',
                ),
                _InfoRow(
                  icon: Icons.vaccines_rounded,
                  label: 'Jenis Imunisasi',
                  value: item.namaImunisasi ?? '-',
                ),
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Tanggal Imunisasi',
                  value: df.format(item.tanggalImunisasi),
                ),
                _InfoRow(
                  icon: Icons.access_time_rounded,
                  label: 'Usia Saat Imunisasi',
                  value: usiaBulan != null
                      ? AgeCalculator.formatUsia(usiaBulan)
                      : '-',
                ),
                if (item.beratBadan != null)
                  _InfoRow(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Berat Badan',
                    value: '${item.beratBadan} kg',
                  ),
                if (item.tinggiBadan != null)
                  _InfoRow(
                    icon: Icons.straighten_rounded,
                    label: 'Tinggi Badan',
                    value: '${item.tinggiBadan} cm',
                  ),
                if (item.suhuBadan != null)
                  _InfoRow(
                    icon: Icons.thermostat_rounded,
                    label: 'Suhu Badan',
                    value: '${item.suhuBadan} °C',
                  ),
                if (item.lingkarKepala != null)
                  _InfoRow(
                    icon: Icons.radio_button_unchecked_rounded,
                    label: 'Lingkar Kepala',
                    value: '${item.lingkarKepala} cm',
                  ),
                if (item.namaPetugas != null)
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Petugas',
                    value: item.namaPetugas!,
                  ),
                if (item.catatan != null && item.catatan!.isNotEmpty)
                  _InfoRow(
                    icon: Icons.notes_rounded,
                    label: 'Catatan',
                    value: item.catatan!,
                    isMultiLine: true,
                  ),
                if (jadwalBerikutnya != null)
                  _InfoRow(
                    icon: Icons.event_available_rounded,
                    label: 'Jadwal Berikutnya',
                    value:
                        '${DateFormat('dd MMMM yyyy', 'id_ID').format(jadwalBerikutnya!.tanggalJadwal)}'
                        '${jadwalBerikutnya!.namaImunisasi != null ? '\n(${jadwalBerikutnya!.namaImunisasi})' : ''}',
                    valueColor: AppColors.primary,
                    isMultiLine: true,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Status Pencatatan
            _StatusPencatatanCard(item: item, df: df),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _konfirmasiHapus(BuildContext context) async {
    final konfirmasi = await showConfirmationDialog(
      context: context,
      title: 'Hapus Data Imunisasi',
      message:
          'Hapus data imunisasi "${item.namaImunisasi ?? 'ini'}"? Data tidak dapat dikembalikan.',
      icon: Icons.delete_outline_rounded,
    );
    if (konfirmasi != true || !context.mounted) return;

    final berhasil = await context.read<ImunisasiProvider>().hapusImunisasi(
      item.id,
    );
    if (!context.mounted) return;
    if (berhasil) {
      Navigator.pop(context);
      CustomSnackbar.sukses(context, 'Data imunisasi berhasil dihapus');
    } else {
      CustomSnackbar.gagal(context, 'Gagal menghapus data');
    }
  }
}

// ─── Vaksin Header Card ─────────────────────────────────────────────────────

class _VaksinHeaderCard extends StatelessWidget {
  final ImunisasiModel item;
  final DateFormat df;
  final int? usiaBulan;

  const _VaksinHeaderCard({
    required this.item,
    required this.df,
    this.usiaBulan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceMint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.vaccines_rounded,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.namaImunisasi ?? 'Imunisasi',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
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
                const SizedBox(height: 6),
                Text(
                  'Tanggal Imunisasi',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  df.format(item.tanggalImunisasi),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (usiaBulan != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Usia saat imunisasi',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    AgeCalculator.formatUsia(usiaBulan!),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Card ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 16),
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: child,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Info Row ───────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isMultiLine;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isMultiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: isMultiLine
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppColors.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
              height: isMultiLine ? 1.4 : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Status Pencatatan Card ─────────────────────────────────────────────────

class _StatusPencatatanCard extends StatelessWidget {
  final ImunisasiModel item;
  final DateFormat df;

  const _StatusPencatatanCard({required this.item, required this.df});

  @override
  Widget build(BuildContext context) {
    final dfWaktu = DateFormat('dd MMMM yyyy, HH.mm', 'id_ID');
    final waktu = dfWaktu.format(item.createdAt);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
            child: Row(
              children: const [
                Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Status Pencatatan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          _StatusRow(
            icon: Icons.send_rounded,
            label: 'Notifikasi telah dikirim ke orang tua',
            waktu: waktu,
            isDone: item.namaBalita != null,
          ),
          const SizedBox(height: 2),
          _StatusRow(
            icon: Icons.bar_chart_rounded,
            label: 'Data pertumbuhan diperbarui',
            waktu: waktu,
            isDone: item.beratBadan != null && item.tinggiBadan != null,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String waktu;
  final bool isDone;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.waktu,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.border.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isDone ? AppColors.primary : AppColors.textDisabled,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDone
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDone ? waktu : 'Belum tersedia',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isDone)
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
        ],
      ),
    );
  }
}
