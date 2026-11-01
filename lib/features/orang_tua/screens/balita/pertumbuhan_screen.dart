import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/age_calculator.dart';
import '../../../../core/utils/growth_status_helper.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../providers/ortu_balita_provider.dart';
import '../../providers/pertumbuhan_provider.dart';

class PertumbuhanScreen extends StatefulWidget {
  final bool standalone;

  const PertumbuhanScreen({super.key, this.standalone = true});

  @override
  State<PertumbuhanScreen> createState() => _PertumbuhanScreenState();
}

class _PertumbuhanScreenState extends State<PertumbuhanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final balita = context.read<OrtuBalitaProvider>().selected;
      if (balita != null) {
        context.read<PertumbuhanProvider>().muatByBalita(balita.id);
      }
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Normal':
        return AppColors.success;
      case 'Gizi Kurang':
      case 'Risiko Stunting':
        return AppColors.warning;
      case 'Gizi Buruk':
      case 'Stunting':
        return AppColors.statusGiziBuruk;
      case 'Risiko Gizi Lebih':
        return AppColors.statusRisikoGiziLebih;
      case 'Gizi Lebih':
        return AppColors.statusGiziLebih;
      case 'Obesitas':
        return AppColors.statusObesitas;
      default:
        return AppColors.primary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Normal':
        return Icons.sentiment_satisfied_alt_rounded;
      case 'Gizi Kurang':
      case 'Risiko Stunting':
        return Icons.sentiment_dissatisfied_rounded;
      case 'Gizi Buruk':
      case 'Stunting':
        return Icons.sentiment_very_dissatisfied_rounded;
      case 'Risiko Gizi Lebih':
      case 'Gizi Lebih':
      case 'Obesitas':
        return Icons.sentiment_neutral_rounded;
      default:
        return Icons.sentiment_satisfied_alt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final balita = context.watch<OrtuBalitaProvider>().selected;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientPageHeader(
            title: 'Pertumbuhan',
            subtitle: 'Pantau grafik berat, tinggi, dan status gizi balita.',
            icon: Icons.show_chart_rounded,
            onBack: widget.standalone ? () => Navigator.pop(context) : null,
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -18),
              child: Consumer<PertumbuhanProvider>(
                builder: (_, provider, __) {
                  if (provider.isLoading) return const LoadingWidget();
                  if (provider.daftar.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.show_chart,
                      pesan: 'Belum ada data pertumbuhan',
                    );
                  }

                  final daftar = provider.daftar;
                  final terakhir = daftar.last;

                  final usiaTeks = balita != null
                      ? AgeCalculator.formatUsiaDetail(balita.tanggalLahir)
                      : '${terakhir.usiaBulan} bulan';

                  final usiaBulan = balita != null
                      ? AgeCalculator.hitungUsiaBulanSekarang(
                          balita.tanggalLahir,
                        )
                      : terakhir.usiaBulan;

                  final jenisKelamin = balita?.jenisKelamin ?? 'Laki-laki';

                  final statusGizi =
                      terakhir.statusGizi ??
                      GrowthStatusHelper.hitungStatusGizi(
                        beratBadan: terakhir.beratBadan,
                        tinggiBadan: terakhir.tinggiBadan,
                        usiaBulan: usiaBulan,
                        jenisKelamin: jenisKelamin,
                      );

                  final statusWarna = _statusColor(statusGizi);

                  double? zScore;
                  String zLabel = '';
                  if (terakhir.beratBadan > 0) {
                    zScore = GrowthStatusHelper.hitungZScoreBBTB(
                      beratBadan: terakhir.beratBadan,
                      usiaBulan: usiaBulan,
                      jenisKelamin: jenisKelamin,
                    );
                    zLabel = GrowthStatusHelper.labelZScore(zScore);
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    children: [
                      // ── Header balita ────────────────────────────────────────────
                      SoftHeaderCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: jenisKelamin == 'Perempuan'
                                  ? const Color(0xFFFFE4EE)
                                  : AppColors.surfaceTeal,
                              child: Icon(
                                jenisKelamin == 'Perempuan'
                                    ? Icons.girl_rounded
                                    : Icons.boy_rounded,
                                color: jenisKelamin == 'Perempuan'
                                    ? const Color(0xFFE91E8C)
                                    : AppColors.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    balita?.nama ?? 'Balita',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$jenisKelamin • $usiaTeks',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(label: statusGizi, color: statusWarna),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Status Gizi ──────────────────────────────────────────────
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Status Gizi Saat Ini',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: statusWarna.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: statusWarna.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: statusWarna.withValues(
                                          alpha: 0.15,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _statusIcon(statusGizi),
                                        color: statusWarna,
                                        size: 30,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            statusGizi,
                                            style: TextStyle(
                                              color: statusWarna,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'Berdasarkan perhitungan otomatis',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Status gizi dihitung dari Berat Badan, Tinggi Badan, Usia (bulan), dan Jenis Kelamin.',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // ── 2x2 Metric Grid ──────────────────────────────────
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetricCard(
                                      title: 'Berat Badan Terakhir',
                                      value: terakhir.beratBadan
                                          .toStringAsFixed(1),
                                      unit: 'kg',
                                      subLabel:
                                          GrowthStatusHelper.hitungStatusBeratBadan(
                                            beratBadan: terakhir.beratBadan,
                                            usiaBulan: usiaBulan,
                                            jenisKelamin: jenisKelamin,
                                          ),
                                      subColor: statusWarna,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _MetricCard(
                                      title: 'Tinggi Badan Terakhir',
                                      value: terakhir.tinggiBadan
                                          .toStringAsFixed(1),
                                      unit: 'cm',
                                      subLabel:
                                          GrowthStatusHelper.hitungStatusTinggiBadan(
                                            tinggiBadan: terakhir.tinggiBadan,
                                            usiaBulan: usiaBulan,
                                            jenisKelamin: jenisKelamin,
                                          ),
                                      subColor: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetricCard(
                                      title: 'Usia (Otomatis)',
                                      value: usiaTeks,
                                      unit: '',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _MetricCard(
                                      title: 'BB/TB (Z-Score)',
                                      value: zScore != null
                                          ? '${zScore.toStringAsFixed(2)} SD'
                                          : '-',
                                      unit: '',
                                      subLabel: zLabel,
                                      subColor: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Grafik Berat Badan ───────────────────────────────────────
                      _ChartCard(
                        title: 'Grafik Berat Badan (kg)',
                        daftar: daftar,
                        isBeratBadan: true,
                      ),
                      const SizedBox(height: 12),

                      // ── Grafik Tinggi Badan ──────────────────────────────────────
                      _ChartCard(
                        title: 'Grafik Tinggi Badan (cm)',
                        daftar: daftar,
                        isBeratBadan: false,
                      ),
                      const SizedBox(height: 18),

                      // ── Riwayat Data ─────────────────────────────────────────────
                      const SectionTitle(title: 'Riwayat Data'),
                      const SizedBox(height: 8),
                      ...daftar.reversed.map(
                        (p) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const IconBadge(
                              icon: Icons.timeline_rounded,
                              size: 42,
                            ),
                            title: Text(
                              '${p.beratBadan.toStringAsFixed(1)} kg  •  ${p.tinggiBadan.toStringAsFixed(1)} cm',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              '${p.usiaBulan} bulan  •  ${DateFormat('dd MMM yyyy', 'id_ID').format(p.tanggalPemeriksaan)}',
                            ),
                            trailing: p.statusGizi != null
                                ? StatusBadge(label: p.statusGizi as String)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String? subLabel;
  final Color? subColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    this.subLabel,
    this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            unit.isEmpty ? value : '$value $unit',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (subLabel != null && subLabel!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subLabel!,
              style: TextStyle(
                color: subColor ?? AppColors.success,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final List<dynamic> daftar;
  final bool isBeratBadan;

  const _ChartCard({
    required this.title,
    required this.daftar,
    required this.isBeratBadan,
  });

  @override
  Widget build(BuildContext context) {
    final values = daftar
        .map((p) => isBeratBadan ? p.beratBadan : p.tinggiBadan)
        .cast<double>()
        .toList();
    final spots = values
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isBeratBadan
                      ? Icons.monitor_weight_outlined
                      : Icons.height_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 172,
              child: LineChart(
                LineChartData(
                  minY: (minVal - 2).clamp(0, double.infinity),
                  maxY: maxVal + 2,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: AppColors.divider, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (v, _) => Text(
                          v.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= daftar.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            '${daftar[idx].usiaBulan} bln',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
