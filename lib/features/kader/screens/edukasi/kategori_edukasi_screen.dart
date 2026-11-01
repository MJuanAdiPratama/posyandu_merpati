import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../providers/edukasi_kader_provider.dart';

class KategoriEdukasiScreen extends StatefulWidget {
  const KategoriEdukasiScreen({super.key});

  @override
  State<KategoriEdukasiScreen> createState() => _KategoriEdukasiScreenState();
}

class _KategoriEdukasiScreenState extends State<KategoriEdukasiScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EdukasiKaderProvider>().muatKategori();
    });
  }

  void _tampilkanForm({String? id, String? nama, String? deskripsi}) {
    final namaCtrl = TextEditingController(text: nama);
    final deskripsiCtrl = TextEditingController(text: deskripsi);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              // header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      id == null
                          ? Icons.add_circle_outline_rounded
                          : Icons.edit_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    id == null ? 'Tambah Kategori' : 'Edit Kategori',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: namaCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama Kategori',
                  hintText: 'Contoh: Gizi, Imunisasi, Tumbuh Kembang',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppStrings.fieldWajibDiisi
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: deskripsiCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  hintText: 'Keterangan singkat tentang kategori ini',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final provider = ctx.read<EdukasiKaderProvider>();
                  final namaVal = namaCtrl.text.trim();
                  final deskVal = deskripsiCtrl.text.trim().isEmpty
                      ? null
                      : deskripsiCtrl.text.trim();
                  final bool ok;
                  if (id == null) {
                    ok = await provider.tambahKategori(namaVal, deskVal);
                  } else {
                    ok = await provider.updateKategori(id, namaVal, deskVal);
                  }
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (ok) {
                    CustomSnackbar.sukses(ctx, AppStrings.berhasilDisimpan);
                  } else {
                    CustomSnackbar.gagal(ctx, AppStrings.gagalMenyimpan);
                  }
                },
                child: const Text(
                  AppStrings.simpan,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _konfirmasiHapus(String id, String nama) async {
    final konfirmasi = await showConfirmationDialog(
      context: context,
      title: 'Hapus Kategori?',
      message:
          'Kategori "$nama" akan dihapus. Artikel yang menggunakan kategori ini tidak ikut terhapus.',
      icon: Icons.delete_outline_rounded,
    );

    if (konfirmasi != true || !mounted) return;
    final ok = await context.read<EdukasiKaderProvider>().hapusKategori(id);
    if (!mounted) return;
    if (ok) {
      CustomSnackbar.sukses(context, AppStrings.berhasilDihapus);
    } else {
      CustomSnackbar.gagal(context, AppStrings.gagalMenyimpan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: 'Kategori Edukasi'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tampilkanForm(),
        child: const Icon(Icons.add),
      ),
      body: Consumer<EdukasiKaderProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading) return const LoadingWidget();
          if (provider.kategori.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.category_outlined,
              pesan: 'Belum ada kategori edukasi',
              onRetry: provider.muatKategori,
            );
          }
          return RefreshIndicator(
            onRefresh: provider.muatKategori,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              children: [
                KaderHeroPanel(
                  title: 'Kategori Edukasi',
                  subtitle:
                      '${provider.kategori.length} kategori tersedia untuk pengelompokan artikel.',
                  icon: Icons.category_rounded,
                ),
                const SizedBox(height: 14),
                const SectionTitle(title: 'Daftar Kategori'),
                const SizedBox(height: 10),
                ...provider.kategori.map((item) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMint,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.label_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.nama,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (item.deskripsi != null &&
                                    item.deskripsi!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.deskripsi!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.secondary,
                            ),
                            onPressed: () => _tampilkanForm(
                              id: item.id,
                              nama: item.nama,
                              deskripsi: item.deskripsi,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                            ),
                            onPressed: () =>
                                _konfirmasiHapus(item.id, item.nama),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
