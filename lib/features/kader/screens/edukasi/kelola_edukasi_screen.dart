import 'package:cached_network_image/cached_network_image.dart';
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
import '../../../../data/models/edukasi_model.dart';
import '../../../../routes/app_routes.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/edukasi_kader_provider.dart';

class KelolaEdukasiScreen extends StatefulWidget {
  const KelolaEdukasiScreen({super.key});

  @override
  State<KelolaEdukasiScreen> createState() => _KelolaEdukasiScreenState();
}

class _KelolaEdukasiScreenState extends State<KelolaEdukasiScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EdukasiKaderProvider>().muatDaftar();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EdukasiKaderProvider>();
    final namaKader = context.watch<AuthProvider>().profil?.nama ?? 'Kader';
    final df = DateFormat('d MMM yyyy', 'id_ID');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'Kelola Edukasi',
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined, color: Colors.white),
            tooltip: 'Kelola Kategori',
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.kategoriEdukasi);
              if (mounted) provider.muatKategori();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.tambahEdukasi);
          if (mounted) provider.muatDaftar();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: provider.isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: provider.muatDaftar,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Greeting header
                  SliverToBoxAdapter(
                    child: _GreetingHeader(namaKader: namaKader),
                  ),

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

                  // List artikel
                  provider.daftar.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyStateWidget(
                            icon: Icons.article_outlined,
                            pesan: provider.searchQuery.isNotEmpty
                                ? 'Tidak ada artikel untuk\n"${provider.searchQuery}"'
                                : 'Belum ada artikel edukasi',
                            onRetry: provider.muatDaftar,
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          sliver: SliverList.separated(
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemCount: provider.daftar.length,
                            itemBuilder: (ctx, i) {
                              final edukasi = provider.daftar[i];
                              return _ArtikelKaderCard(
                                edukasi: edukasi,
                                df: df,
                                onLihat: () => Navigator.pushNamed(
                                  ctx,
                                  AppRoutes.detailEdukasi,
                                  arguments: edukasi,
                                ),
                                onEdit: () async {
                                  await Navigator.pushNamed(
                                    ctx,
                                    AppRoutes.tambahEdukasi,
                                    arguments: edukasi,
                                  );
                                  if (!context.mounted) return;
                                  provider.muatDaftar();
                                },
                                onHapus: () async {
                                  final ok = await provider.hapus(edukasi.id);
                                  if (!context.mounted) return;
                                  if (ok) {
                                    CustomSnackbar.sukses(
                                      context,
                                      AppStrings.berhasilDihapus,
                                    );
                                  } else {
                                    CustomSnackbar.gagal(
                                      context,
                                      AppStrings.gagalMenyimpan,
                                    );
                                  }
                                },
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

// ─── Greeting Header ────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  final String namaKader;
  const _GreetingHeader({required this.namaKader});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.surfaceMint],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $namaKader!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Kelola artikel edukasi Posyandu',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.article_rounded,
              size: 22,
              color: AppColors.primary,
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
          hintText: 'Cari artikel',
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

// ─── Artikel Kader Card ─────────────────────────────────────────────────────

class _ArtikelKaderCard extends StatelessWidget {
  final EdukasiModel edukasi;
  final DateFormat df;
  final VoidCallback onLihat;
  final VoidCallback onEdit;
  final VoidCallback onHapus;

  const _ArtikelKaderCard({
    required this.edukasi,
    required this.df,
    required this.onLihat,
    required this.onEdit,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final adaGambar =
        edukasi.gambarUrl != null && edukasi.gambarUrl!.isNotEmpty;

    return Container(
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
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onLihat,
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
                      width: 80,
                      height: 88,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _ThumbPlaceholder(),
                      errorWidget: (_, __, ___) => _ThumbPlaceholder(),
                    )
                  : _ThumbPlaceholder(),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      edukasi.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (edukasi.kategori != null) ...[
                          Text(
                            'Kategori: ${edukasi.kategori}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        df.format(edukasi.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Menu kebab
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onSelected: (v) {
                if (v == 'lihat') onLihat();
                if (v == 'edit') onEdit();
                if (v == 'hapus') _konfirmasiHapus(context);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'lihat',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Lihat Detail'),
                    ],
                  ),
                ),
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
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.error,
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
      ),
    );
  }

  Future<void> _konfirmasiHapus(BuildContext context) async {
    final konfirmasi = await showConfirmationDialog(
      context: context,
      title: 'Hapus Artikel',
      message:
          'Hapus artikel "${edukasi.judul}"? Tindakan ini tidak dapat dibatalkan.',
      icon: Icons.delete_outline_rounded,
    );
    if (konfirmasi == true) onHapus();
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 88,
      color: AppColors.surfaceMint,
      child: const Icon(
        Icons.article_rounded,
        size: 28,
        color: AppColors.primary,
      ),
    );
  }
}
