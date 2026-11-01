import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/age_calculator.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../routes/app_routes.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/agenda_imunisasi_provider.dart';
import '../../providers/notifikasi_ortu_provider.dart';
import '../../providers/ortu_balita_provider.dart';
import '../../providers/pertumbuhan_provider.dart';
import '../../providers/riwayat_imunisasi_provider.dart';

class ProfilOrtuScreen extends StatefulWidget {
  const ProfilOrtuScreen({super.key});

  @override
  State<ProfilOrtuScreen> createState() => _ProfilOrtuScreenState();
}

class _ProfilOrtuScreenState extends State<ProfilOrtuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _noHpCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _syncForm();
      final profil = context.read<AuthProvider>().profil;
      if (profil != null) {
        await context.read<OrtuBalitaProvider>().muatByParent(profil.id);
      }
    });
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _noHpCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
  }

  void _syncForm() {
    final profil = context.read<AuthProvider>().profil;
    if (profil == null) return;
    _namaCtrl.text = profil.nama;
    _noHpCtrl.text = profil.noHp ?? '';
    _alamatCtrl.text = profil.alamat ?? '';
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AuthProvider>();
    final berhasil = await provider.updateProfil(
      nama: _namaCtrl.text.trim(),
      noHp: _noHpCtrl.text.trim().isEmpty ? null : _noHpCtrl.text.trim(),
      alamat: _alamatCtrl.text.trim().isEmpty ? null : _alamatCtrl.text.trim(),
    );
    if (!mounted) return;
    if (berhasil) {
      setState(() => _isEdit = false);
      CustomSnackbar.sukses(context, AppStrings.berhasilDiperbarui);
    } else {
      CustomSnackbar.gagal(
        context,
        provider.error ?? AppStrings.gagalMenyimpan,
      );
    }
  }

  Future<void> _logout() async {
    final nav = Navigator.of(context);
    context.read<OrtuBalitaProvider>().reset();
    context.read<PertumbuhanProvider>().reset();
    context.read<AgendaImunisasiProvider>().reset();
    context.read<RiwayatImunisasiProvider>().reset();
    context.read<NotifikasiOrtuProvider>().reset();
    await context.read<AuthProvider>().logout();
    if (mounted) nav.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<AuthProvider, OrtuBalitaProvider>(
        builder: (_, auth, balitaProvider, __) {
          final profil = auth.profil;
          if (profil == null) return const SizedBox.shrink();
          final balita =
              balitaProvider.selected ??
              (balitaProvider.daftar.isNotEmpty
                  ? balitaProvider.daftar.first
                  : null);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => balitaProvider.muatByParent(profil.id),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _ProfileHeader(
                    title: 'Profil Orang Tua',
                    name: profil.nama,
                    subtitle: 'Orang Tua',
                    avatarIcon: Icons.person_rounded,
                  ),
                  Transform.translate(
                    offset: const Offset(0, -22),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Column(
                        children: [
                          if (balita != null)
                            _BalitaSummaryCard(balita: balita)
                          else
                            _EmptyBalitaProfileCard(),
                          const SizedBox(height: 14),
                          _InfoCard(
                            children: [
                              _InfoRow(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: profil.email,
                              ),
                              _InfoRow(
                                icon: Icons.phone_outlined,
                                label: 'Nomor HP',
                                value: profil.noHp?.isNotEmpty == true
                                    ? profil.noHp!
                                    : 'Belum diisi',
                              ),
                              _InfoRow(
                                icon: Icons.location_on_rounded,
                                label: 'Alamat',
                                value: profil.alamat?.isNotEmpty == true
                                    ? profil.alamat!
                                    : 'Belum diisi',
                              ),
                              const _InfoRow(
                                icon: Icons.home_rounded,
                                label: 'Hubungan dengan Anak',
                                value: 'Orang Tua',
                                isLast: true,
                              ),
                            ],
                          ),
                          if (_isEdit) ...[
                            const SizedBox(height: 14),
                            _EditProfileForm(
                              formKey: _formKey,
                              namaCtrl: _namaCtrl,
                              noHpCtrl: _noHpCtrl,
                              alamatCtrl: _alamatCtrl,
                              isLoading: auth.isLoading,
                              onCancel: () {
                                _syncForm();
                                setState(() => _isEdit = false);
                              },
                              onSave: _simpan,
                            ),
                          ],
                          const SizedBox(height: 14),
                          _MenuCard(
                            children: [
                              _MenuRow(
                                icon: Icons.person_rounded,
                                label: 'Edit Profil',
                                color: AppColors.primary,
                                onTap: () => setState(() => _isEdit = true),
                              ),
                              _MenuRow(
                                icon: Icons.lock_rounded,
                                label: 'Ubah Password',
                                color: AppColors.success,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.gantiPassword,
                                ),
                              ),
                              _MenuRow(
                                icon: Icons.notifications_rounded,
                                label: 'Pengaturan Notifikasi',
                                color: AppColors.warning,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.pengaturanNotifikasi,
                                ),
                              ),
                              _MenuRow(
                                icon: Icons.help_rounded,
                                label: 'Bantuan',
                                color: AppColors.primary,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.pusatBantuan,
                                ),
                              ),
                              _MenuRow(
                                icon: Icons.privacy_tip_rounded,
                                label: 'Kebijakan Privasi',
                                color: const Color(0xFF7E57C2),
                                isLast: true,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.kebijakanPrivasi,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _LogoutCard(onTap: _logout),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String title;
  final String name;
  final String subtitle;
  final IconData avatarIcon;

  const _ProfileHeader({
    required this.title,
    required this.name,
    required this.subtitle,
    required this.avatarIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 42),
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
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(avatarIcon, color: AppColors.primary, size: 48),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalitaSummaryCard extends StatelessWidget {
  final dynamic balita;

  const _BalitaSummaryCard({required this.balita});

  @override
  Widget build(BuildContext context) {
    final isPerempuan = balita.jenisKelamin == 'Perempuan';
    final isActive = balita.statusVerifikasi == 'disetujui';
    final usia = AgeCalculator.formatUsiaDetail(balita.tanggalLahir);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, AppRoutes.pertumbuhan),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isPerempuan
                      ? const Color(0xFFFFE4EE)
                      : AppColors.surfaceTeal,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPerempuan ? Icons.girl_rounded : Icons.boy_rounded,
                  color: isPerempuan
                      ? const Color(0xFFE91E8C)
                      : AppColors.primary,
                  size: 38,
                ),
              ),
              const SizedBox(width: 12),
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
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
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
                          isPerempuan
                              ? Icons.female_rounded
                              : Icons.male_rounded,
                          color: AppColors.primary,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            balita.jenisKelamin,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _StatusPill(
                label: isActive ? 'Aktif' : 'Pending',
                color: isActive ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBalitaProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.child_care_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Belum ada balita terdaftar',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.registrasiBalita),
              child: const Text('Daftar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textDisabled,
                size: 20,
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 48, endIndent: 14),
      ],
    );
  }
}

class _EditProfileForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController namaCtrl;
  final TextEditingController noHpCtrl;
  final TextEditingController alamatCtrl;
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _EditProfileForm({
    required this.formKey,
    required this.namaCtrl,
    required this.noHpCtrl,
    required this.alamatCtrl,
    required this.isLoading,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: namaCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.nama,
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppStrings.fieldWajibDiisi
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noHpCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: AppStrings.noHp,
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: alamatCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: AppStrings.alamat,
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      child: const Text(AppStrings.batal),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onSave,
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(AppStrings.simpan),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;

  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          minLeadingWidth: 24,
          leading: Icon(icon, color: color, size: 24),
          title: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
          onTap: onTap,
        ),
        if (!isLast) const Divider(height: 1, indent: 54),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 5),
          Icon(Icons.check_circle_rounded, color: color, size: 15),
        ],
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.logout_rounded, color: AppColors.error),
        title: const Text(
          'Keluar',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
