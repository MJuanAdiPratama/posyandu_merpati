import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../data/models/edukasi_model.dart';
import '../../providers/edukasi_kader_provider.dart';

class TambahEdukasiScreen extends StatefulWidget {
  const TambahEdukasiScreen({super.key});

  @override
  State<TambahEdukasiScreen> createState() => _TambahEdukasiScreenState();
}

class _TambahEdukasiScreenState extends State<TambahEdukasiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulCtrl = TextEditingController();
  final _isiCtrl = TextEditingController();
  final _kategoriCtrl = TextEditingController();

  EdukasiModel? _editData;
  String? _kategoriId;
  bool _isEdit = false;
  XFile? _imageFile;
  String? _gambarUrlLama;
  bool _hapusGambar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EdukasiKaderProvider>().muatKategori();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isEdit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is EdukasiModel) {
        _editData = args;
        _judulCtrl.text = args.judul;
        _isiCtrl.text = args.isi;
        _kategoriId = args.kategoriId;
        _kategoriCtrl.text = args.kategori ?? '';
        _gambarUrlLama = args.gambarUrl;
        _isEdit = true;
      }
    }
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _isiCtrl.dispose();
    _kategoriCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihGambar(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 720,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _imageFile = picked;
        _hapusGambar = false;
      });
    }
  }

  void _showPilihGambarSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pilihGambar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _pilihGambar(ImageSource.camera);
              },
            ),
            if (_imageFile != null || _gambarUrlLama != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Hapus Gambar',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imageFile = null;
                    _hapusGambar = true;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pratinjau() async {
    if (!_formKey.currentState!.validate()) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pratinjau Artikel'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _judulCtrl.text,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              if (_kategoriCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _kategoriCtrl.text,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              const Divider(),
              Text(
                _isiCtrl.text.length > 200
                    ? '${_isiCtrl.text.substring(0, 200)}...'
                    : _isiCtrl.text,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<EdukasiKaderProvider>();
    final kategori = _kategoriCtrl.text.trim().isEmpty
        ? null
        : _kategoriCtrl.text.trim();

    String? gambarUrl;
    if (_imageFile != null) {
      gambarUrl = await provider.uploadGambar(_imageFile!.path);
      if (!mounted) return;
      if (gambarUrl == null) {
        CustomSnackbar.gagal(context, provider.error ?? 'Gagal upload gambar');
        return;
      }
    }

    bool berhasil;
    if (_editData != null) {
      berhasil = await provider.update(
        _editData!.id,
        _judulCtrl.text.trim(),
        _isiCtrl.text.trim(),
        _kategoriId,
        kategori,
        gambarUrl: gambarUrl,
        hapusGambar: _hapusGambar,
        gambarUrlLama: _gambarUrlLama,
      );
    } else {
      berhasil = await provider.tambah(
        judul: _judulCtrl.text.trim(),
        isi: _isiCtrl.text.trim(),
        kategoriId: _kategoriId,
        kategori: kategori,
        gambarUrl: gambarUrl,
      );
    }
    if (!mounted) return;
    if (berhasil) {
      CustomSnackbar.sukses(context, AppStrings.berhasilDisimpan);
      Navigator.pop(context);
    } else {
      CustomSnackbar.gagal(
          context, provider.error ?? AppStrings.gagalMenyimpan);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? AppStrings.editEdukasi : AppStrings.tambahEdukasi;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: title),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form Artikel Card
              _FormCard(
                title: 'Form Artikel',
                icon: Icons.article_rounded,
                children: [
                  // Judul
                  TextFormField(
                    controller: _judulCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Judul Artikel *',
                      hintText: 'Masukkan judul artikel yang menarik',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? AppStrings.fieldWajibDiisi
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Kategori
                  Consumer<EdukasiKaderProvider>(
                    builder: (_, provider, __) {
                      final selectedName = _kategoriCtrl.text.trim();
                      final options = provider.kategori.isNotEmpty
                          ? provider.kategori
                              .map((k) => _KategoriOption(
                                    value: k.id,
                                    id: k.id,
                                    nama: k.nama,
                                  ))
                              .toList()
                          : provider.pilihanKategori
                              .map((k) => _KategoriOption(
                                    value: k,
                                    nama: k,
                                  ))
                              .toList();

                      _KategoriOption? matched;
                      for (final o in options) {
                        if (o.id == _kategoriId || o.nama == selectedName) {
                          matched = o;
                          break;
                        }
                      }

                      return DropdownButtonFormField<String>(
                        initialValue: matched?.value,
                        decoration: const InputDecoration(
                          labelText: 'Kategori *',
                          hintText: 'Pilih kategori artikel',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: options
                            .map((o) => DropdownMenuItem(
                                  value: o.value,
                                  child: Text(o.nama),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          final o = options.firstWhere((x) => x.value == v);
                          setState(() {
                            _kategoriId = o.id;
                            _kategoriCtrl.text = o.nama;
                          });
                        },
                        validator: (v) =>
                            v == null || v.isEmpty
                                ? AppStrings.fieldWajibDiisi
                                : null,
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // Isi Artikel
                  TextFormField(
                    controller: _isiCtrl,
                    maxLines: 10,
                    minLines: 6,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      labelText: 'Isi Artikel *',
                      hintText:
                          'Tulis isi artikel di sini...\n\nGunakan - untuk bullet point\n1. untuk numbered list',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 170),
                        child: Icon(Icons.article_outlined),
                      ),
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? AppStrings.fieldWajibDiisi
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Upload Gambar
              _FormCard(
                title: 'Upload Gambar',
                icon: Icons.image_rounded,
                children: [
                  Consumer<EdukasiKaderProvider>(
                    builder: (_, p, __) {
                      final adaBaru = _imageFile != null;
                      final adaLama = _gambarUrlLama != null && !_hapusGambar;
                      final tampil = adaBaru || adaLama;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (tampil) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: adaBaru
                                  ? Image.file(
                                      File(_imageFile!.path),
                                      width: double.infinity,
                                      height: 160,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      _gambarUrlLama!,
                                      width: double.infinity,
                                      height: 160,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            const SizedBox(height: 10),
                          ] else ...[
                            // Drop zone placeholder
                            GestureDetector(
                              onTap: p.isUploadingGambar
                                  ? null
                                  : _showPilihGambarSheet,
                              child: Container(
                                width: double.infinity,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMint,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 36,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Klik untuk upload gambar',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Format: JPG, PNG  •  Maks. 2 MB',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          OutlinedButton.icon(
                            onPressed: p.isUploadingGambar
                                ? null
                                : _showPilihGambarSheet,
                            icon: p.isUploadingGambar
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Icon(
                                    tampil
                                        ? Icons.edit_outlined
                                        : Icons.add_photo_alternate_outlined,
                                    size: 18,
                                  ),
                            label: Text(
                              p.isUploadingGambar
                                  ? 'Mengupload...'
                                  : tampil
                                      ? 'Ganti Gambar'
                                      : 'Pilih Gambar',
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 40),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action buttons
              Consumer<EdukasiKaderProvider>(
                builder: (_, p, __) => Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: p.isLoading ? null : _pratinjau,
                        icon: const Icon(
                          Icons.visibility_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        label: const Text(
                          'Pratinjau Artikel',
                          style: TextStyle(color: AppColors.primary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: p.isLoading ? null : _simpan,
                        icon: p.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.save_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                        label: const Text(
                          'Simpan Artikel',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
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
  }
}

// ─── Form Card ───────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _FormCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Kategori Option ─────────────────────────────────────────────────────────

class _KategoriOption {
  final String value;
  final String? id;
  final String nama;

  const _KategoriOption({required this.value, required this.nama, this.id});
}
