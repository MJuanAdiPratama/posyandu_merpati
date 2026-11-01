import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/edukasi_model.dart';
import '../../providers/edukasi_ortu_provider.dart';

class DetailEdukasiScreen extends StatelessWidget {
  const DetailEdukasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final edukasi = args is EdukasiModel
        ? args
        : context.watch<EdukasiOrtuProvider>().selected;

    if (edukasi == null) {
      return const Scaffold(
        body: Center(child: Text('Artikel tidak ditemukan')),
      );
    }

    final adaGambar =
        edukasi.gambarUrl != null && edukasi.gambarUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar dengan gambar
          SliverAppBar(
            expandedHeight: adaGambar ? 220 : 0,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: const Text(
              'Detail Artikel',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            flexibleSpace: adaGambar
                ? FlexibleSpaceBar(
                    background: CachedNetworkImage(
                      imageUrl: edukasi.gambarUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.surfaceMint),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceMint,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: AppColors.textDisabled,
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),

          // Konten artikel
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kategori badge
                        if (edukasi.kategori != null &&
                            edukasi.kategori!.isNotEmpty) ...[
                          _KategoriBadge(edukasi.kategori!),
                          const SizedBox(height: 10),
                        ],
                        // Judul
                        Text(
                          edukasi.judul,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Author row
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryDark,
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_hospital_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Posyandu Merpati',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '•',
                                style: TextStyle(color: AppColors.textDisabled),
                              ),
                            ),
                            Text(
                              DateFormat(
                                'dd MMM yyyy',
                                'id_ID',
                              ).format(edukasi.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '•',
                                style: TextStyle(color: AppColors.textDisabled),
                              ),
                            ),
                            Text(
                              '${edukasi.estimasiMenitBaca} min baca',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        // Isi artikel
                        _IsiArtikel(isi: edukasi.isi),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Kategori Badge ─────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Isi Artikel ────────────────────────────────────────────────────────────

class _IsiArtikel extends StatelessWidget {
  final String isi;
  const _IsiArtikel({required this.isi});

  @override
  Widget build(BuildContext context) {
    // Parse baris demi baris untuk membuat tampilan berstruktur
    final lines = isi.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Heading (baris diakhiri ':' atau dalam huruf kapital semua)
      if (line.endsWith(':') ||
          (line == line.toUpperCase() && line.length > 3)) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line.replaceAll(':', ''),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Bullet point (baris dimulai '-' atau '•')
      if (line.startsWith('- ') || line.startsWith('• ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Numbered list
      final numbered = RegExp(r'^(\d+)[.)]\s+(.+)$').firstMatch(line);
      if (numbered != null) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      numbered.group(1)!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    numbered.group(2)!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Normal paragraph
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.65,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
