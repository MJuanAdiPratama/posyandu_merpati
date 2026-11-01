import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/age_calculator.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/balita_model.dart';
import '../../../../routes/app_routes.dart';
import '../../providers/balita_kader_provider.dart';

class DaftarBalitaScreen extends StatefulWidget {
  final bool standalone;

  const DaftarBalitaScreen({super.key, this.standalone = true});

  @override
  State<DaftarBalitaScreen> createState() => _DaftarBalitaScreenState();
}

class _DaftarBalitaScreenState extends State<DaftarBalitaScreen> {
  final _searchCtrl = TextEditingController();
  String? _filterStatus;
  String _query = '';
  bool _showSearch = false;
  bool _showFilter = false;

  List<BalitaModel> _terapkanFilter(List<BalitaModel> all) {
    var list = _filterStatus == null
        ? all
        : all.where((b) => b.statusVerifikasi == _filterStatus).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where(
            (b) =>
                b.nama.toLowerCase().contains(q) ||
                b.nik.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BalitaKaderProvider>().muatDaftar();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bukaTambah() async {
    final provider = context.read<BalitaKaderProvider>();
    await Navigator.pushNamed(context, AppRoutes.tambahBalita);
    if (mounted) provider.muatDaftar();
  }

  Future<void> _bukaDetail(BalitaKaderProvider provider, BalitaModel balita) {
    provider.pilihBalita(balita);
    return Navigator.pushNamed(context, AppRoutes.detailBalita);
  }

  @override
  Widget build(BuildContext context) {
    final body = Consumer<BalitaKaderProvider>(
      builder: (_, provider, __) {
        final filtered = _terapkanFilter(provider.daftar);

        return Column(
          children: [
            _ListHeader(
              showBack: widget.standalone,
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
              onToggleFilter: () => setState(() => _showFilter = !_showFilter),
              filterActive: _filterStatus != null,
            ),
            if (_showFilter)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _FilterBar(
                  selectedStatus: _filterStatus,
                  onChanged: (status) =>
                      setState(() => _filterStatus = status),
                ),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: provider.isLoading
                  ? const LoadingWidget()
                  : filtered.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.child_care_rounded,
                      pesan: _filterStatus == null
                          ? 'Belum ada data balita'
                          : 'Tidak ada balita dengan status ini',
                      onRetry: provider.muatDaftar,
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: provider.muatDaftar,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: filtered.length,
                        itemBuilder: (_, index) => _BalitaListCard(
                          balita: filtered[index],
                          onTap: () => _bukaDetail(provider, filtered[index]),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );

    if (!widget.standalone) return body;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: _bukaTambah,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  final bool showBack;
  final bool showSearch;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;
  final VoidCallback onToggleSearch;
  final VoidCallback onToggleFilter;
  final bool filterActive;

  const _ListHeader({
    required this.showBack,
    required this.showSearch,
    required this.searchCtrl,
    required this.onSearch,
    required this.onClear,
    required this.onToggleSearch,
    required this.onToggleFilter,
    required this.filterActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 0, 16, showSearch ? 20 : 16),
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
                if (showBack)
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Kembali',
                  )
                else
                  const SizedBox(width: 48),
                const Expanded(
                  child: Text(
                    'Data Balita',
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
                    showSearch ? Icons.search_off_rounded : Icons.search_rounded,
                    color: Colors.white,
                  ),
                  onPressed: onToggleSearch,
                  tooltip: showSearch ? 'Tutup pencarian' : 'Cari',
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, color: Colors.white),
                      onPressed: onToggleFilter,
                      tooltip: 'Filter',
                    ),
                    if (filterActive)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
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
                  hintText: 'Cari nama / NIK balita',
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

class _FilterBar extends StatelessWidget {
  final String? selectedStatus;
  final ValueChanged<String?> onChanged;

  const _FilterBar({required this.selectedStatus, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: _FilterChipButton(
                label: 'Semua',
                selected: selectedStatus == null,
                color: AppColors.primary,
                onTap: () => onChanged(null),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FilterChipButton(
                label: 'Disetujui',
                selected: selectedStatus == 'disetujui',
                color: AppColors.success,
                icon: Icons.check_circle_rounded,
                onTap: () => onChanged('disetujui'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FilterChipButton(
                label: 'Pending',
                selected: selectedStatus == 'pending',
                color: AppColors.warning,
                icon: Icons.info_outline_rounded,
                onTap: () => onChanged('pending'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final IconData? icon;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.icon,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: selected ? Colors.white : color, size: 16),
                const SizedBox(width: 5),
              ],
              Flexible(
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
            ],
          ),
        ),
      ),
    );
  }
}

class _BalitaListCard extends StatelessWidget {
  final BalitaModel balita;
  final VoidCallback onTap;

  const _BalitaListCard({required this.balita, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBoy = balita.jenisKelamin == 'Laki-laki';
    final usia = AgeCalculator.formatUsiaDariTanggalLahir(balita.tanggalLahir);

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
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: isBoy
                        ? AppColors.surfaceTeal
                        : const Color(0xFFFFE4EE),
                    child: Icon(
                      isBoy ? Icons.boy_rounded : Icons.girl_rounded,
                      color: isBoy
                          ? AppColors.primary
                          : const Color(0xFFE91E8C),
                      size: 38,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                balita.nama,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _StatusChip(status: balita.statusVerifikasi),
                          ],
                        ),
                        const SizedBox(height: 5),
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Orang Tua: ${balita.namaOrtu}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
              const Divider(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Pemeriksaan terakhir: ${_formatTanggal(balita.updatedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTanggal(DateTime value) {
    const bulan = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${value.day} ${bulan[value.month]} ${value.year}';
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
