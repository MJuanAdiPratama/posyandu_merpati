import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/age_calculator.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/balita_model.dart';
import '../../../../data/models/jadwal_imunisasi_model.dart';
import '../../providers/balita_kader_provider.dart';
import '../../providers/imunisasi_provider.dart';
import '../../providers/jadwal_imunisasi_kader_provider.dart';
import '../../providers/jenis_imunisasi_provider.dart';
import '../balita/generate_jadwal_screen.dart';
import 'input_imunisasi_screen.dart';

class DaftarJadwalImunisasiScreen extends StatefulWidget {
  final bool standalone;

  const DaftarJadwalImunisasiScreen({super.key, this.standalone = true});

  @override
  State<DaftarJadwalImunisasiScreen> createState() =>
      _DaftarJadwalImunisasiScreenState();
}

class _DaftarJadwalImunisasiScreenState
    extends State<DaftarJadwalImunisasiScreen> {
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _muat());
  }

  void _muat() {
    final balita = context.read<BalitaKaderProvider>().selected;
    if (balita != null) {
      context.read<JadwalImunisasiKaderProvider>().muat(balita.id);
    }
  }

  Future<void> _bukaInputImunisasi(
    BuildContext context,
    BalitaModel balita,
    JadwalImunisasiModel jadwal,
  ) async {
    final jadwalProvider = context.read<JadwalImunisasiKaderProvider>();
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

    if (result == true && mounted) {
      jadwalProvider.tandaiSelesai(jadwal.id);
    }
  }

  bool _bisaInput(JadwalImunisasiModel jadwal) {
    if (jadwal.status == 'selesai') return false;
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final tgl = DateTime(
      jadwal.tanggalJadwal.year,
      jadwal.tanggalJadwal.month,
      jadwal.tanggalJadwal.day,
    );
    return !tgl.isAfter(today);
  }

  Future<void> _reschedule(
    BuildContext context,
    JadwalImunisasiModel jadwal,
  ) async {
    final provider = context.read<JadwalImunisasiKaderProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: jadwal.tanggalJadwal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('id', 'ID'),
    );
    if (picked == null || !context.mounted) return;
    final berhasil = await provider.ubahTanggal(jadwal.id, picked);
    if (!context.mounted) return;
    if (berhasil) {
      CustomSnackbar.sukses(context, 'Jadwal berhasil diperbarui');
    } else {
      CustomSnackbar.gagal(
        context,
        provider.error ?? 'Gagal memperbarui jadwal',
      );
    }
  }

  Future<void> _hapus(BuildContext context, JadwalImunisasiModel jadwal) async {
    final konfirmasi = await showConfirmationDialog(
      context: context,
      title: 'Hapus Jadwal',
      message:
          'Hapus jadwal "${jadwal.namaImunisasi ?? 'ini'}"? Jadwal ini tidak dapat dikembalikan.',
      icon: Icons.delete_outline_rounded,
    );
    if (konfirmasi != true || !context.mounted) return;
    final provider = context.read<JadwalImunisasiKaderProvider>();
    final berhasil = await provider.hapus(jadwal.id);
    if (!context.mounted) return;
    if (berhasil) {
      CustomSnackbar.sukses(context, 'Jadwal berhasil dihapus');
    } else {
      CustomSnackbar.gagal(context, provider.error ?? 'Gagal menghapus jadwal');
    }
  }

  Future<void> _bukaGenerateJadwal(
    BuildContext context,
    BalitaModel balita,
  ) async {
    final jadwalProvider = context.read<JadwalImunisasiKaderProvider>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => GenerateJadwalScreen(balita: balita)),
    );
    if (result == true && mounted) {
      jadwalProvider.muat(balita.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balita = context.watch<BalitaKaderProvider>().selected;
    final provider = context.watch<JadwalImunisasiKaderProvider>();
    final df = DateFormat('dd MMM yyyy', 'id_ID');

    if (balita == null) {
      return const Scaffold(body: Center(child: Text('Data tidak ditemukan')));
    }

    final daftar = _filterStatus == null
        ? provider.daftar
        : provider.daftar.where((j) => j.status == _filterStatus).toList();

    final content = RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => provider.muat(balita.id),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _ImunisasiHeader(
                  title: 'Jadwal Imunisasi',
                  showBack: widget.standalone,
                ),
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Column(
                      children: [
                        _BalitaHeaderCard(balita: balita),
                        const SizedBox(height: 12),
                        _StatusFilterBar(
                          selectedStatus: _filterStatus,
                          onChanged: (status) =>
                              setState(() => _filterStatus = status),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (provider.isLoading)
            const SliverFillRemaining(child: LoadingWidget())
          else if (provider.daftar.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptySchedule(
                onGenerate: () => _bukaGenerateJadwal(context, balita),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              sliver: SliverList.separated(
                itemCount: daftar.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final jadwal = daftar[index];
                  return _JadwalItem(
                    jadwal: jadwal,
                    df: df,
                    onInput: _bisaInput(jadwal)
                        ? () => _bukaInputImunisasi(ctx, balita, jadwal)
                        : null,
                    onEdit: jadwal.status == 'selesai'
                        ? null
                        : () => _reschedule(ctx, jadwal),
                    onHapus: jadwal.status == 'selesai'
                        ? null
                        : () => _hapus(ctx, jadwal),
                  );
                },
              ),
            ),
        ],
      ),
    );

    if (!widget.standalone) return content;

    return Scaffold(backgroundColor: AppColors.background, body: content);
  }
}

