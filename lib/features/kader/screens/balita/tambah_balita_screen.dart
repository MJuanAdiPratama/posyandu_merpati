import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/city_autocomplete_field.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../data/models/balita_model.dart';
import '../../providers/balita_kader_provider.dart';

class TambahBalitaScreen extends StatefulWidget {
  const TambahBalitaScreen({super.key});

  @override
  State<TambahBalitaScreen> createState() => _TambahBalitaScreenState();
}

class _TambahBalitaScreenState extends State<TambahBalitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nikCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _tempatLahirCtrl = TextEditingController();
  final _namaOrtuCtrl = TextEditingController();
  final _kontakCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();

  DateTime? _tanggalLahir;
  String _jenisKelamin = 'Laki-laki';
  _OrtuPilihan? _ortuDipilih;
  bool _editOrtuManual = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BalitaKaderProvider>().muatDaftarOrtu();
    });
  }

  void _terapkanPilihan(_OrtuPilihan pilihan) {
    setState(() {
      _ortuDipilih = pilihan;
      _namaOrtuCtrl.text = pilihan.nama;
      _kontakCtrl.text = pilihan.noHp ?? '';
      _alamatCtrl.text = pilihan.alamat ?? '';
    });
  }

  void _resetOrtu() {
    setState(() {
      _ortuDipilih = null;
      _editOrtuManual = false;
      _namaOrtuCtrl.clear();
      _kontakCtrl.clear();
      _alamatCtrl.clear();
    });
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
      initialDate: DateTime.now().subtract(const Duration(days: 30)),
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

    final balita = BalitaModel(
      id: '',
      parentId: _ortuDipilih?.parentId,
      nik: _nikCtrl.text.trim(),
      nama: _namaCtrl.text.trim(),
      tempatLahir: _tempatLahirCtrl.text.trim(),
      tanggalLahir: _tanggalLahir!,
      jenisKelamin: _jenisKelamin,
      namaOrtu: _namaOrtuCtrl.text.trim(),
      kontakOrtu: _kontakCtrl.text.trim(),
      alamat: _alamatCtrl.text.trim(),
      statusVerifikasi: 'disetujui',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final berhasil = await context.read<BalitaKaderProvider>().tambah(balita);
    if (!mounted) return;
    if (berhasil) {
      CustomSnackbar.sukses(context, AppStrings.berhasilDisimpan);
      Navigator.pop(context);
    } else {
      CustomSnackbar.gagal(
        context,
        context.read<BalitaKaderProvider>().error ?? AppStrings.gagalMenyimpan,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: AppStrings.tambahBalita),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const KaderHeroPanel(
                title: 'Tambah Data Balita',
                subtitle:
                    'Lengkapi data balita dan informasi orang tua dengan benar.',
                icon: Icons.child_care_rounded,
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
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  CityAutocompleteField(
                    controller: _tempatLahirCtrl,
                    labelText: AppStrings.tempatLahir,
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
                  // Selector otomatis: gabungan akun terdaftar + riwayat balita
                  Consumer<BalitaKaderProvider>(
                    builder: (_, p, __) {
                      // Gabung akun Supabase + riwayat dari balita (hindari duplikat)
                      final combined = <_OrtuPilihan>[
                        ...p.daftarOrtu.map(
                          (o) => _OrtuPilihan(
                            parentId: o.id,
                            nama: o.nama,
                            noHp: o.noHp,
                            alamat: o.alamat,
                            dariAkun: true,
                          ),
                        ),
                        ...p.ortuRiwayat
                            .where(
                              (r) => !p.daftarOrtu.any(
                                (o) =>
                                    o.nama.toLowerCase() ==
                                    (r['nama'] ?? '').toLowerCase(),
                              ),
                            )
                            .map(
                              (r) => _OrtuPilihan(
                                nama: r['nama']!,
                                noHp: r['no_hp'],
                                alamat: r['alamat'],
                              ),
                            ),
                      ];

                      Widget selectorWidget;

                      if (p.isLoadingOrtu) {
                        selectorWidget = const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Memuat data orang tua...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (combined.isEmpty) {
                        selectorWidget = const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Belum ada data orang tua tersimpan. Isi manual di bawah.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        selectorWidget = DropdownButtonFormField<_OrtuPilihan>(
                          key: ValueKey(_ortuDipilih?.nama),
                          initialValue: _ortuDipilih,
                          decoration: InputDecoration(
                            labelText: 'Pilih Orang Tua (Opsional)',
                            prefixIcon: const Icon(
                              Icons.people_outline_rounded,
                            ),
                            suffixIcon: _ortuDipilih != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    tooltip: 'Reset pilihan',
                                    onPressed: _resetOrtu,
                                  )
                                : null,
                          ),
                          items: [
                            const DropdownMenuItem<_OrtuPilihan>(
                              value: null,
                              child: Text(
                                '-- Pilih orang tua --',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            ...combined.map(
                              (o) => DropdownMenuItem(
                                value: o,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        o.nama,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (o.dariAkun)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(
                                          Icons.verified_user_rounded,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          onChanged: (pilihan) {
                            if (pilihan != null) {
                              _terapkanPilihan(pilihan);
                            } else {
                              _resetOrtu();
                            }
                          },
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          selectorWidget,
                          if (_ortuDipilih != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _ortuDipilih!.dariAkun
                                  ? 'Data dari akun terdaftar. Bisa diedit jika perlu.'
                                  : 'Data dari riwayat pendaftaran. Bisa diedit jika perlu.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary.withValues(alpha: 0.8),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
                  if (_ortuDipilih != null && !_editOrtuManual) ...[
                    // Info card read-only saat orang tua sudah dipilih dari daftar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMint,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.people_outline,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _namaOrtuCtrl.text,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_kontakCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone_outlined,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _kontakCtrl.text,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_alamatCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.home_outlined,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _alamatCtrl.text,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () =>
                                  setState(() => _editOrtuManual = true),
                              icon: const Icon(Icons.edit_outlined, size: 14),
                              label: const Text(
                                'Edit Data',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
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
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? customValidator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: tipe,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        counterText: maxLength != null ? null : '',
      ),
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

/// Model pilihan orang tua — bisa dari akun Supabase atau dari riwayat balita.
class _OrtuPilihan {
  final String? parentId; // hanya ada jika dari akun Supabase
  final String nama;
  final String? noHp;
  final String? alamat;
  final bool dariAkun;

  const _OrtuPilihan({
    this.parentId,
    required this.nama,
    this.noHp,
    this.alamat,
    this.dariAkun = false,
  });
}
