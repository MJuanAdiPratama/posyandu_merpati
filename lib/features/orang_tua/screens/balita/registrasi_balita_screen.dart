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
import '../../../auth/providers/auth_provider.dart';
import '../../providers/agenda_imunisasi_provider.dart';
import '../../providers/ortu_balita_provider.dart';
import '../../providers/pertumbuhan_provider.dart';
import '../../providers/riwayat_imunisasi_provider.dart';

class RegistrasiBalitaScreen extends StatefulWidget {
  const RegistrasiBalitaScreen({super.key});

  @override
  State<RegistrasiBalitaScreen> createState() => _RegistrasiBalitaScreenState();
}

class _RegistrasiBalitaScreenState extends State<RegistrasiBalitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nikCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _tempatLahirCtrl = TextEditingController();
  final _namaOrtuCtrl = TextEditingController();
  final _kontakCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();

  DateTime? _tanggalLahir;
  String _jenisKelamin = 'Laki-laki';
  bool _editOrtuManual = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profil = context.read<AuthProvider>().profil;
      if (profil != null) {
        _namaOrtuCtrl.text = profil.nama;
        _kontakCtrl.text = profil.noHp ?? '';
        _alamatCtrl.text = profil.alamat ?? '';
      }
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

  Future<void> _daftar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tanggalLahir == null) {
      CustomSnackbar.gagal(context, 'Tanggal lahir wajib diisi');
      return;
    }

    final auth = context.read<AuthProvider>();
    final profil = auth.profil;
    if (profil == null) {
      CustomSnackbar.gagal(context, 'Sesi login tidak ditemukan');
      return;
    }
    final provider = context.read<OrtuBalitaProvider>();

    final balita = BalitaModel(
      id: '',
      parentId: profil.id,
      nik: _nikCtrl.text.trim(),
      nama: _namaCtrl.text.trim(),
      tempatLahir: _tempatLahirCtrl.text.trim(),
      tanggalLahir: _tanggalLahir!,
      jenisKelamin: _jenisKelamin,
      namaOrtu: _namaOrtuCtrl.text.trim().isEmpty
          ? profil.nama
          : _namaOrtuCtrl.text.trim(),
      kontakOrtu: _kontakCtrl.text.trim(),
      alamat: _alamatCtrl.text.trim(),
      statusVerifikasi: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final berhasil = await provider.daftarBalita(balita);
    if (!mounted) return;
    if (berhasil) {
      final balitaBaru = provider.selected;
      if (balitaBaru != null) {
        await Future.wait([
          context.read<PertumbuhanProvider>().muatByBalita(balitaBaru.id),
          context.read<AgendaImunisasiProvider>().muatByBalita(balitaBaru.id),
          context.read<RiwayatImunisasiProvider>().muatByBalita(balitaBaru.id),
        ]);
        if (!mounted) return;
      }
      CustomSnackbar.sukses(
        context,
        'Balita berhasil didaftarkan. Menunggu verifikasi kader.',
      );
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
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientPageHeader(
            title: 'Registrasi Balita',
            subtitle: 'Lengkapi data balita untuk diverifikasi kader.',
            icon: Icons.child_care_rounded,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -18),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: AppColors.surfaceMint,
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Row(
                          children: [
                            IconBadge(icon: Icons.verified_outlined),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pendaftaran balita',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Data akan diverifikasi kader sebelum aktif di aplikasi.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(
                              label: 'Pending',
                              color: AppColors.warning,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SectionTitle(title: 'Data Balita'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _field(
                                _nikCtrl,
                                AppStrings.nikBalita,
                                Icons.badge_outlined,
                                tipe: TextInputType.number,
                                maxLength: 16,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                customValidator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return AppStrings.fieldWajibDiisi;
                                  }
                                  if (v.length != 16) {
                                    return 'NIK harus 16 digit';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _field(
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
                                    prefixIcon: Icon(
                                      Icons.calendar_today_outlined,
                                    ),
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
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  AppStrings.jenisKelamin,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _genderOption(
                                      'Laki-laki',
                                      Icons.boy,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _genderOption(
                                      'Perempuan',
                                      Icons.girl,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (!_editOrtuManual) ...[
                                // Info card dari profil akun
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMint,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.verified_user_rounded,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Data dari profil akun Anda',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
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
                                              _namaOrtuCtrl.text.isNotEmpty
                                                  ? _namaOrtuCtrl.text
                                                  : '-',
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                  color:
                                                      AppColors.textSecondary,
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
                                          onPressed: () => setState(
                                            () => _editOrtuManual = true,
                                          ),
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 14,
                                          ),
                                          label: const Text(
                                            'Edit Data',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                _field(
                                  _namaOrtuCtrl,
                                  AppStrings.namaOrtu,
                                  Icons.people_outline,
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  _kontakCtrl,
                                  AppStrings.kontakOrtu,
                                  Icons.phone_outlined,
                                  tipe: TextInputType.phone,
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  _alamatCtrl,
                                  AppStrings.alamat,
                                  Icons.home_outlined,
                                  maxLines: 2,
                                ),
                              ],
                              const SizedBox(height: 22),
                              Consumer<OrtuBalitaProvider>(
                                builder: (_, p, __) => ElevatedButton(
                                  onPressed: p.isLoading ? null : _daftar,
                                  child: p.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Simpan Data'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
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

  Widget _genderOption(String value, IconData icon) {
    final selected = _jenisKelamin == value;
    return InkWell(
      onTap: () => setState(() => _jenisKelamin = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceTeal : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? AppColors.primaryDark
                      : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
