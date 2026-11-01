import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../data/models/jadwal_posyandu_model.dart';
import '../../providers/jadwal_posyandu_provider.dart';

class TambahJadwalScreen extends StatefulWidget {
  const TambahJadwalScreen({super.key});

  @override
  State<TambahJadwalScreen> createState() => _TambahJadwalScreenState();
}

class _TambahJadwalScreenState extends State<TambahJadwalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final _lokasiCtrl = TextEditingController();

  DateTime? _tanggal;
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;

  @override
  void dispose() {
    _judulCtrl.dispose();
    _deskripsiCtrl.dispose();
    _lokasiCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _pilihJam(bool isMulai) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isMulai) {
          _jamMulai = picked;
        } else {
          _jamSelesai = picked;
        }
      });
    }
  }

  String _formatJam(TimeOfDay? jam) {
    if (jam == null) return 'Pilih jam';
    final h = jam.hour.toString().padLeft(2, '0');
    final m = jam.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tanggal == null) {
      CustomSnackbar.gagal(context, 'Tanggal wajib diisi');
      return;
    }

    final provider = context.read<JadwalPosyanduProvider>();
    final jadwal = JadwalPosyanduModel(
      id: '',
      judul: _judulCtrl.text.trim(),
      deskripsi: _deskripsiCtrl.text.trim().isEmpty
          ? null
          : _deskripsiCtrl.text.trim(),
      tanggal: _tanggal!,
      jamMulai: _jamMulai != null ? _formatJam(_jamMulai) : null,
      jamSelesai: _jamSelesai != null ? _formatJam(_jamSelesai) : null,
      lokasi: _lokasiCtrl.text.trim().isEmpty ? null : _lokasiCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    final berhasil = await provider.tambah(jadwal);
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
      appBar: GradientAppBar(title: AppStrings.tambahJadwal),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const KaderHeroPanel(
                title: 'Tambah Jadwal',
                subtitle:
                    'Buat jadwal kegiatan posyandu baru untuk masyarakat.',
                icon: Icons.event_note_rounded,
              ),
              const SizedBox(height: 16),
              const SectionTitle(title: 'Informasi Kegiatan'),
              const SizedBox(height: 10),
              _FormSection(
                children: [
                  TextFormField(
                    controller: _judulCtrl,
                    decoration: const InputDecoration(
                      labelText: AppStrings.judulKegiatan,
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? AppStrings.fieldWajibDiisi
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _deskripsiCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: AppStrings.deskripsi,
                      hintText: 'Keterangan kegiatan (opsional)',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const SectionTitle(title: 'Waktu & Lokasi'),
              const SizedBox(height: 10),
              _FormSection(
                children: [
                  InkWell(
                    onTap: _pilihTanggal,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: AppStrings.tanggal,
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      child: Text(
                        _tanggal != null
                            ? DateFormat(
                                'dd MMMM yyyy',
                                'id_ID',
                              ).format(_tanggal!)
                            : 'Pilih tanggal',
                        style: TextStyle(
                          color: _tanggal != null
                              ? AppColors.textPrimary
                              : AppColors.textDisabled,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pilihJam(true),
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: AppStrings.jamMulai,
                              prefixIcon: Icon(Icons.access_time_rounded),
                            ),
                            child: Text(
                              _formatJam(_jamMulai),
                              style: TextStyle(
                                color: _jamMulai != null
                                    ? AppColors.textPrimary
                                    : AppColors.textDisabled,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pilihJam(false),
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: AppStrings.jamSelesai,
                              prefixIcon: Icon(
                                Icons.access_time_filled_rounded,
                              ),
                            ),
                            child: Text(
                              _formatJam(_jamSelesai),
                              style: TextStyle(
                                color: _jamSelesai != null
                                    ? AppColors.textPrimary
                                    : AppColors.textDisabled,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lokasiCtrl,
                    decoration: const InputDecoration(
                      labelText: AppStrings.lokasi,
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Consumer<JadwalPosyanduProvider>(
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
