import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/age_calculator.dart';
import '../../../../core/utils/growth_status_helper.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/growth_status_badge.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/balita_model.dart';
import '../../../../data/models/pertumbuhan_model.dart';
import '../../providers/balita_kader_provider.dart';
import '../../providers/pertumbuhan_kader_provider.dart';

class RiwayatPertumbuhanKaderScreen extends StatefulWidget {
  const RiwayatPertumbuhanKaderScreen({super.key});

  @override
  State<RiwayatPertumbuhanKaderScreen> createState() =>
      _RiwayatPertumbuhanKaderScreenState();
}

class _RiwayatPertumbuhanKaderScreenState
    extends State<RiwayatPertumbuhanKaderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final balita = context.read<BalitaKaderProvider>().selected;
      if (balita != null) {
        context.read<PertumbuhanKaderProvider>().muatByBalita(balita.id);
      }
    });
  }

  Future<void> _konfirmasiHapus(PertumbuhanModel item) async {
    final df = DateFormat('dd MMM yyyy', 'id_ID');
    final konfirmasi = await showConfirmationDialog(
      context: context,
      title: 'Hapus Data Pertumbuhan',
      message:
          'Hapus data pertumbuhan tanggal ${df.format(item.tanggalPemeriksaan)}? Data tidak dapat dikembalikan.',
      icon: Icons.delete_outline_rounded,
    );
    if (konfirmasi != true || !mounted) return;

    final berhasil = await context.read<PertumbuhanKaderProvider>().hapus(
      item.id,
    );
    if (!mounted) return;
    if (berhasil) {
      CustomSnackbar.sukses(context, 'Data pertumbuhan berhasil dihapus');
    } else {
      final err = context.read<PertumbuhanKaderProvider>().error;
      CustomSnackbar.gagal(context, err ?? 'Gagal menghapus data');
    }
  }

  void _bukaEditPertumbuhan(PertumbuhanModel item) {
    final balita = context.read<BalitaKaderProvider>().selected;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<PertumbuhanKaderProvider>(),
        child: _EditPertumbuhanSheet(
          item: item,
          tanggalLahir: balita?.tanggalLahir,
          jenisKelamin: balita?.jenisKelamin ?? 'Laki-laki',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balita = context.watch<BalitaKaderProvider>().selected;
    final provider = context.watch<PertumbuhanKaderProvider>();

    if (balita == null) {
      return const Scaffold(body: Center(child: Text('Data tidak ditemukan')));
    }

    final daftar = [...provider.daftar]
      ..sort((a, b) => a.tanggalPemeriksaan.compareTo(b.tanggalPemeriksaan));
    final terbaru = daftar.isEmpty ? null : daftar.last;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: provider.isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => provider.muatByBalita(balita.id),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const _RiwayatHeader(),
                    Transform.translate(
                      offset: const Offset(0, -22),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Column(
                          children: [
                            _BalitaCard(balita: balita),
                            const SizedBox(height: 12),
                            _GrowthChartCard(daftar: daftar),
                            const SizedBox(height: 12),
                            _HistoryCard(
                              daftar: daftar.reversed.toList(),
                              onEdit: _bukaEditPertumbuhan,
                              onHapus: _konfirmasiHapus,
                            ),
                            const SizedBox(height: 12),
                            _SummaryCard(pertumbuhan: terbaru),
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
}

class _RiwayatHeader extends StatelessWidget {
  const _RiwayatHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 42),
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
              onPressed: () => Navigator.pop(context),
            ),
            const Expanded(
              child: Text(
                'Riwayat Pertumbuhan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

class _BalitaCard extends StatelessWidget {
  final BalitaModel balita;

  const _BalitaCard({required this.balita});

  @override
  Widget build(BuildContext context) {
    final isBoy = balita.jenisKelamin == 'Laki-laki';
    final usia = AgeCalculator.formatUsiaDetail(balita.tanggalLahir);

    return _SoftCard(
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
              color: isBoy ? AppColors.primary : const Color(0xFFE91E63),
              size: 44,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  balita.nama,
                  style: const TextStyle(
                    color: Color(0xFF111A3A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Usia $usia',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      isBoy ? Icons.male_rounded : Icons.female_rounded,
                      color: isBoy ? AppColors.info : const Color(0xFFE91E63),
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      balita.jenisKelamin,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.surfaceMint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.show_chart_rounded,
              color: AppColors.secondary,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthChartCard extends StatelessWidget {
  final List<PertumbuhanModel> daftar;

  const _GrowthChartCard({required this.daftar});

  @override
  Widget build(BuildContext context) {
    final points = daftar.length > 6
        ? daftar.sublist(daftar.length - 6)
        : daftar;

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _SectionTitle('Grafik Pertumbuhan')),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '6 Bulan Terakhir',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _LegendDot(color: AppColors.success, label: 'Berat Badan (kg)'),
              SizedBox(width: 14),
              _LegendDot(color: AppColors.info, label: 'Tinggi Badan (cm)'),
            ],
          ),
          const SizedBox(height: 10),
          if (points.length < 2)
            const SizedBox(
              height: 170,
              child: Center(
                child: Text(
                  'Data pertumbuhan belum cukup untuk grafik',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            SizedBox(height: 185, child: LineChart(_lineData(points))),
        ],
      ),
    );
  }

  LineChartData _lineData(List<PertumbuhanModel> points) {
    final values = <double>[
      for (final item in points) ...[item.beratBadan, item.tinggiBadan],
    ];
    var minY = values.first;
    var maxY = values.first;
    for (final value in values) {
      if (value < minY) minY = value;
      if (value > maxY) maxY = value;
    }
    minY = (minY - 5).clamp(0, double.infinity).toDouble();
    maxY = maxY + 8;

    return LineChartData(
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: AppColors.divider, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 20,
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= points.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  DateFormat(
                    'MMM yy',
                    'id_ID',
                  ).format(points[index].tanggalPemeriksaan),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.primaryDark,
        ),
      ),
      lineBarsData: [
        _chartLine(points, AppColors.success, (item) => item.beratBadan),
        _chartLine(points, AppColors.info, (item) => item.tinggiBadan),
      ],
    );
  }

  LineChartBarData _chartLine(
    List<PertumbuhanModel> points,
    Color color,
    double Function(PertumbuhanModel item) valueOf,
  ) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < points.length; i++)
          FlSpot(i.toDouble(), valueOf(points[i])),
      ],
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.07),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final List<PertumbuhanModel> daftar;
  final ValueChanged<PertumbuhanModel> onEdit;
  final ValueChanged<PertumbuhanModel> onHapus;

  const _HistoryCard({
    required this.daftar,
    required this.onEdit,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Riwayat Pertumbuhan'),
          const SizedBox(height: 12),
          if (daftar.isEmpty)
            const SizedBox(
              height: 110,
              child: Center(
                child: Text(
                  'Belum ada data pertumbuhan',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            ...daftar.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _HistoryRow(
                  item: item,
                  onEdit: () => onEdit(item),
                  onHapus: () => onHapus(item),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final PertumbuhanModel item;
  final VoidCallback onEdit;
  final VoidCallback onHapus;

  const _HistoryRow({
    required this.item,
    required this.onEdit,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final status = item.statusGizi ?? 'Tidak diketahui';
    final color = growthStatusColor(status);
    final df = DateFormat('dd MMM\nyyyy', 'id_ID');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceMint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              df.format(item.tanggalPemeriksaan),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                _MetricText(label: 'Usia', value: '${item.usiaBulan} bln'),
                _MetricText(
                  label: 'Berat Badan',
                  value: '${_formatNumber(item.beratBadan)} kg',
                ),
                _MetricText(
                  label: 'Tinggi Badan',
                  value: '${_formatNumber(item.tinggiBadan)} cm',
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusBadge(label: status, color: color),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'hapus') onHapus();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'hapus',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final PertumbuhanModel? pertumbuhan;

  const _SummaryCard({required this.pertumbuhan});

  @override
  Widget build(BuildContext context) {
    final item = pertumbuhan;
    final status = item?.statusGizi ?? 'Belum ada data';
    final color = growthStatusColor(status);
    final tanggal = item == null
        ? '-'
        : DateFormat('dd MMM yyyy', 'id_ID').format(item.tanggalPemeriksaan);

    return _SoftCard(
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(growthStatusIcon(status), color: color, size: 38),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Gizi Terakhir',
                        style: TextStyle(
                          color: Color(0xFF111A3A),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Berat badan dan tinggi badan sesuai untuk usia',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 62, color: AppColors.divider),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.info,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pemeriksaan Terakhir',
                        style: TextStyle(
                          color: Color(0xFF111A3A),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tanggal,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        item == null ? '-' : 'Usia ${item.usiaBulan} bulan',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditPertumbuhanSheet extends StatefulWidget {
  final PertumbuhanModel item;
  final DateTime? tanggalLahir;
  final String jenisKelamin;

  const _EditPertumbuhanSheet({
    required this.item,
    required this.tanggalLahir,
    required this.jenisKelamin,
  });

  @override
  State<_EditPertumbuhanSheet> createState() => _EditPertumbuhanSheetState();
}

class _EditPertumbuhanSheetState extends State<_EditPertumbuhanSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bbCtrl;
  late final TextEditingController _tbCtrl;
  late final TextEditingController _catatanCtrl;
  late DateTime _tanggal;

  @override
  void initState() {
    super.initState();
    _tanggal = widget.item.tanggalPemeriksaan;
    _bbCtrl = TextEditingController(
      text: _formatNumber(widget.item.beratBadan),
    );
    _tbCtrl = TextEditingController(
      text: _formatNumber(widget.item.tinggiBadan),
    );
    _catatanCtrl = TextEditingController(text: widget.item.catatan ?? '');
  }

  @override
  void dispose() {
    _bbCtrl.dispose();
    _tbCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  double? _parseDecimal(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    final bb = _parseDecimal(_bbCtrl.text);
    final tb = _parseDecimal(_tbCtrl.text);
    if (bb == null || tb == null) {
      CustomSnackbar.gagal(context, 'Masukkan nilai berat dan tinggi valid');
      return;
    }

    final usiaBulan = widget.tanggalLahir != null
        ? AgeCalculator.hitungUsiaBulan(widget.tanggalLahir!, _tanggal)
        : widget.item.usiaBulan;
    final statusGizi = GrowthStatusHelper.hitungStatusGizi(
      beratBadan: bb,
      tinggiBadan: tb,
      usiaBulan: usiaBulan,
      jenisKelamin: widget.jenisKelamin,
    );
    final statusTB = GrowthStatusHelper.hitungStatusTinggiBadan(
      tinggiBadan: tb,
      usiaBulan: usiaBulan,
      jenisKelamin: widget.jenisKelamin,
    );
    final statusBB = GrowthStatusHelper.hitungStatusBeratBadan(
      beratBadan: bb,
      usiaBulan: usiaBulan,
      jenisKelamin: widget.jenisKelamin,
    );

    final provider = context.read<PertumbuhanKaderProvider>();
    final berhasil = await provider.update(
      widget.item.id,
      tanggalPemeriksaan: _tanggal,
      usiaBulan: usiaBulan,
      beratBadan: bb,
      tinggiBadan: tb,
      statusGizi: statusGizi,
      statusTinggiBadan: statusTB,
      statusBeratBadan: statusBB,
      catatan: _catatanCtrl.text.trim().isEmpty
          ? null
          : _catatanCtrl.text.trim(),
    );
    if (!mounted) return;
    if (berhasil) {
      Navigator.pop(context);
      CustomSnackbar.sukses(context, 'Data pertumbuhan berhasil diperbarui');
    } else {
      CustomSnackbar.gagal(context, provider.error ?? 'Gagal menyimpan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMMM yyyy', 'id_ID');
    final provider = context.watch<PertumbuhanKaderProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Edit Data Pertumbuhan',
              style: TextStyle(
                color: Color(0xFF111A3A),
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pilihTanggal,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Pemeriksaan',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(df.format(_tanggal)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bbCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Berat Badan (kg)',
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _tbCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Tinggi Badan (cm)',
                      prefixIcon: Icon(Icons.height),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _catatanCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan',
                prefixIcon: Icon(Icons.note_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : _simpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Simpan Perubahan',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricText extends StatelessWidget {
  final String label;
  final String value;

  const _MetricText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
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
      constraints: const BoxConstraints(maxWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(growthStatusIcon(label), color: color, size: 15),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF111A3A),
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1).replaceAll('.', ',');
}
