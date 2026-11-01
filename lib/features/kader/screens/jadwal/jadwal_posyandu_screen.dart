import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/jadwal_posyandu_model.dart';
import '../../../../routes/app_routes.dart';
import '../../providers/jadwal_posyandu_provider.dart';

class JadwalPosyanduScreen extends StatefulWidget {
  final bool standalone;
  const JadwalPosyanduScreen({super.key, this.standalone = true});

  @override
  State<JadwalPosyanduScreen> createState() => _JadwalPosyanduScreenState();
}

class _JadwalPosyanduScreenState extends State<JadwalPosyanduScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JadwalPosyanduProvider>().muatDaftar();
    });
  }

  Widget _buildBody() {
    return Consumer<JadwalPosyanduProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading && provider.daftar.isEmpty) {
          return const LoadingWidget();
        }
        if (provider.error != null && provider.daftar.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.cloud_off_rounded,
            pesan: 'Gagal memuat jadwal:\n${provider.error}',
            onRetry: provider.muatDaftar,
          );
        }
        if (provider.daftar.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.event_note,
            pesan: 'Belum ada jadwal posyandu.\nTekan + untuk menambah jadwal.',
            onRetry: provider.muatDaftar,
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: provider.muatDaftar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            children: [
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: LinearProgressIndicator(color: AppColors.primary),
                ),
              KaderHeroPanel(
                title: 'Kelola Jadwal',
                subtitle:
                    '${provider.daftar.length} agenda Posyandu tersimpan untuk layanan admin.',
                icon: Icons.calendar_month_rounded,
              ),
              const SizedBox(height: 14),
              const SectionTitle(title: 'Daftar Agenda Posyandu'),
              const SizedBox(height: 10),
              ...provider.daftar.map((jadwal) {
                final isPast = _dateOnly(
                  jadwal.tanggal,
                ).isBefore(_dateOnly(DateTime.now()));
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showJadwalDetail(context, jadwal, isPast),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _DateBadge(date: jadwal.tanggal, muted: isPast),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        jadwal.judul,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: isPast
                                              ? AppColors.textDisabled
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    StatusBadge(
                                      label: isPast ? 'Selesai' : 'Akan datang',
                                      color: isPast
                                          ? AppColors.textSecondary
                                          : AppColors.success,
                                    ),
                                  ],
                                ),
                                if (jadwal.jamMulai != null) ...[
                                  const SizedBox(height: 6),
                                  InfoTextRow(
                                    icon: Icons.schedule_outlined,
                                    text:
                                        '${jadwal.jamMulai}${jadwal.jamSelesai != null ? ' - ${jadwal.jamSelesai}' : ''} WIB',
                                  ),
                                ],
                                if (jadwal.lokasi != null) ...[
                                  const SizedBox(height: 4),
                                  InfoTextRow(
                                    icon: Icons.place_outlined,
                                    text: jadwal.lokasi!,
                                  ),
                                ],
                                if (jadwal.deskripsi != null &&
                                    jadwal.deskripsi!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  InfoTextRow(
                                    icon: Icons.notes_outlined,
                                    text: jadwal.deskripsi!,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                color: AppColors.primary,
                                tooltip: AppStrings.edit,
                                visualDensity: VisualDensity.compact,
                                onPressed: () async {
                                  provider.pilihJadwal(jadwal);
                                  await Navigator.pushNamed(
                                    context,
                                    AppRoutes.editJadwal,
                                  );
                                  if (mounted) provider.muatDaftar();
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                ),
                                color: AppColors.error,
                                tooltip: 'Hapus',
                                visualDensity: VisualDensity.compact,
                                onPressed: () =>
                                    _konfirmasiHapusJadwal(provider, jadwal),
                              ),
                            ],
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.standalone) return _buildBody();

    return Scaffold(
      appBar: GradientAppBar(title: AppStrings.jadwalPosyandu),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final provider = context.read<JadwalPosyanduProvider>();
          await Navigator.pushNamed(context, AppRoutes.tambahJadwal);
          if (mounted) provider.muatDaftar();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

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
                  _DateBadge(date: jadwal.tanggal, muted: isPast),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      jadwal.judul,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _konfirmasiHapusJadwal(
    JadwalPosyanduProvider provider,
    JadwalPosyanduModel jadwal,
  ) async {
    final ok = await showConfirmationDialog(
      context: context,
      title: 'Hapus Jadwal Posyandu',
      message:
          'Hapus jadwal "${jadwal.judul}"? Agenda ini tidak dapat dikembalikan.',
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;

    final berhasil = await provider.hapus(jadwal.id);
    if (!mounted) return;
    if (berhasil) {
      CustomSnackbar.sukses(context, AppStrings.berhasilDihapus);
    } else {
      CustomSnackbar.gagal(context, AppStrings.gagalMenyimpan);
    }
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

class _DateBadge extends StatelessWidget {
  final DateTime date;
  final bool muted;

  const _DateBadge({required this.date, required this.muted});

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.textDisabled : AppColors.primary;
    return Container(
      width: 56,
      height: 62,
      decoration: BoxDecoration(
        color: muted ? AppColors.divider : AppColors.surfaceMint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('dd').format(date),
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            DateFormat('MMM', 'id_ID').format(date).toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
