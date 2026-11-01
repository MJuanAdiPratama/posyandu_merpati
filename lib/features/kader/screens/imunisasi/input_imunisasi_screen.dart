import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/age_calculator.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/balita_model.dart';
import '../../../../data/models/jadwal_imunisasi_model.dart';
import '../../../../data/models/jenis_imunisasi_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/balita_kader_provider.dart';
import '../../providers/imunisasi_provider.dart';
import '../../providers/jadwal_imunisasi_kader_provider.dart';
import '../../providers/jenis_imunisasi_provider.dart';

class InputImunisasiScreen extends StatefulWidget {
  final bool standalone;
  final JadwalImunisasiModel? jadwalAktif;
  const InputImunisasiScreen({
    super.key,
    this.standalone = true,
    this.jadwalAktif,
  });

  @override
  State<InputImunisasiScreen> createState() => _InputImunisasiScreenState();
}

class _InputImunisasiScreenState extends State<InputImunisasiScreen> {
  static const double _suhuMaksimalNormal = 37.5;

  final _formKey = GlobalKey<FormState>();
  final _bbCtrl = TextEditingController();
  final _tbCtrl = TextEditingController();
  final _suhuCtrl = TextEditingController();
  final _lkCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  final _petugasCtrl = TextEditingController();

  BalitaModel? _balitaSelected;
  JadwalImunisasiModel? _selectedJadwal;
  DateTime _tanggalImunisasi = DateTime.now();
  int _usiaBulan = 0;

  bool get _dariJadwal => widget.jadwalAktif != null;

  String? get _jenisImunisasiId => _dariJadwal
      ? widget.jadwalAktif?.jenisImunisasiId
      : _selectedJadwal?.jenisImunisasiId;

  String? get _jadwalId =>
      _dariJadwal ? widget.jadwalAktif?.id : _selectedJadwal?.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final balitaProvider = context.read<BalitaKaderProvider>();
      final jenisProvider = context.read<JenisImunisasiProvider>();
      final auth = context.read<AuthProvider>();

      _petugasCtrl.text = auth.profil?.nama ?? '';

      await Future.wait([
        balitaProvider.muatDaftar(),
        jenisProvider.muatDaftar(),
      ]);

      if (!mounted) return;

      final jadwal = widget.jadwalAktif;
      if (jadwal != null) {
        final balita = balitaProvider.daftar.where(
          (b) => b.id == jadwal.balitaId && b.statusVerifikasi == 'disetujui',
        );
        if (balita.isNotEmpty) {
          setState(() {
            _balitaSelected = balita.first;
            _hitungUsia();
          });
        }
        return;
      }

      final selected = balitaProvider.selected;
      final selectedTerverifikasi =
          selected != null &&
          selected.statusVerifikasi == 'disetujui' &&
          balitaProvider.daftar.any((b) => b.id == selected.id);

