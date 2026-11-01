import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/jenis_imunisasi_model.dart';
import '../../providers/jenis_imunisasi_provider.dart';

class JenisImunisasiScreen extends StatefulWidget {
  const JenisImunisasiScreen({super.key});

  @override
  State<JenisImunisasiScreen> createState() => _JenisImunisasiScreenState();
}

class _JenisImunisasiScreenState extends State<JenisImunisasiScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JenisImunisasiProvider>().muatDaftar();
    });
  }

  void _tampilkanForm({
    String? id,
    String? nama,
    int? usia,
    String? kandungan,
  }) {
    final namaCtrl = TextEditingController(text: nama);
    final usiaCtrl = TextEditingController(text: usia?.toString() ?? '');
    final kandunganCtrl = TextEditingController(text: kandungan);
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
                      id == null ? Icons.vaccines_rounded : Icons.edit_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    id == null ? 'Tambah Imunisasi' : 'Edit Imunisasi',
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
                decoration: const InputDecoration(
                  labelText: 'Nama Imunisasi',
                  prefixIcon: Icon(Icons.vaccines_outlined),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? AppStrings.fieldWajibDiisi
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: usiaCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Usia (bulan)',
                  prefixIcon: Icon(Icons.child_care_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return AppStrings.fieldWajibDiisi;
                  if (int.tryParse(v) == null) return 'Masukkan angka valid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: kandunganCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Kandungan Obat',
                  prefixIcon: Icon(Icons.science_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppStrings.fieldWajibDiisi
                    : null,
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
                  final provider = ctx.read<JenisImunisasiProvider>();
                  final namaVal = namaCtrl.text.trim();
                  final usiaParsed = int.parse(usiaCtrl.text);
                  final kandunganVal = kandunganCtrl.text.trim();
                  bool ok;
                  if (id == null) {
                    ok = await provider.tambah(
                      namaVal,
                      usiaParsed,
                      null,
                      kandunganVal,
                    );
                  } else {
                    ok = await provider.update(
                      id,
                      namaVal,
                      usiaParsed,
                      null,
                      kandunganVal,
                    );
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

  Future<void> _konfirmasiHapus(
    JenisImunisasiProvider provider,
    JenisImunisasiModel item,
  ) async {
    final ok = await showConfirmationDialog(
      context: context,
      title: 'Hapus Jenis Imunisasi',
      message:
          'Hapus jenis imunisasi "${item.namaImunisasi}"? Data ini tidak dapat dikembalikan.',
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;

    final berhasil = await provider.hapus(item.id);
    if (!mounted) return;
    if (berhasil) {
      CustomSnackbar.sukses(context, AppStrings.berhasilDihapus);
    } else {
      CustomSnackbar.gagal(context, AppStrings.gagalMenyimpan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: AppStrings.jenisImunisasi),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tampilkanForm(),
        child: const Icon(Icons.add),
      ),
      body: Consumer<JenisImunisasiProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading) return const LoadingWidget();
          if (provider.daftar.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.vaccines,
              pesan: 'Belum ada jenis imunisasi',
              onRetry: provider.muatDaftar,
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            children: [
              KaderHeroPanel(
                title: 'Jenis Imunisasi',
                subtitle:
                    '${provider.daftar.length} jenis imunisasi tersedia untuk pencatatan kader.',
                icon: Icons.list_alt_rounded,
              ),
              const SizedBox(height: 14),
              const SectionTitle(title: 'Daftar Jenis Imunisasi'),
              const SizedBox(height: 10),
              ...provider.daftar.map((item) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMint,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(
                            child: Text(
                              '${item.usiaBulan}',
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.namaImunisasi,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InfoTextRow(
                                icon: Icons.calendar_month_outlined,
                                text: 'Usia ${item.usiaBulan} bulan',
                              ),
                              if (item.kandungan != null &&
                                  item.kandungan!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                InfoTextRow(
                                  icon: Icons.science_outlined,
                                  text: item.kandungan!,
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
                            nama: item.namaImunisasi,
                            usia: item.usiaBulan,
                            kandungan: item.kandungan,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          onPressed: () => _konfirmasiHapus(provider, item),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
