import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/age_calculator.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/growth_status_badge.dart';
import '../../../../data/models/balita_model.dart';
import '../../../../data/models/jadwal_imunisasi_model.dart';
import '../../../../data/models/pertumbuhan_model.dart';
import '../../../../routes/app_routes.dart';
import '../../providers/balita_kader_provider.dart';
import '../../providers/imunisasi_provider.dart';
import '../../providers/jadwal_imunisasi_kader_provider.dart';
import '../../providers/jenis_imunisasi_provider.dart';
import '../../providers/pertumbuhan_kader_provider.dart';
import '../imunisasi/daftar_jadwal_imunisasi_screen.dart';
import '../imunisasi/input_imunisasi_screen.dart';
import '../imunisasi/riwayat_imunisasi_kader_screen.dart';
import '../pertumbuhan/riwayat_pertumbuhan_kader_screen.dart';

class DetailBalitaScreen extends StatefulWidget {
  const DetailBalitaScreen({super.key});

  @override
  State<DetailBalitaScreen> createState() => _DetailBalitaScreenState();
}

class _DetailBalitaScreenState extends State<DetailBalitaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _muatData();
    });
  }

  void _muatData() {
    final balita = context.read<BalitaKaderProvider>().selected;
    if (balita == null) return;
    context.read<JadwalImunisasiKaderProvider>().muatHariIniByBalita(balita.id);
    context.read<PertumbuhanKaderProvider>().muatByBalita(balita.id);
  }

  Future<void> _bukaInputImunisasiDariJadwal(
    JadwalImunisasiModel jadwal,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(
              value: context.read<BalitaKaderProvider>(),
            ),
            ChangeNotifierProvider.value(
              value: context.read<ImunisasiProvider>(),
            ),
            ChangeNotifierProvider.value(
              value: context.read<JenisImunisasiProvider>(),
            ),
          ],
          child: InputImunisasiScreen(jadwalAktif: jadwal),
        ),
      ),
    );
    if (result == true && mounted) _muatData();
  }

  @override
  Widget build(BuildContext context) {
    final balita = context.watch<BalitaKaderProvider>().selected;
    if (balita == null) {
      return const Scaffold(body: Center(child: Text('Data tidak ditemukan')));
    }

    final pertumbuhanProvider = context.watch<PertumbuhanKaderProvider>();
    final jadwalHariIni = context
        .watch<JadwalImunisasiKaderProvider>()
        .jadwalHariIni;
    final pertumbuhanTerakhir = pertumbuhanProvider.daftar.isEmpty
        ? null
        : pertumbuhanProvider.daftar.last;

    final bolehInput = balita.statusVerifikasi == 'disetujui';

    void bukaInputImunisasi() {
      if (!bolehInput) {
        _showBelumVerifikasi();
        return;
      }
      Navigator.pushNamed(context, AppRoutes.inputImunisasi);
    }

    void bukaInputPertumbuhan() {
      if (!bolehInput) {
        _showBelumVerifikasi();
        return;
      }
      Navigator.pushNamed(
        context,
        AppRoutes.inputPertumbuhan,
        arguments: context.read<PertumbuhanKaderProvider>(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => _muatData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _DetailHeader(
                onBack: () => Navigator.pop(context),
                onEdit: () =>
                    Navigator.pushNamed(context, AppRoutes.editBalita),
                onDelete: () => _hapusBalita(balita),
              ),
              Transform.translate(
                offset: const Offset(0, -22),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    children: [
                      _BalitaHeroCard(balita: balita),
                      if (jadwalHariIni.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _JadwalHariIniBanner(
                          daftar: jadwalHariIni,
                          onInput: bolehInput
                              ? (jadwal) =>
                                    _bukaInputImunisasiDariJadwal(jadwal)
                              : null,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _IdentityCard(balita: balita),
                      const SizedBox(height: 12),
                      _HealthSummaryCard(pertumbuhan: pertumbuhanTerakhir),
                      const SizedBox(height: 12),
                      _QuickActionsCard(
                        onJadwal: _bukaJadwalImunisasi,
                        onInputImunisasi: bukaInputImunisasi,
                        onInputPertumbuhan: bukaInputPertumbuhan,
                        onRiwayat: _bukaRiwayatImunisasi,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _bukaRiwayatPertumbuhan,
                        icon: const Icon(Icons.show_chart_rounded),
                        label: const Text('Riwayat Pertumbuhan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBelumVerifikasi() {
    CustomSnackbar.gagal(
      context,
      'Balita belum diverifikasi. Verifikasi data balita terlebih dahulu.',
    );
  }

  void _bukaJadwalImunisasi() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(
              value: context.read<BalitaKaderProvider>(),
            ),
            ChangeNotifierProvider.value(
              value: context.read<ImunisasiProvider>(),
            ),
            ChangeNotifierProvider.value(
              value: context.read<JenisImunisasiProvider>(),
            ),
            ChangeNotifierProvider(
              create: (_) => JadwalImunisasiKaderProvider(),
            ),
          ],
          child: const DaftarJadwalImunisasiScreen(),
        ),
      ),
    );
  }

  void _bukaRiwayatImunisasi() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(
              value: context.read<BalitaKaderProvider>(),
            ),
            ChangeNotifierProvider.value(
              value: context.read<ImunisasiProvider>(),
            ),
          ],
          child: const RiwayatImunisasiKaderScreen(),
        ),
      ),
    );
  }

  void _bukaRiwayatPertumbuhan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(
              value: context.read<BalitaKaderProvider>(),
            ),
            ChangeNotifierProvider.value(
              value: context.read<PertumbuhanKaderProvider>(),
            ),
          ],
          child: const RiwayatPertumbuhanKaderScreen(),
        ),
      ),
    );
  }

  Future<void> _hapusBalita(BalitaModel balita) async {
    final konfirmasi = await showConfirmationDialog(
      context: context,
      title: 'Hapus Data Balita',
      message:
          'Data ${balita.nama} akan dihapus dari daftar balita. Tindakan ini tidak dapat dibatalkan.',
      icon: Icons.delete_outline_rounded,
    );
    if (konfirmasi != true || !mounted) return;
    final berhasil = await context.read<BalitaKaderProvider>().hapus(balita.id);
    if (!mounted) return;
    if (berhasil) {
      CustomSnackbar.sukses(context, AppStrings.berhasilDihapus);
      Navigator.pop(context);
    } else {
      CustomSnackbar.gagal(context, AppStrings.gagalMenyimpan);
    }
  }
}

