import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/edukasi_model.dart';
import '../../../../routes/app_routes.dart';
import '../../providers/edukasi_ortu_provider.dart';
import '../../providers/notifikasi_ortu_provider.dart';

class EdukasiScreen extends StatefulWidget {
  const EdukasiScreen({super.key});

  @override
  State<EdukasiScreen> createState() => _EdukasiScreenState();
}

class _EdukasiScreenState extends State<EdukasiScreen> {
  static const int _profileTabIndex = 4;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EdukasiOrtuProvider>().muatDaftar();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientPageHeader(
            title: 'Edukasi',
            subtitle: 'Artikel dan tips kesehatan untuk keluarga.',
            icon: Icons.menu_book_rounded,
            actions: [
              Consumer<NotifikasiOrtuProvider>(
                builder: (_, notifProvider, __) {
                  final unread = notifProvider.jumlahBelumDibaca;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.notifikasi),
                      ),
                      if (unread > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                unread > 9 ? '9+' : '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_rounded, color: Colors.white),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.dashboardOrtu,
                  (_) => false,
                  arguments: const {'initialIndex': _profileTabIndex},
                ),
              ),
            ],
          ),
          Expanded(
            child: Consumer<EdukasiOrtuProvider>(
              builder: (_, provider, __) {
                if (provider.isLoading) return const LoadingWidget();

                if (provider.semuaDaftar.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.article_outlined,
                    pesan: 'Belum ada artikel edukasi',
                    onRetry: provider.muatDaftar,
                  );
                }

                final daftar = provider.daftar;
                final kategoriList = provider.kategoriList;

                return RefreshIndicator(
                  onRefresh: provider.muatDaftar,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Search bar
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: _SearchBar(
                            controller: _searchCtrl,
                            onChanged: provider.setSearch,
                          ),
                        ),
                      ),

                      // Filter chips kategori
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                          child: _KategoriChips(
                            kategoriList: kategoriList,
                            selected: provider.filterKategori,
                            onSelected: provider.setFilter,
                          ),
                        ),
                      ),

                      // Hero Banner (hanya tampil jika tidak ada filter aktif)
                      if (provider.filterKategori == null &&
                          provider.searchQuery.isEmpty &&
                          provider.semuaDaftar.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                            child: _HeroBanner(
                              edukasi: provider.semuaDaftar.first,
                              onTap: () {
                                provider.pilih(provider.semuaDaftar.first);
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.detailEdukasi,
                                );
                              },
                            ),
                          ),
                        ),

                      // Section header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                          child: Text(
                            provider.filterKategori != null
                                ? provider.filterKategori!
                                : provider.searchQuery.isNotEmpty
                                ? 'Hasil Pencarian'
                                : 'Artikel Terkini',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),

                      // Empty filtered state
                      if (daftar.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 32,
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: AppColors.textDisabled,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    provider.searchQuery.isNotEmpty
                                        ? 'Tidak ada artikel untuk\n"${provider.searchQuery}"'
                                        : 'Tidak ada artikel untuk\n"${provider.filterKategori}"',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          sliver: SliverList.separated(
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemCount: daftar.length,
                            itemBuilder: (ctx, i) {
                              final edukasi = daftar[i];
                              return _ArtikelCard(
                                edukasi: edukasi,
                                onTap: () {
                                  provider.pilih(edukasi);
                                  Navigator.pushNamed(
                                    ctx,
                                    AppRoutes.detailEdukasi,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar ─────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Cari artikel edukasi',
          hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ─── Kategori Chips ─────────────────────────────────────────────────────────

class _KategoriChips extends StatelessWidget {
  final List<String> kategoriList;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _KategoriChips({
    required this.kategoriList,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _Chip(
            label: 'Semua',
            isActive: selected == null,
            onTap: () => onSelected(null),
          ),
          ...kategoriList.map(
            (k) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _Chip(
                label: k,
                isActive: selected == k,
                onTap: () => onSelected(selected == k ? null : k),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Hero Banner ────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final EdukasiModel edukasi;
  final VoidCallback onTap;

  const _HeroBanner({required this.edukasi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 172,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background image (jika ada)
            if (edukasi.gambarUrl != null)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 140,
                child: CachedNetworkImage(
                  imageUrl: edukasi.gambarUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox(),
                ),
              ),
            // Gradient overlay kanan
            Positioned(
              right: 80,
              top: 0,
              bottom: 0,
              width: 80,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      AppColors.primary.withValues(alpha: 0),
                      AppColors.primary,
                    ],
                  ),
                ),
              ),
            ),
            // Text
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 190,
                    child: Text(
                      'Tumbuh Sehat,\nMasa Depan Hebat',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 180,
                    child: Text(
                      'Edukasi terpercaya untuk dukung tumbuh kembang anak.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Baca Sekarang',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
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

// ─── Artikel Card ────────────────────────────────────────────────────────────

class _ArtikelCard extends StatelessWidget {
  final EdukasiModel edukasi;
  final VoidCallback onTap;

  const _ArtikelCard({required this.edukasi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final adaGambar =
        edukasi.gambarUrl != null && edukasi.gambarUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child: adaGambar
                  ? CachedNetworkImage(
                      imageUrl: edukasi.gambarUrl!,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _PlaceholderThumb(),
                      errorWidget: (_, __, ___) => _PlaceholderThumb(),
                    )
                  : _PlaceholderThumb(),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (edukasi.kategori != null &&
                        edukasi.kategori!.isNotEmpty) ...[
                      _KategoriBadge(edukasi.kategori!),
                      const SizedBox(height: 5),
                    ],
                    Text(
                      edukasi.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      edukasi.ringkasanDisplay,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.textDisabled,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${edukasi.estimasiMenitBaca} min baca',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textDisabled,
                          ),
                        ),
                      ],
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

class _PlaceholderThumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      color: AppColors.surfaceMint,
      child: const Icon(
        Icons.health_and_safety_rounded,
        size: 32,
        color: AppColors.primary,
      ),
    );
  }
}

class _KategoriBadge extends StatelessWidget {
  final String label;
  const _KategoriBadge(this.label);

  Color get _color {
    final colors = {
      'Gizi': const Color(0xFF4CAF50),
      'Imunisasi': AppColors.info,
      'Stunting': const Color(0xFF9C27B0),
      'Perawatan': AppColors.warning,
      'Tumbuh Kembang': AppColors.secondary,
    };
    return colors[label] ?? AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