class _ImunisasiHeader extends StatelessWidget {
  final String title;
  final bool showBack;

  const _ImunisasiHeader({required this.title, required this.showBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 42),
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
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showBack)
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            else
              const SizedBox(width: 48),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _BalitaHeaderCard extends StatelessWidget {
  final BalitaModel balita;

  const _BalitaHeaderCard({required this.balita});

  @override
  Widget build(BuildContext context) {
    final isBoy = balita.jenisKelamin == 'Laki-laki';
    final usia = AgeCalculator.formatUsiaDetail(balita.tanggalLahir);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: isBoy
                  ? AppColors.surfaceTeal
                  : const Color(0xFFFFE4EE),
              child: Icon(
                isBoy ? Icons.boy_rounded : Icons.girl_rounded,
                color: isBoy ? AppColors.primary : const Color(0xFFE91E8C),
                size: 42,
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
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Usia $usia',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isBoy ? Icons.male_rounded : Icons.female_rounded,
                        color: isBoy ? AppColors.info : AppColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        balita.jenisKelamin,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
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

class _StatusFilterBar extends StatelessWidget {
  final String? selectedStatus;
  final ValueChanged<String?> onChanged;

  const _StatusFilterBar({
    required this.selectedStatus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterPill(
          label: 'Terjadwal',
          selected: selectedStatus == null || selectedStatus == 'terjadwal',
          color: AppColors.primary,
          onTap: () => onChanged(
            selectedStatus == 'terjadwal' || selectedStatus == null
                ? null
                : 'terjadwal',
          ),
        ),
        const SizedBox(width: 8),
        _FilterPill(
          label: 'Terlambat',
          selected: selectedStatus == 'terlambat',
          color: AppColors.warning,
          onTap: () => onChanged('terlambat'),
        ),
        const SizedBox(width: 8),
        _FilterPill(
          label: 'Selesai',
          selected: selectedStatus == 'selesai',
          color: AppColors.info,
          onTap: () => onChanged('selesai'),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? color : Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  final VoidCallback onGenerate;

  const _EmptySchedule({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 64,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 12),
            const Text(
              'Belum ada jadwal imunisasi.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              icon: const Icon(Icons.event_available_rounded),
              label: const Text('Buat Jadwal Imunisasi'),
              onPressed: onGenerate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JadwalItem extends StatelessWidget {
  final JadwalImunisasiModel jadwal;
  final DateFormat df;
  final VoidCallback? onInput;
  final VoidCallback? onEdit;
  final VoidCallback? onHapus;

  const _JadwalItem({
    required this.jadwal,
    required this.df,
    required this.onInput,
    this.onEdit,
    this.onHapus,
  });

  Color get _statusColor {
    return switch (jadwal.status) {
      'selesai' => AppColors.success,
      'terlambat' => AppColors.error,
      _ => AppColors.success,
    };
  }

  String get _statusLabel {
    return switch (jadwal.status) {
      'selesai' => 'Selesai',
      'terlambat' => 'Terlambat',
      _ => 'Terjadwal',
    };
  }

  @override
  Widget build(BuildContext context) {
    final selesai = jadwal.status == 'selesai';
    final iconColor = _iconColor(jadwal.namaImunisasi ?? '');

    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.vaccines_rounded, color: iconColor, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jadwal.namaImunisasi ?? 'Imunisasi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selesai
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _SmallLine(
                    label: 'Jatuh Tempo',
                    value: 'Usia ${jadwal.usiaBulanImunisasi ?? '-'} bulan',
                  ),
                  const _SmallLine(label: 'Tempat', value: 'Posyandu Merpati'),
                  _SmallLine(
                    label: 'Tanggal',
                    value: df.format(jadwal.tanggalJadwal),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusBadge(label: _statusLabel, color: _statusColor),
                const SizedBox(height: 10),
                if (selesai)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 28,
                  )
                else
                  OutlinedButton(
                    onPressed: onInput,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      minimumSize: const Size(0, 34),
                    ),
                    child: const Text(
                      'Input',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                if (!selesai)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_horiz_rounded, size: 20),
                    onSelected: (value) {
                      if (value == 'edit') onEdit?.call();
                      if (value == 'hapus') onHapus?.call();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Ubah Tanggal')),
                      PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _iconColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('bcg')) return AppColors.warning;
    if (lower.contains('polio')) return AppColors.info;
    if (lower.contains('dpt')) return AppColors.success;
    if (lower.contains('campak')) return const Color(0xFFFF6384);
    return const Color(0xFF7E57C2);
  }
}

class _SmallLine extends StatelessWidget {
  final String label;
  final String value;

  const _SmallLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              ': $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