class _DetailHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DetailHeader({
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00B7B0), AppColors.primary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: onBack,
            ),
            const Expanded(
              child: Text(
                'Detail Balita',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _HeaderActionBox(onEdit: onEdit, onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}

class _HeaderActionBox extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HeaderActionBox({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HeaderActionButton(
            icon: Icons.edit_rounded,
            tooltip: 'Edit Balita',
            onTap: onEdit,
          ),
          Container(
            width: 1,
            height: 22,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          _HeaderActionButton(
            icon: Icons.delete_rounded,
            tooltip: 'Hapus Balita',
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _BalitaHeroCard extends StatelessWidget {
  final BalitaModel balita;

  const _BalitaHeroCard({required this.balita});

  @override
  Widget build(BuildContext context) {
    final isBoy = balita.jenisKelamin == 'Laki-laki';
    final usia = AgeCalculator.formatUsiaDariTanggalLahir(balita.tanggalLahir);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: isBoy
                      ? AppColors.surfaceTeal
                      : const Color(0xFFFFE4EE),
                  child: Icon(
                    isBoy ? Icons.boy_rounded : Icons.girl_rounded,
                    color: isBoy ? AppColors.primary : const Color(0xFFE91E8C),
                    size: 46,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        balita.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Usia $usia',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isBoy ? Icons.male_rounded : Icons.female_rounded,
                            color: isBoy ? AppColors.info : AppColors.error,
                            size: 15,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              balita.jenisKelamin,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _StatusChip(status: balita.statusVerifikasi),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _CompactInfoLine(
                  icon: Icons.phone_outlined,
                  text: '${balita.namaOrtu}  •  ${balita.kontakOrtu ?? '-'}',
                ),
                const SizedBox(height: 8),
                _CompactInfoLine(
                  icon: Icons.location_on_rounded,
                  text: balita.alamat ?? '-',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final BalitaModel balita;

  const _IdentityCard({required this.balita});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

    return _PanelCard(
      title: 'Identitas Balita',
      child: Column(
        children: [
          _DetailInfoRow(
            icon: Icons.badge_outlined,
            label: 'NIK',
            value: balita.nik,
          ),
          _DetailInfoRow(
            icon: Icons.place_outlined,
            label: 'Tempat Lahir',
            value: balita.tempatLahir ?? '-',
          ),
          _DetailInfoRow(
            icon: Icons.calendar_month_outlined,
            label: 'Tanggal Lahir',
            value: dateFormat.format(balita.tanggalLahir),
          ),
          _DetailInfoRow(
            icon: Icons.people_outline_rounded,
            label: 'Nama Orang Tua',
            value: balita.namaOrtu,
          ),
          _DetailInfoRow(
            icon: Icons.phone_outlined,
            label: 'Nomor HP Orang Tua',
            value: balita.kontakOrtu ?? '-',
          ),
          _DetailInfoRow(
            icon: Icons.home_outlined,
            label: 'Alamat',
            value: balita.alamat ?? '-',
          ),
          _DetailInfoRow(
            icon: Icons.verified_outlined,
            label: 'Status Verifikasi',
            valueWidget: Align(
              alignment: Alignment.centerLeft,
              child: _StatusChip(status: balita.statusVerifikasi),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthSummaryCard extends StatelessWidget {
  final PertumbuhanModel? pertumbuhan;

  const _HealthSummaryCard({required this.pertumbuhan});

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Ringkasan Kesehatan Terakhir',
      child: pertumbuhan == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada data pertumbuhan.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : Row(
              children: [
                _HealthMetric(
                  icon: Icons.monitor_weight_rounded,
                  label: 'Berat Badan',
                  value: '${pertumbuhan!.beratBadan.toStringAsFixed(1)} kg',
                  date: DateFormat(
                    'dd MMM yyyy',
                    'id_ID',
                  ).format(pertumbuhan!.tanggalPemeriksaan),
                  color: AppColors.success,
                ),
                _MetricDivider(),
                _HealthMetric(
                  icon: Icons.height_rounded,
                  label: 'Tinggi Badan',
                  value: '${pertumbuhan!.tinggiBadan.toStringAsFixed(1)} cm',
                  date: DateFormat(
                    'dd MMM yyyy',
                    'id_ID',
                  ).format(pertumbuhan!.tanggalPemeriksaan),
                  color: AppColors.info,
                ),
                _MetricDivider(),
                _HealthMetric(
                  icon: Icons.sentiment_satisfied_alt_rounded,
                  label: 'Status Gizi',
                  value: pertumbuhan!.statusGizi ?? 'Normal',
                  date: 'Terakhir',
                  color: growthStatusColor(pertumbuhan!.statusGizi ?? 'Normal'),
                ),
              ],
            ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  final VoidCallback onJadwal;
  final VoidCallback onInputImunisasi;
  final VoidCallback onInputPertumbuhan;
  final VoidCallback onRiwayat;

  const _QuickActionsCard({
    required this.onJadwal,
    required this.onInputImunisasi,
    required this.onInputPertumbuhan,
    required this.onRiwayat,
  });

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Aksi Cepat',
      child: Row(
        children: [
          _ActionTile(
            icon: Icons.calendar_month_rounded,
            label: 'Jadwal\nImunisasi',
            color: const Color(0xFF7E57C2),
            onTap: onJadwal,
          ),
          const SizedBox(width: 8),
          _ActionTile(
            icon: Icons.vaccines_rounded,
            label: 'Input\nImunisasi',
            color: AppColors.info,
            onTap: onInputImunisasi,
          ),
          const SizedBox(width: 8),
          _ActionTile(
            icon: Icons.trending_up_rounded,
            label: 'Input\nPertumbuhan',
            color: AppColors.success,
            onTap: onInputPertumbuhan,
          ),
          const SizedBox(width: 8),
          _ActionTile(
            icon: Icons.article_rounded,
            label: 'Riwayat',
            color: AppColors.primary,
            onTap: onRiwayat,
          ),
        ],
      ),
    );
  }
}

class _JadwalHariIniBanner extends StatelessWidget {
  final List<JadwalImunisasiModel> daftar;
  final void Function(JadwalImunisasiModel)? onInput;

  const _JadwalHariIniBanner({required this.daftar, this.onInput});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.today_rounded, color: AppColors.warning, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Jadwal Imunisasi Hari Ini',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.warning,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...daftar.map(
            (jadwal) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      jadwal.namaImunisasi ?? 'Imunisasi',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (onInput != null)
                    TextButton(
                      onPressed: () => onInput!(jadwal),
                      child: const Text('Input Sekarang'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _PanelCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _DetailInfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 17),
          const SizedBox(width: 10),
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(':  ', style: TextStyle(color: AppColors.textSecondary)),
          Expanded(
            child:
                valueWidget ??
                Text(
                  value ?? '-',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _HealthMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String date;
  final Color color;

  const _HealthMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.date,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color == AppColors.info ? AppColors.textPrimary : color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            date,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppColors.divider,
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 94,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CompactInfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'disetujui' => AppColors.success,
      'ditolak' => AppColors.error,
      _ => AppColors.warning,
    };
    final label = switch (status) {
      'disetujui' => 'Disetujui',
      'ditolak' => 'Ditolak',
      _ => 'Pending',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 5),
          Icon(
            status == 'disetujui'
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            color: color,
            size: 15,
          ),
        ],
      ),
    );
  }
}
