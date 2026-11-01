import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../providers/balita_kader_provider.dart';

class EditBalitaScreen extends StatefulWidget {
  const EditBalitaScreen({super.key});

  @override
  State<EditBalitaScreen> createState() => _EditBalitaScreenState();
}

class _EditBalitaScreenState extends State<EditBalitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nikCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _tempatLahirCtrl = TextEditingController();
  final _namaOrtuCtrl = TextEditingController();
  final _kontakCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();

  DateTime? _tanggalLahir;
  late String _jenisKelamin;

  @override
  void initState() {
    super.initState();
    final balita = context.read<BalitaKaderProvider>().selected!;
    _nikCtrl.text = balita.nik;
    _namaCtrl.text = balita.nama;
    _tempatLahirCtrl.text = balita.tempatLahir ?? '';
    _namaOrtuCtrl.text = balita.namaOrtu;
    _kontakCtrl.text = balita.kontakOrtu ?? '';
    _alamatCtrl.text = balita.alamat ?? '';
    _tanggalLahir = balita.tanggalLahir;
    _jenisKelamin = balita.jenisKelamin;
  }

  @override
  void dispose() {
    _nikCtrl.dispose();
    _namaCtrl.dispose();
    _tempatLahirCtrl.dispose();
    _namaOrtuCtrl.dispose();
    _kontakCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _tanggalLahir ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2018),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) setState(() => _tanggalLahir = picked);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tanggalLahir == null) {
      CustomSnackbar.gagal(context, 'Tanggal lahir wajib diisi');
      return;
    }

    final provider = context.read<BalitaKaderProvider>();
    final id = provider.selected!.id;
    final tgl = _tanggalLahir!;

    final berhasil = await provider.update(id, {
      'nik': _nikCtrl.text.trim(),
      'nama': _namaCtrl.text.trim(),
      'tempat_lahir': _tempatLahirCtrl.text.trim(),
      'tanggal_lahir':
          '${tgl.year}-${tgl.month.toString().padLeft(2, '0')}-${tgl.day.toString().padLeft(2, '0')}',
      'jenis_kelamin': _jenisKelamin,
      'nama_ortu': _namaOrtuCtrl.text.trim(),
      'kontak_ortu': _kontakCtrl.text.trim(),
      'alamat': _alamatCtrl.text.trim(),
    });

    if (!mounted) return;
    if (berhasil) {
      CustomSnackbar.sukses(context, AppStrings.berhasilDisimpan);
      Navigator.pop(context);
    } else {
      CustomSnackbar.gagal(
        context,
        provider.error ?? AppStrings.gagalMenyimpan,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: 'Edit Data Balita'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const KaderHeroPanel(
                title: 'Edit Data Balita',
                subtitle: 'Perbarui data balita dan informasi orang tua.',
                icon: Icons.edit_note_rounded,
              ),
              const SizedBox(height: 16),
              const SectionTitle(title: 'Data Balita'),
              const SizedBox(height: 10),
              _FormSection(
                children: [
                  _buildField(
                    _nikCtrl,
                    AppStrings.nikBalita,
                    Icons.badge_outlined,
                    tipe: TextInputType.number,
                    maxLength: 16,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    customValidator: (v) {
                      if (v == null || v.isEmpty) {
                        return AppStrings.fieldWajibDiisi;
                      }
                      if (v.length != 16) return 'NIK harus 16 digit';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    _namaCtrl,
                    AppStrings.namaBalita,
                    Icons.person_outline,
                    wajib: true,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    _tempatLahirCtrl,
                    AppStrings.tempatLahir,
                    Icons.place_outlined,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pilihTanggal,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: AppStrings.tanggalLahir,
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      child: Text(
                        _tanggalLahir != null
                            ? DateFormat(
                                'dd MMMM yyyy',
                                'id_ID',
                              ).format(_tanggalLahir!)
                            : 'Pilih tanggal lahir',
                        style: TextStyle(
                          color: _tanggalLahir != null
                              ? AppColors.textPrimary
                              : AppColors.textDisabled,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _jenisKelamin,
                    decoration: const InputDecoration(
                      labelText: AppStrings.jenisKelamin,
                      prefixIcon: Icon(Icons.wc_rounded),
                    ),
                    items: ['Laki-laki', 'Perempuan']
                        .map(
                          (jk) => DropdownMenuItem(value: jk, child: Text(jk)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _jenisKelamin = v!),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const SectionTitle(title: 'Data Orang Tua'),
              const SizedBox(height: 10),
              _FormSection(
                children: [
                  _buildField(
                    _namaOrtuCtrl,
                    AppStrings.namaOrtu,
                    Icons.people_outline,
                    wajib: true,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    _kontakCtrl,
                    AppStrings.kontakOrtu,
                    Icons.phone_outlined,
                    tipe: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    _alamatCtrl,
                    AppStrings.alamat,
                    Icons.home_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Consumer<BalitaKaderProvider>(
                builder: (_, p, __) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: p.isLoading ? null : _simpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: p.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            AppStrings.simpan,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool wajib = false,
    TextInputType? tipe,
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? customValidator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: tipe,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator:
          customValidator ??
          (wajib
              ? (v) =>
                    (v == null || v.isEmpty) ? AppStrings.fieldWajibDiisi : null
              : null),
    );
  }
}

class _FormSection extends StatelessWidget {
  final List<Widget> children;

  const _FormSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}
