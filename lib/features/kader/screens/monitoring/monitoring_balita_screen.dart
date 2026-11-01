import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/age_calculator.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/growth_status_badge.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/monitoring_balita_item.dart';
import '../../../../routes/app_routes.dart';
import '../../providers/balita_kader_provider.dart';
import '../../providers/monitoring_balita_provider.dart';

class MonitoringBalitaScreen extends StatefulWidget {
  const MonitoringBalitaScreen({super.key});

  @override
  State<MonitoringBalitaScreen> createState() =>
      _MonitoringBalitaScreenState();
}

class _MonitoringBalitaScreenState extends State<MonitoringBalitaScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _showSearch = false;
  String _filter = 'semua';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MonitoringBalitaItem> _terapkanFilter(List<MonitoringBalitaItem> all) {
    var list = switch (_filter) {
      'perlu_perhatian' => all.where((i) => i.perluPerhatian).toList(),
      'normal' => all.where((i) => !i.perluPerhatian).toList(),
      _ => all,
    };
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((i) => i.balita.nama.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  Future<void> _muatUlang() async {
    await context.read<MonitoringBalitaProvider>().muatData();
    if (!mounted) return;
    final error = context.read<MonitoringBalitaProvider>().error;
    if (error != null) {
      CustomSnackbar.gagal(context, 'Gagal memuat data monitoring balita');
    }
  }

  void _bukaDetail(MonitoringBalitaItem item) {
    context.read<BalitaKaderProvider>().pilihBalita(item.balita);
    Navigator.pushNamed(context, AppRoutes.detailBalita);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MonitoringBalitaProvider>();
    final filtered = _terapkanFilter(provider.daftar);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _MonitoringHeader(
            showSearch: _showSearch,
            searchCtrl: _searchCtrl,
            onSearch: (v) => setState(() => _query = v),
            onClear: () => setState(() {
              _searchCtrl.clear();
              _query = '';
            }),
            onToggleSearch: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchCtrl.clear();
                _query = '';
              }
            }),
          ),
          Transform.translate(
            offset: const Offset(0, -22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _RingkasanCard(
                total: provider.daftar.length,
                perluPerhatian: provider.jumlahPerluPerhatian,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _FilterBar(
              selected: _filter,
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: provider.isLoading
                ? const LoadingWidget()
                : filtered.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.groups_rounded,
                    pesan: provider.daftar.isEmpty
                        ? 'Belum ada balita terverifikasi untuk dipantau'
                        : 'Tidak ada balita yang cocok dengan filter ini',
                    onRetry: _muatUlang,
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _muatUlang,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (_, index) => _MonitoringCard(
                        item: filtered[index],
                        onTap: () => _bukaDetail(filtered[index]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MonitoringHeader extends StatelessWidget {
  final bool showSearch;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;
  final VoidCallback onToggleSearch;

  const _MonitoringHeader({
    required this.showSearch,
    required this.searchCtrl,
    required this.onSearch,
    required this.onClear,
    required this.onToggleSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, 0, 16, showSearch ? 20 : 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Monitoring Balita',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    showSearch
                        ? Icons.search_off_rounded
                        : Icons.search_rounded,
                    color: Colors.white,
                  ),
                  onPressed: onToggleSearch,
                ),
              ],
            ),
            if (showSearch) ...[
              const SizedBox(height: 10),
              TextField(
                controller: searchCtrl,
                autofocus: true,
                onChanged: onSearch,
                decoration: InputDecoration(
                  hintText: 'Cari nama balita',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: onClear,
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RingkasanCard extends StatelessWidget {
  final int total;
  final int perluPerhatian;

  const _RingkasanCard({required this.total, required this.perluPerhatian});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Expanded(
            child: _RingkasanItem(
              label: 'Total Balita Dipantau',
              value: '$total',
              color: AppColors.primary,
              icon: Icons.groups_rounded,
            ),
          ),
          Container(width: 1, height: 48, color: AppColors.divider),
          Expanded(
            child: _RingkasanItem(
              label: 'Perlu Perhatian',
              value: '$perluPerhatian',
              color: perluPerhatian > 0
                  ? AppColors.warning
                  : AppColors.success,
              icon: Icons.health_and_safety_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingkasanItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _RingkasanItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
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

class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FilterChip(
            label: 'Semua',
            selected: selected == 'semua',
            color: AppColors.primary,
            onTap: () => onChanged('semua'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FilterChip(
            label: 'Perlu Perhatian',
            selected: selected == 'perlu_perhatian',
            color: AppColors.warning,
            onTap: () => onChanged('perlu_perhatian'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FilterChip(
            label: 'Normal',
            selected: selected == 'normal',
            color: AppColors.success,
            onTap: () => onChanged('normal'),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _MonitoringCard extends StatelessWidget {
  final MonitoringBalitaItem item;
  final VoidCallback onTap;

  const _MonitoringCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final balita = item.balita;
    final isBoy = balita.jenisKelamin == 'Laki-laki';
    final statusColor = growthStatusColor(item.statusGizi);
    final statusIcon = growthStatusIcon(item.statusGizi);

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: isBoy
                        ? AppColors.surfaceTeal
                        : const Color(0xFFFFE4EE),
                    child: Icon(
                      isBoy ? Icons.boy_rounded : Icons.girl_rounded,
                      color: isBoy
                          ? AppColors.primary
                          : const Color(0xFFE91E8C),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Usia ${AgeCalculator.formatUsia(item.usiaBulan)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Badge(
                    label: item.statusGizi,
                    color: statusColor,
                    icon: statusIcon,
                  ),
                  if (item.jumlahImunisasiTerlambat > 0)
                    _Badge(
                      label:
                          '${item.jumlahImunisasiTerlambat} Imunisasi Terlambat',
                      color: AppColors.error,
                      icon: Icons.vaccines_rounded,
                    )
                  else
                    const _Badge(
                      label: 'Imunisasi Sesuai Jadwal',
                      color: AppColors.success,
                      icon: Icons.vaccines_rounded,
                    ),
                  if (item.belumDiperiksaBulanIni)
                    const _Badge(
                      label: 'Belum Diperiksa Bulan Ini',
                      color: AppColors.warning,
                      icon: Icons.event_busy_rounded,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Badge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
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
