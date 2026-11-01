import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../routes/app_routes.dart';
import '../../providers/edukasi_ortu_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Edukasi
// ─────────────────────────────────────────────────────────────────────────────

class EdukasiTab extends StatefulWidget {
  const EdukasiTab({super.key});

  @override
  State<EdukasiTab> createState() => _EdukasiTabState();
}

class _EdukasiTabState extends State<EdukasiTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EdukasiOrtuProvider>().muatDaftar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const GradientPageHeader(
            title: 'Edukasi',
            subtitle: 'Artikel dan tips kesehatan untuk keluarga.',
            icon: Icons.menu_book_rounded,
          ),
          Expanded(
            child: Consumer<EdukasiOrtuProvider>(
              builder: (_, provider, __) {
                if (provider.isLoading) return const LoadingWidget();
                if (provider.daftar.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.article_outlined,
                    pesan: 'Belum ada artikel edukasi',
                    onRetry: provider.muatDaftar,
                  );
                }
                return RefreshIndicator(
                  onRefresh: provider.muatDaftar,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: provider.daftar.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Colors.white, AppColors.surfaceMint],
                            ),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Row(
                            children: [
                              IconBadge(
                                icon: Icons.menu_book_rounded,
                                size: 48,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Artikel kesehatan balita dari sumber terpercaya.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final edukasi = provider.daftar[index - 1];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            provider.pilih(edukasi);
                            Navigator.pushNamed(
                              context,
                              AppRoutes.detailEdukasi,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.health_and_safety_rounded,
                                    color: AppColors.secondary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (edukasi.kategori != null &&
                                          edukasi.kategori!.isNotEmpty)
                                        StatusBadge(
                                          label: edukasi.kategori!,
                                          color: AppColors.success,
                                        ),
                                      const SizedBox(height: 5),
                                      Text(
                                        edukasi.judul,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        edukasi.isi.length > 70
                                            ? '${edukasi.isi.substring(0, 70)}...'
                                            : edukasi.isi,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
