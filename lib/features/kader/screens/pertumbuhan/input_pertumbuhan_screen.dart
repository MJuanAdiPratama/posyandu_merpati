import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/age_calculator.dart';
import '../../../../core/utils/growth_status_helper.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/balita_model.dart';
import '../../../../data/models/pertumbuhan_model.dart';
import '../../providers/balita_kader_provider.dart';
import '../../providers/pertumbuhan_kader_provider.dart';

class InputPertumbuhanScreen extends StatefulWidget {
  const InputPertumbuhanScreen({super.key});

  @override
  State<InputPertumbuhanScreen> createState() => _InputPertumbuhanScreenState();
}

class _InputPertumbuhanScreenState extends State<InputPertumbuhanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bbCtrl = TextEditingController();
  final _tbCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();

  DateTime _tanggalPemeriksaan = DateTime.now();

  @override
  void initState() {
    super.initState();
    _bbCtrl.addListener(_refreshStatusPreview);
    _tbCtrl.addListener(_refreshStatusPreview);
  }

  @override
  void dispose() {
    _bbCtrl.removeListener(_refreshStatusPreview);
    _tbCtrl.removeListener(_refreshStatusPreview);
    _bbCtrl.dispose();
    _tbCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  void _refreshStatusPreview() {
    if (mounted) setState(() {});
  }

  double? _parseDecimal(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalPemeriksaan,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() => _tanggalPemeriksaan = picked);
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    final balita = context.read<BalitaKaderProvider>().selected;
    if (balita == null) return;

    final bb = _parseDecimal(_bbCtrl.text)!;
    final tb = _parseDecimal(_tbCtrl.text)!;
    final usiaBulan = AgeCalculator.hitungUsiaBulan(
      balita.tanggalLahir,
      _tanggalPemeriksaan,
    );

    final statusGizi = GrowthStatusHelper.hitungStatusGizi(
      beratBadan: bb,
      tinggiBadan: tb,
      usiaBulan: usiaBulan,
      jenisKelamin: balita.jenisKelamin,
    );
    final statusTB = GrowthStatusHelper.hitungStatusTinggiBadan(
      tinggiBadan: tb,
      usiaBulan: usiaBulan,
      jenisKelamin: balita.jenisKelamin,
    );
    final statusBB = GrowthStatusHelper.hitungStatusBeratBadan(
      beratBadan: bb,
      usiaBulan: usiaBulan,
      jenisKelamin: balita.jenisKelamin,
    );

    final pertumbuhan = PertumbuhanModel(
      id: '',
      balitaId: balita.id,
      tanggalPemeriksaan: _tanggalPemeriksaan,
      usiaBulan: usiaBulan,
      beratBadan: bb,
      tinggiBadan: tb,
      statusGizi: statusGizi,
      statusTinggiBadan: statusTB,
      statusBeratBadan: statusBB,
      catatan: _catatanCtrl.text.trim().isEmpty
          ? null
          : _catatanCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    final berhasil = await context.read<PertumbuhanKaderProvider>().simpan(
      pertumbuhan,
      parentId: balita.parentId,
      namaBalita: balita.nama,
    );

    if (!mounted) return;
    if (berhasil) {
      CustomSnackbar.sukses(context, 'Data pertumbuhan berhasil disimpan');
      Navigator.pop(context, true);
    } else {
      final err = context.read<PertumbuhanKaderProvider>().error;
      CustomSnackbar.gagal(context, err ?? 'Gagal menyimpan data pertumbuhan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final balita = context.watch<BalitaKaderProvider>().selected;
    if (balita == null) {
      return const Scaffold(body: Center(child: Text('Data tidak ditemukan')));
    }

    final usiaBulan = AgeCalculator.hitungUsiaBulan(
      balita.tanggalLahir,
      _tanggalPemeriksaan,
    );
    final isLoading = context.watch<PertumbuhanKaderProvider>().isLoading;
    final bb = _parseDecimal(_bbCtrl.text);
    final tb = _parseDecimal(_tbCtrl.text);
    final status = bb != null && tb != null && bb > 0 && tb > 0
        ? GrowthStatusHelper.hitungStatusGizi(
            beratBadan: bb,
            tinggiBadan: tb,
            usiaBulan: usiaBulan,
            jenisKelamin: balita.jenisKelamin,
          )
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              child: Column(
                children: [
                  const _GrowthHeader(),
                  Transform.translate(
                    offset: const Offset(0, -22),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _BalitaCard(balita: balita),
                            const SizedBox(height: 12),
                            _DataPemeriksaanCard(
                              tanggal: _tanggalPemeriksaan,
                              bbCtrl: _bbCtrl,
                              tbCtrl: _tbCtrl,
                              catatanCtrl: _catatanCtrl,
                              onPilihTanggal: _pilihTanggal,
                            ),
                            const SizedBox(height: 12),
                            _InfoOtomatisCard(
                              jenisKelamin: balita.jenisKelamin,
                              usiaBulan: usiaBulan,
                            ),
                            const SizedBox(height: 12),
                            _StatusGiziCard(status: status),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save_rounded),
                                label: const Text('Simpan Pertumbuhan'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _simpan,
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
    );
  }
}

class _GrowthHeader extends StatelessWidget {
  const _GrowthHeader();

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
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const Expanded(
              child: Text(
                'Input Pertumbuhan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _BalitaCard extends StatelessWidget {
  final BalitaModel balita;

  const _BalitaCard({required this.balita});

  @override
  Widget build(BuildContext context) {
    final isBoy = balita.jenisKelamin == 'Laki-laki';
    final usia = AgeCalculator.formatUsiaDetail(balita.tanggalLahir);

    return _SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: isBoy
                ? AppColors.surfaceTeal
                : const Color(0xFFFFE4EE),
            child: Icon(
              isBoy ? Icons.boy_rounded : Icons.girl_rounded,
              color: isBoy ? AppColors.primary : const Color(0xFFE91E63),
              size: 44,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  balita.nama,
                  style: const TextStyle(
                    color: Color(0xFF111A3A),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Usia $usia',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      isBoy ? Icons.male_rounded : Icons.female_rounded,
                      color: isBoy ? AppColors.info : const Color(0xFFE91E63),
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      balita.jenisKelamin,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceMint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.child_care_rounded,
              color: AppColors.secondary,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}

class _DataPemeriksaanCard extends StatelessWidget {
  final DateTime tanggal;
  final TextEditingController bbCtrl;
  final TextEditingController tbCtrl;
  final TextEditingController catatanCtrl;
  final VoidCallback onPilihTanggal;

  const _DataPemeriksaanCard({
    required this.tanggal,
    required this.bbCtrl,
    required this.tbCtrl,
    required this.catatanCtrl,
    required this.onPilihTanggal,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy', 'id_ID');

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Data Pemeriksaan'),
          const SizedBox(height: 14),
          _FormRow(
            label: 'Tanggal Pemeriksaan',
            child: InkWell(
              onTap: onPilihTanggal,
              borderRadius: BorderRadius.circular(12),
              child: _FieldShell(
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        df.format(tanggal),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FormRow(
            label: 'Berat Badan (kg)',
            child: TextFormField(
              controller: bbCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(
                hint: '10,5',
                icon: Icons.monitor_weight_outlined,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                final val = double.tryParse(v.trim().replaceAll(',', '.'));
                if (val == null || val <= 0) return 'Masukkan angka valid';
                if (val > 50) return 'Berat badan tidak wajar';
                return null;
              },
            ),
          ),
          const SizedBox(height: 12),
          _FormRow(
            label: 'Tinggi Badan (cm)',
            child: TextFormField(
              controller: tbCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(hint: '81,5', icon: Icons.height),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                final val = double.tryParse(v.trim().replaceAll(',', '.'));
                if (val == null || val <= 0) return 'Masukkan angka valid';
                if (val > 200) return 'Tinggi badan tidak wajar';
                return null;
              },
            ),
          ),
          const SizedBox(height: 12),
          _FormRow(
            label: 'Catatan (opsional)',
            child: TextFormField(
              controller: catatanCtrl,
              maxLines: 2,
              decoration: _inputDecoration(
                hint: 'Contoh: Nafsu makan baik, aktif bermain',
                icon: Icons.edit_note_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }
}

class _InfoOtomatisCard extends StatelessWidget {
  final String jenisKelamin;
  final int usiaBulan;

  const _InfoOtomatisCard({
    required this.jenisKelamin,
    required this.usiaBulan,
  });

  @override
  Widget build(BuildContext context) {
    final isBoy = jenisKelamin == 'Laki-laki';

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Informasi Otomatis'),
          const SizedBox(height: 12),
          _InfoRow(
            icon: isBoy ? Icons.male_rounded : Icons.female_rounded,
            iconColor: isBoy ? AppColors.info : const Color(0xFFE91E63),
            label: 'Jenis Kelamin',
            value: jenisKelamin,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.groups_rounded,
            iconColor: AppColors.primary,
            label: 'Usia Bulan (Otomatis)',
            value: '$usiaBulan bulan',
          ),
        ],
      ),
    );
  }
}

class _StatusGiziCard extends StatelessWidget {
  final String? status;

  const _StatusGiziCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = status ?? 'Menunggu Data';
    final color = _statusColor(label);
    final isNormal = label == 'Normal';

    return _SoftCard(
      color: isNormal ? const Color(0xFFEAF9EF) : Colors.white,
      borderColor: color.withValues(alpha: status == null ? 0.12 : 0.24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Status Gizi Otomatis'),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_statusIcon(label), color: color, size: 48),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (status != null)
                          _MiniBadge(
                            label: isNormal ? 'Baik' : 'Perlu Pantau',
                            color: color,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusDescription(label),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Status gizi dihitung otomatis dari data balita dan pemeriksaan.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 136,
          child: Padding(
            padding: const EdgeInsets.only(top: 13),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }
}

class _FieldShell extends StatelessWidget {
  final Widget child;

  const _FieldShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(child: child),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF111A3A),
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;

  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.borderColor = AppColors.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'Normal':
      return AppColors.success;
    case 'Gizi Kurang':
    case 'Risiko Stunting':
      return AppColors.warning;
    case 'Gizi Buruk':
    case 'Stunting':
      return AppColors.error;
    case 'Risiko Gizi Lebih':
    case 'Gizi Lebih':
    case 'Obesitas':
      return Colors.deepOrange;
    default:
      return AppColors.textSecondary;
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'Normal':
      return Icons.sentiment_satisfied_alt_rounded;
    case 'Menunggu Data':
      return Icons.help_outline_rounded;
    default:
      return Icons.warning_amber_rounded;
  }
}

String _statusDescription(String status) {
  switch (status) {
    case 'Normal':
      return 'Berat badan dan tinggi badan sesuai untuk usia';
    case 'Menunggu Data':
      return 'Isi berat dan tinggi badan untuk melihat hasil';
    default:
      return 'Perlu dipantau dan dievaluasi pada pemeriksaan berikutnya';
  }
}
