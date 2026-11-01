import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/age_calculator.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/jadwal_imunisasi_model.dart';
import '../../providers/balita_kader_provider.dart';
import '../../providers/imunisasi_provider.dart';
import '../../providers/jadwal_imunisasi_kader_provider.dart';
import '../../providers/jenis_imunisasi_provider.dart';
import 'input_imunisasi_screen.dart';

class JadwalImunisasiKaderScreen extends StatefulWidget {
  const JadwalImunisasiKaderScreen({super.key});

  @override
  State<JadwalImunisasiKaderScreen> createState() =>
      _JadwalImunisasiKaderScreenState();
}

class _JadwalImunisasiKaderScreenState
    extends State<JadwalImunisasiKaderScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String? _filterStatus;
  bool _isCalendarView = false;
  bool _showSearch = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JadwalImunisasiKaderProvider>().muatSemuaJadwal();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int _statusPriority(String status) {
    switch (status) {
      case 'terlambat':
        return 0;
      case 'terjadwal':
        return 1;
      default:
        return 2;
    }
  }

  bool _isHariIni(DateTime tanggal) {
    final now = DateTime.now();
    return tanggal.year == now.year &&
        tanggal.month == now.month &&
        tanggal.day == now.day;
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

  List<JadwalImunisasiModel> _eventsForDay(
    DateTime day,
    List<JadwalImunisasiModel> all,
  ) {
    return all.where((j) {
      final sameDay =
          j.tanggalJadwal.year == day.year &&
          j.tanggalJadwal.month == day.month &&
          j.tanggalJadwal.day == day.day;
      if (!sameDay) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        if (!(j.namaBalita ?? '').toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();
  }

  List<JadwalImunisasiModel> _terapkanFilter(List<JadwalImunisasiModel> all) {
    var list = all.where((j) {
      if (_filterStatus != null && j.status != _filterStatus) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        if (!(j.namaBalita ?? '').toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();

    list.sort((a, b) {
      if (_filterStatus == null) {
        final pa = _statusPriority(a.status);
        final pb = _statusPriority(b.status);
        if (pa != pb) return pa.compareTo(pb);
      }
      if (a.status == 'selesai' && b.status == 'selesai') {
        return b.tanggalJadwal.compareTo(a.tanggalJadwal);
      }
      return a.tanggalJadwal.compareTo(b.tanggalJadwal);
    });
    return list;
  }

  Future<void> _bukaInputImunisasi(JadwalImunisasiModel jadwal) async {
    final provider = context.read<JadwalImunisasiKaderProvider>();
    await Navigator.push(
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
    if (mounted) provider.muatSemuaJadwal();
  }

  Future<void> _reschedule(JadwalImunisasiModel jadwal) async {
    final provider = context.read<JadwalImunisasiKaderProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: jadwal.tanggalJadwal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('id', 'ID'),
    );
    if (picked == null || !mounted) return;
    final berhasil = await provider.ubahTanggal(jadwal.id, picked);
    if (!mounted) return;
    if (berhasil) {
      CustomSnackbar.sukses(context, 'Jadwal berhasil diperbarui');
      provider.muatSemuaJadwal();
    } else {
      CustomSnackbar.gagal(
        context,
        provider.errorSemua ?? 'Gagal memperbarui jadwal',
      );
    }
  }

  Future<void> _hapus(JadwalImunisasiModel jadwal) async {
    final konfirmasi = await showConfirmationDialog(
      context: context,
      title: 'Hapus Jadwal',
      message:
          'Hapus jadwal "${jadwal.namaImunisasi ?? 'ini'}" untuk ${jadwal.namaBalita ?? 'balita'}? Jadwal ini tidak dapat dikembalikan.',
      icon: Icons.delete_outline_rounded,
    );
    if (konfirmasi != true || !mounted) return;
    final provider = context.read<JadwalImunisasiKaderProvider>();
    final berhasil = await provider.hapus(jadwal.id);
    if (!mounted) return;
    if (berhasil) {
      CustomSnackbar.sukses(context, 'Jadwal berhasil dihapus');
      provider.muatSemuaJadwal();
    } else {
      CustomSnackbar.gagal(
        context,
        provider.errorSemua ?? 'Gagal menghapus jadwal',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JadwalImunisasiKaderProvider>();
    final df = DateFormat('dd MMM yyyy', 'id_ID');

    final semua = provider.semuaJadwal;
    final terlambat = semua.where((j) => j.status == 'terlambat').length;
    final hariIni = semua
        .where((j) => j.status != 'selesai' && _isHariIni(j.tanggalJadwal))
        .length;
    final terjadwal = semua.where((j) => j.status == 'terjadwal').length;

    final selectedDay = _selectedDay ?? DateTime.now();
    final daftarDitampilkan = _isCalendarView
        ? (_eventsForDay(selectedDay, semua)
            ..sort((a, b) => a.tanggalJadwal.compareTo(b.tanggalJadwal)))
        : _terapkanFilter(semua);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: provider.muatSemuaJadwal,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: GradientPageHeader(
                title: 'Jadwal Imunisasi',
                subtitle: 'Pantau jadwal imunisasi seluruh balita.',
                icon: Icons.event_available_rounded,
                onBack: () => Navigator.pop(context),
                bottomPadding: 18,
                actions: [
                  IconButton(
                    icon: Icon(
                      _showSearch
                          ? Icons.search_off_rounded
                          : Icons.search_rounded,
                      color: Colors.white,
                    ),
                    tooltip: _showSearch ? 'Tutup pencarian' : 'Cari',
                    onPressed: () => setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) {
                        _searchCtrl.clear();
                        _search = '';
                      }
                    }),
                  ),
                  IconButton(
                    icon: Icon(
                      _isCalendarView
                          ? Icons.view_list_rounded
                          : Icons.calendar_month_rounded,
                      color: Colors.white,
                    ),
                    tooltip: _isCalendarView
                        ? 'Tampilan daftar'
                        : 'Tampilan kalender',
                    onPressed: () =>
                        setState(() => _isCalendarView = !_isCalendarView),
                  ),
                ],
                bottom: _showSearch
                    ? _SearchField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _search = v),
                      )
                    : null,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Terlambat',
                            value: terlambat,
                            color: AppColors.error,
                            icon: Icons.warning_amber_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'Hari Ini',
                            value: hariIni,
                            color: AppColors.warning,
                            icon: Icons.today_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'Terjadwal',
                            value: terjadwal,
                            color: AppColors.info,
                            icon: Icons.event_note_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_isCalendarView) ...[
                      _JadwalCalendar(
                        focusedDay: _focusedDay,
                        selectedDay: _selectedDay,
                        eventsForDay: (day) => _eventsForDay(day, semua),
                        onDaySelected: (selected, focused) {
                          setState(() {
                            _selectedDay = selected;
                            _focusedDay = focused;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Jadwal • ${DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(selectedDay)}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ] else ...[
                      _StatusFilterChips(
                        selected: _filterStatus,
                        onChanged: (v) => setState(() => _filterStatus = v),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            if (provider.isLoadingSemua && semua.isEmpty)
              const SliverFillRemaining(child: LoadingWidget())
            else if (daftarDitampilkan.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateWidget(
                  icon: Icons.event_busy_outlined,
                  pesan: _isCalendarView
                      ? 'Tidak ada jadwal pada tanggal ini.'
                      : semua.isEmpty
                      ? 'Belum ada jadwal imunisasi.'
                      : 'Tidak ada jadwal yang cocok dengan filter.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                sliver: SliverList.separated(
                  itemCount: daftarDitampilkan.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final jadwal = daftarDitampilkan[index];
                    return _JadwalGlobalItem(
                      jadwal: jadwal,
                      df: df,
                      onInput: _bisaInput(jadwal)
                          ? () => _bukaInputImunisasi(jadwal)
                          : null,
                      onEdit: jadwal.status == 'selesai'
                          ? null
                          : () => _reschedule(jadwal),
                      onHapus: jadwal.status == 'selesai'
                          ? null
                          : () => _hapus(jadwal),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _JadwalCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final List<JadwalImunisasiModel> Function(DateTime day) eventsForDay;
  final void Function(DateTime selected, DateTime focused) onDaySelected;

  const _JadwalCalendar({
    required this.focusedDay,
    required this.selectedDay,
    required this.eventsForDay,
    required this.onDaySelected,
  });

  Color? _warnaStatus(String status) {
    return switch (status) {
      'terlambat' => AppColors.error,
      'terjadwal' => AppColors.info,
      'selesai' => AppColors.success,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TableCalendar<JadwalImunisasiModel>(
        locale: 'id_ID',
        firstDay: DateTime(2020, 1, 1),
        lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) =>
            selectedDay != null && isSameDay(selectedDay, day),
        onDaySelected: onDaySelected,
        eventLoader: eventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        daysOfWeekHeight: 22,
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: 'Bulan'},
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: AppColors.primary,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: AppColors.primary,
          ),
        ),
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: AppColors.surfaceTeal,
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w900,
          ),
          selectedDecoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          weekendTextStyle: TextStyle(color: AppColors.textPrimary),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return null;
            final warna = events
                .map((e) => _warnaStatus(e.status))
                .whereType<Color>()
                .toSet()
                .toList();
            return Positioned(
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: warna.take(3).map((c) {
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: AppColors.primary,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
        decoration: const InputDecoration(
          hintText: 'Cari nama balita...',
          hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: 13.5),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _StatusFilterChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final opsi = <(String?, String, Color)>[
      (null, 'Semua', AppColors.primary),
      ('terlambat', 'Terlambat', AppColors.error),
      ('terjadwal', 'Terjadwal', AppColors.info),
      ('selesai', 'Selesai', AppColors.success),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: opsi.map((o) {
          final isSelected = selected == o.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: isSelected ? o.$3 : Colors.white,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: () => onChanged(o.$1),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: o.$3.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    o.$2,
                    style: TextStyle(
                      color: isSelected ? Colors.white : o.$3,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _JadwalGlobalItem extends StatelessWidget {
  final JadwalImunisasiModel jadwal;
  final DateFormat df;
  final VoidCallback? onInput;
  final VoidCallback? onEdit;
  final VoidCallback? onHapus;

  const _JadwalGlobalItem({
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
      _ => AppColors.info,
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
    final isBoy = jadwal.balitaJenisKelamin == 'Laki-laki';
    final usiaSekarang = jadwal.balitaTanggalLahir != null
        ? AgeCalculator.formatUsiaDariTanggalLahir(jadwal.balitaTanggalLahir!)
        : null;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: isBoy
                  ? AppColors.surfaceTeal
                  : const Color(0xFFFFE4EE),
              child: Icon(
                isBoy ? Icons.boy_rounded : Icons.girl_rounded,
                color: isBoy ? AppColors.primary : const Color(0xFFE91E8C),
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jadwal.namaBalita ?? 'Balita',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    jadwal.namaImunisasi ?? 'Imunisasi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selesai
                          ? AppColors.textSecondary
                          : AppColors.primaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _SmallLine(
                    label: 'Tanggal',
                    value: df.format(jadwal.tanggalJadwal),
                  ),
                  if (usiaSekarang != null)
                    _SmallLine(label: 'Usia Saat Ini', value: usiaSekarang),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusBadge(label: _statusLabel, color: _statusColor),
                const SizedBox(height: 10),
                if (selesai)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 26,
                  )
                else if (onInput != null)
                  OutlinedButton(
                    onPressed: onInput,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text(
                      'Input',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
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
            width: 76,
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