      if (selectedTerverifikasi) {
        final balita = balitaProvider.daftar.firstWhere(
          (b) => b.id == selected.id,
        );
        setState(() {
          _balitaSelected = balita;
          _hitungUsia();
        });
        if (mounted) {
          await Future.wait([
            context.read<JadwalImunisasiKaderProvider>().muatTersediaByBalita(
              balita.id,
            ),
            context.read<ImunisasiProvider>().muatSudahDiberikan(balita.id),
          ]);
        }
      }
    });
  }

  @override
  void dispose() {
    _bbCtrl.dispose();
    _tbCtrl.dispose();
    _suhuCtrl.dispose();
    _lkCtrl.dispose();
    _catatanCtrl.dispose();
    _petugasCtrl.dispose();
    super.dispose();
  }

  void _hitungUsia() {
    if (_balitaSelected != null) {
      _usiaBulan = AgeCalculator.hitungUsiaBulan(
        _balitaSelected!.tanggalLahir,
        _tanggalImunisasi,
      );
    }
  }

  void _resetForm() {
    setState(() {
      _balitaSelected = null;
      _selectedJadwal = null;
      _tanggalImunisasi = DateTime.now();
      _usiaBulan = 0;
    });
    _bbCtrl.clear();
    _tbCtrl.clear();
    _suhuCtrl.clear();
    _lkCtrl.clear();
    _catatanCtrl.clear();
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalImunisasi,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() {
        _tanggalImunisasi = picked;
        _hitungUsia();
      });
    }
  }

  Future<void> _tambahJadwalBaru() async {
    if (_balitaSelected == null) {
      CustomSnackbar.gagal(context, 'Pilih balita terlebih dahulu');
      return;
    }
    final jenisProvider = context.read<JenisImunisasiProvider>();
    final jadwalProvider = context.read<JadwalImunisasiKaderProvider>();
    final imunisasiProvider = context.read<ImunisasiProvider>();
    final excludedIds = {
      ...jadwalProvider.jenisIdsTersedia,
      ...imunisasiProvider.sudahDiberikan,
    };
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _TambahJadwalDialog(
        jenisList: jenisProvider.daftar,
        excludedJenisIds: excludedIds,
      ),
    );
    if (result == null || !mounted) return;

    final newJadwal = await jadwalProvider.tambahJadwalCepat(
      _balitaSelected!.id,
      result['jenisImunisasiId'] as String,
      result['tanggal'] as DateTime,
    );
    if (!mounted) return;
    if (newJadwal != null) {
      setState(() => _selectedJadwal = newJadwal);
      CustomSnackbar.sukses(context, 'Jadwal ditambahkan dan dipilih');
    } else {
      CustomSnackbar.gagal(
        context,
        jadwalProvider.error ?? 'Gagal menambah jadwal',
      );
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_balitaSelected == null) {
      CustomSnackbar.gagal(context, 'Pilih balita terlebih dahulu');
      return;
    }
    if (_balitaSelected!.statusVerifikasi != 'disetujui') {
      CustomSnackbar.gagal(
        context,
        'Balita belum diverifikasi. Verifikasi data balita terlebih dahulu.',
      );
      return;
    }
    if (!_dariJadwal && _selectedJadwal == null) {
      CustomSnackbar.gagal(context, 'Pilih jadwal imunisasi terlebih dahulu');
      return;
    }

    final suhu = _suhuCtrl.text.isNotEmpty
        ? double.tryParse(_suhuCtrl.text)
        : null;
    if (suhu != null && suhu > _suhuMaksimalNormal) {
      await _tanganiSuhuTidakNormal(suhu);
      return;
    }

    final provider = context.read<ImunisasiProvider>();
    final berhasil = await provider.simpanImunisasi(
      balita: _balitaSelected!,
      jenisImunisasiId: _jenisImunisasiId,
      tanggalImunisasi: _tanggalImunisasi,
      beratBadan: _bbCtrl.text.isNotEmpty
          ? double.tryParse(_bbCtrl.text)
          : null,
      tinggiBadan: _tbCtrl.text.isNotEmpty
          ? double.tryParse(_tbCtrl.text)
          : null,
      suhuBadan: _suhuCtrl.text.isNotEmpty
          ? double.tryParse(_suhuCtrl.text)
          : null,
      lingkarKepala: _lkCtrl.text.isNotEmpty
          ? double.tryParse(_lkCtrl.text)
          : null,
      catatan: _catatanCtrl.text.trim(),
      jadwalId: _jadwalId,
    );
    if (!mounted) return;
    if (berhasil) {
      CustomSnackbar.sukses(context, 'Imunisasi berhasil dicatat');
      if (widget.standalone) {
        Navigator.pop(context, true);
      } else {
        _resetForm();
      }
    } else {
      CustomSnackbar.gagal(
        context,
        provider.error ?? AppStrings.gagalMenyimpan,
      );
    }
  }

  Future<void> _tanganiSuhuTidakNormal(double suhu) async {
    final tanggalBaru = await showDialog<DateTime>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SuhuTidakNormalDialog(suhu: suhu),
    );
    if (tanggalBaru == null || !mounted) return;

    final jadwalId = _jadwalId;
    if (jadwalId == null) {
      CustomSnackbar.gagal(
        context,
        'Jadwal imunisasi tidak ditemukan untuk dijadwalkan ulang',
      );
      return;
    }

    final jadwalProvider = context.read<JadwalImunisasiKaderProvider>();
    final berhasil = await jadwalProvider.ubahTanggal(jadwalId, tanggalBaru);
    if (!mounted) return;
    if (berhasil) {
      CustomSnackbar.sukses(
        context,
        'Suhu badan tidak normal. Imunisasi dijadwalkan ulang ke '
        '${DateFormat('dd MMMM yyyy', 'id_ID').format(tanggalBaru)}',
      );
      if (widget.standalone) {
        Navigator.pop(context, true);
      } else {
        _resetForm();
      }
    } else {
      CustomSnackbar.gagal(
        context,
        jadwalProvider.error ?? 'Gagal menjadwalkan ulang imunisasi',
      );
    }
  }

  Widget _buildFormContent(
    BuildContext context,
    BalitaKaderProvider balitaProvider,
    JenisImunisasiProvider jenisProvider,
    ImunisasiProvider imunisasiProvider,
    JadwalImunisasiKaderProvider jadwalProvider,
    DateFormat df,
  ) {
    final balitaTerverifikasi = balitaProvider.daftar
        .where((b) => b.statusVerifikasi == 'disetujui')
        .toList();
    final selectedId =
        balitaTerverifikasi.any((b) => b.id == _balitaSelected?.id)
        ? _balitaSelected?.id
        : null;

    final namaImunisasiAktif = _dariJadwal
        ? (jenisProvider.daftar
                  .where((m) => m.id == widget.jadwalAktif?.jenisImunisasiId)
                  .firstOrNull
                  ?.namaImunisasi ??
              widget.jadwalAktif?.namaImunisasi ??
              '-')
        : null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InputCard(
            children: [
              if (_dariJadwal) ...[
                _ReadOnlyField(
                  label: 'Balita',
                  value: _balitaSelected?.nama ?? '-',
                ),
              ] else ...[
                DropdownButtonFormField<String>(
                  initialValue: selectedId,
                  decoration: const InputDecoration(labelText: 'Balita'),
                  items: balitaTerverifikasi
                      .map(
                        (b) =>
                            DropdownMenuItem(value: b.id, child: Text(b.nama)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    final balita = balitaTerverifikasi.firstWhere(
                      (b) => b.id == v,
                    );
                    setState(() {
                      _balitaSelected = balita;
                      _selectedJadwal = null;
                      _hitungUsia();
                    });
                    context
                        .read<JadwalImunisasiKaderProvider>()
                        .muatTersediaByBalita(balita.id);
                    context.read<ImunisasiProvider>().muatSudahDiberikan(
                      balita.id,
                    );
                  },
                  validator: (v) =>
                      v == null ? AppStrings.fieldWajibDiisi : null,
                ),
                if (balitaTerverifikasi.isEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const InfoTextRow(
                      icon: Icons.verified_user_outlined,
                      text:
                          'Belum ada balita terverifikasi. Verifikasi data balita sebelum mencatat imunisasi.',
                    ),
                  ),
                ],
              ],
              if (_balitaSelected != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InfoTextRow(
                    icon: Icons.eco_rounded,
                    text:
                        'Usia dihitung otomatis berdasarkan tanggal lahir: ${AgeCalculator.formatUsia(_usiaBulan)}',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          _InputCard(
            children: [
              if (_dariJadwal) ...[
                _ReadOnlyField(
                  label: AppStrings.jenisImunisasi,
                  value: namaImunisasiAktif ?? '-',
                ),
                const SizedBox(height: 8),
                _ReadOnlyField(
                  label: 'Jadwal Berikutnya',
                  value: df.format(widget.jadwalAktif!.tanggalJadwal),
                ),
              ] else ...[
                _buildJadwalPicker(jadwalProvider, df),
              ],
            ],
          ),
          const SizedBox(height: 12),

          _InputCard(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bbCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Berat Badan (kg)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _tbCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Tinggi Badan (cm)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _suhuCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Suhu Badan (°C)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lkCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Lingkar Kepala (cm)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.18),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.health_and_safety_outlined,
                      size: 16,
                      color: AppColors.info,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Syarat vaksinasi: suhu badan normal (maksimal 37,5°C) '
                        'dan balita dalam kondisi sehat, tidak sedang demam '
                        'atau sakit berat.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _InputCard(
            children: [
              InkWell(
                onTap: _pilihTanggal,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: AppStrings.tanggalImunisasi,
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(df.format(_tanggalImunisasi)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _InputCard(
            children: [
              TextFormField(
                controller: _catatanCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: AppStrings.catatan,
                  hintText: 'Contoh: Toleransi baik, tidak ada keluhan',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _petugasCtrl,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Petugas'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppStrings.fieldWajibDiisi
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Tombol Simpan ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: imunisasiProvider.isLoading ? null : _simpan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: imunisasiProvider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Simpan Imunisasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalPicker(
    JadwalImunisasiKaderProvider jadwalProvider,
    DateFormat df,
  ) {
    if (_balitaSelected == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: const [
            Icon(
              Icons.event_available_outlined,
              size: 18,
              color: AppColors.textDisabled,
            ),
            SizedBox(width: 10),
            Text(
              'Pilih balita terlebih dahulu',
              style: TextStyle(color: AppColors.textDisabled, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (jadwalProvider.isLoadingTersedia) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final tersedia = jadwalProvider.jadwalBisaInput;

    if (tersedia.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceMint,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(
                  Icons.event_busy_outlined,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Tidak ada jadwal imunisasi yang tersedia. Tambah jadwal baru untuk melanjutkan.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Tambah Jadwal'),
            onPressed: _tambahJadwalBaru,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      );
    }

    final currentValid = tersedia.any((j) => j.id == _selectedJadwal?.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(_balitaSelected?.id),
          initialValue: currentValid ? _selectedJadwal?.id : null,
          decoration: const InputDecoration(
            labelText: 'Pilih Jadwal Imunisasi',
            prefixIcon: Icon(Icons.event_available_outlined),
          ),
          isExpanded: true,
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('-- Pilih Jadwal --'),
            ),
            ...tersedia.map((j) {
              final label = j.namaImunisasi ?? 'Imunisasi';
              final tgl = DateFormat(
                'dd MMM yyyy',
                'id_ID',
              ).format(j.tanggalJadwal);
              final terlambat = j.status == 'terlambat';
              return DropdownMenuItem(
                value: j.id,
                child: Text(
                  '${terlambat ? '⚠ ' : ''}$label – $tgl',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: terlambat ? AppColors.error : null),
                ),
              );
            }),
          ],
          onChanged: (v) {
            if (v == null) {
              setState(() => _selectedJadwal = null);
              return;
            }
            final jadwal = tersedia.firstWhere((j) => j.id == v);
            setState(() => _selectedJadwal = jadwal);
          },
          validator: (_) =>
              _selectedJadwal == null ? 'Pilih jadwal imunisasi' : null,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Tambah Jadwal', style: TextStyle(fontSize: 12)),
            onPressed: _tambahJadwalBaru,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final balitaProvider = context.watch<BalitaKaderProvider>();
    final jenisProvider = context.watch<JenisImunisasiProvider>();
    final imunisasiProvider = context.watch<ImunisasiProvider>();
    final jadwalProvider = context.watch<JadwalImunisasiKaderProvider>();
    final df = DateFormat('dd MMMM yyyy', 'id_ID');

    if (balitaProvider.isLoading || jenisProvider.isLoading) {
      return widget.standalone
          ? const Scaffold(body: LoadingWidget())
          : const LoadingWidget();
    }

    final formContent = _buildFormContent(
      context,
      balitaProvider,
      jenisProvider,
      imunisasiProvider,
      jadwalProvider,
      df,
    );

    final content = Column(
      children: [
        _InputHeader(showBack: widget.standalone),
        Transform.translate(
          offset: const Offset(0, -22),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              children: [
                if (_balitaSelected != null)
                  _SelectedBalitaCard(balita: _balitaSelected!)
                else
                  const _SelectBalitaHintCard(),
                const SizedBox(height: 12),
                formContent,
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const InfoTextRow(
                    icon: Icons.info_outline_rounded,
                    text:
                        'Jika berat badan, tinggi badan, dan lingkar kepala diisi, data pertumbuhan akan diperbarui otomatis.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (!widget.standalone) {
      return SingleChildScrollView(child: content);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(child: content),
    );
  }
}

class _InputHeader extends StatelessWidget {
  final bool showBack;

  const _InputHeader({required this.showBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 42),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00B7B0), AppColors.primary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showBack)
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            else
              const SizedBox(width: 48),
            const Expanded(
              child: Text(
                'Input Imunisasi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedBalitaCard extends StatelessWidget {
  final BalitaModel balita;

  const _SelectedBalitaCard({required this.balita});

  @override
  Widget build(BuildContext context) {
    final isBoy = balita.jenisKelamin == 'Laki-laki';
    final usia = AgeCalculator.formatUsiaDetail(balita.tanggalLahir);
    final tanggal = DateFormat(
      'dd MMMM yyyy',
      'id_ID',
    ).format(balita.tanggalLahir);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: isBoy
                  ? AppColors.surfaceTeal
                  : const Color(0xFFFFE4EE),
              child: Icon(
                isBoy ? Icons.boy_rounded : Icons.girl_rounded,
                color: isBoy ? AppColors.primary : const Color(0xFFE91E8C),
                size: 42,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    balita.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Usia $usia',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        isBoy ? Icons.male_rounded : Icons.female_rounded,
                        color: isBoy ? AppColors.info : AppColors.error,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        balita.jenisKelamin,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Tanggal Lahir : $tanggal',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
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

class _SelectBalitaHintCard extends StatelessWidget {
  const _SelectBalitaHintCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: InfoTextRow(
          icon: Icons.child_care_rounded,
          text: 'Pilih balita untuk mulai mencatat imunisasi.',
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final List<Widget> children;

  const _InputCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

class _SuhuTidakNormalDialog extends StatefulWidget {
  final double suhu;

  const _SuhuTidakNormalDialog({required this.suhu});

  @override
  State<_SuhuTidakNormalDialog> createState() =>
      _SuhuTidakNormalDialogState();
}

class _SuhuTidakNormalDialogState extends State<_SuhuTidakNormalDialog> {
  DateTime _tanggalBaru = DateTime.now().add(const Duration(days: 1));

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalBaru,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) setState(() => _tanggalBaru = picked);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMMM yyyy', 'id_ID');
    return AlertDialog(
      icon: const Icon(
        Icons.thermostat_rounded,
        color: AppColors.error,
        size: 36,
      ),
      title: const Text('Suhu Badan Tidak Normal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suhu badan balita ${widget.suhu}°C menunjukkan demam '
            '(di atas 37.5°C). Imunisasi tidak dapat dilakukan hari ini '
            'dan harus dijadwalkan ulang ke hari lain.',
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pilihTanggal,
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Jadwalkan Ulang ke Tanggal',
                prefixIcon: Icon(Icons.event_repeat_outlined),
              ),
              child: Text(df.format(_tanggalBaru)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _tanggalBaru),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Jadwalkan Ulang'),
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _TambahJadwalDialog extends StatefulWidget {
  final List<JenisImunisasiModel> jenisList;
  final Set<String> excludedJenisIds;
  const _TambahJadwalDialog({
    required this.jenisList,
    required this.excludedJenisIds,
  });

  @override
  State<_TambahJadwalDialog> createState() => _TambahJadwalDialogState();
}

class _TambahJadwalDialogState extends State<_TambahJadwalDialog> {
  DateTime _tanggal = DateTime.now();
  String? _jenisImunisasiId;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMMM yyyy', 'id_ID');
    final available = widget.jenisList
        .where((m) => !widget.excludedJenisIds.contains(m.id))
        .toList();
    return AlertDialog(
      title: const Text('Tambah Jadwal Imunisasi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _tanggal,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                locale: const Locale('id', 'ID'),
              );
              if (picked != null) setState(() => _tanggal = picked);
            },
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Tanggal Jadwal',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(df.format(_tanggal)),
            ),
          ),
          const SizedBox(height: 12),
          if (available.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceMint,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppColors.success,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Semua vaksin sudah dijadwalkan untuk balita ini.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _jenisImunisasiId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Jenis Imunisasi',
                prefixIcon: Icon(Icons.vaccines),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('-- Pilih Imunisasi --'),
                ),
                ...available.map(
                  (m) => DropdownMenuItem(
                    value: m.id,
                    child: Text(
                      '${m.namaImunisasi} (${m.usiaBulan} bln)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _jenisImunisasiId = v),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _jenisImunisasiId == null
              ? null
              : () => Navigator.pop(context, {
                  'tanggal': _tanggal,
                  'jenisImunisasiId': _jenisImunisasiId!,
                }),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}
