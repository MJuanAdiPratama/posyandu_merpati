import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../routes/app_routes.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/balita_kader_provider.dart';
import '../../providers/dashboard_kader_provider.dart';
import '../../providers/jadwal_posyandu_provider.dart';

class ProfilKaderScreen extends StatefulWidget {
  final bool standalone;

  const ProfilKaderScreen({super.key, this.standalone = true});

  @override
  State<ProfilKaderScreen> createState() => _ProfilKaderScreenState();
}

class _ProfilKaderScreenState extends State<ProfilKaderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _noHpCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncForm();
      context.read<DashboardKaderProvider>().muatDashboard();
      context.read<BalitaKaderProvider>().muatDaftar();
      context.read<JadwalPosyanduProvider>().muatDaftar();
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
    context.read<JadwalPosyanduProvider>().unsubscribe();
    await context.read<AuthProvider>().logout();
    if (mounted) nav.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final content =
        Consumer3<AuthProvider, DashboardKaderProvider, JadwalPosyanduProvider>(
          builder: (_, auth, dashboard, jadwalProvider, __) {
            final profil = auth.profil;
            if (profil == null) return const SizedBox.shrink();

            final jadwalAktif = jadwalProvider.daftar.where((j) {
              final today = DateTime.now();
              final d = DateTime(
                j.tanggal.year,
                j.tanggal.month,
                j.tanggal.day,
              );
              final t = DateTime(today.year, today.month, today.day);
              return !d.isBefore(t);
            }).length;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await Future.wait([
                  context.read<DashboardKaderProvider>().muatDashboard(),
                  context.read<BalitaKaderProvider>().muatDaftar(),
                  context.read<JadwalPosyanduProvider>().muatDaftar(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _ProfileHeader(
                      title: 'Profil Kader',
                      name: profil.nama,
                      subtitle: 'Kader Posyandu Merpati',
                      avatarIcon: Icons.support_agent_rounded,
                    ),
                    Transform.translate(
                      offset: const Offset(0, -22),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Column(
                          children: [
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
                                const _InfoRow(
                                  icon: Icons.location_on_rounded,
                                  label: 'Wilayah Tugas / Posyandu',
                                  value: 'Posyandu Merpati',
                                ),
                                _InfoRow(
                                  icon: Icons.home_rounded,
                                  label: 'Alamat',
                                  value: profil.alamat?.isNotEmpty == true
                                      ? profil.alamat!
                                      : 'Belum diisi',
                                  isLast: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _ProfileStatCard(
                                  icon: Icons.groups_rounded,
                                  label: 'Balita Ditangani',
                                  value: '${dashboard.totalBalita}',
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                _ProfileStatCard(
                                  icon: Icons.calendar_month_rounded,
                                  label: 'Jadwal Aktif',
                                  value: '$jadwalAktif',
                                  color: AppColors.info,
                                ),
                                const SizedBox(width: 8),
                                _ProfileStatCard(
                                  icon: Icons.description_rounded,
                                  label: 'Laporan Bulan Ini',
                                  value: '${dashboard.imunisasiBulanIni}',
                                  color: const Color(0xFF7E57C2),
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
                                  label: 'Notifikasi',
                                  color: AppColors.warning,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.pengaturanNotifikasi,
                                  ),
                                ),
                                _MenuRow(
                                  icon: Icons.event_available_rounded,
                                  label: 'Jadwal Imunisasi',
                                  color: AppColors.info,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.jadwalImunisasi,
                                  ),
                                ),
                                _MenuRow(
                                  icon: Icons.vaccines_rounded,
                                  label: 'Kelola Jenis Imunisasi',
                                  color: AppColors.success,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.jenisImunisasi,
                                  ),
                                ),
                                _MenuRow(
                                  icon: Icons.manage_accounts_rounded,
                                  label: 'Manajemen Pengguna',
                                  color: const Color(0xFF7E57C2),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.manajemenPengguna,
                                  ),
                                ),
                                _MenuRow(
                                  icon: Icons.help_rounded,
                                  label: 'Pusat Bantuan',
                                  color: AppColors.primary,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.pusatBantuan,
                                  ),
                                ),
                                _MenuRow(
                                  icon: Icons.privacy_tip_rounded,
                                  label: 'Kebijakan Privasi',
                                  color: AppColors.info,
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
        );

    if (!widget.standalone) return content;

    return Scaffold(backgroundColor: AppColors.background, body: content);
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
          colors: [AppColors.primary, AppColors.primaryDark],
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
                  width: 92,
                  height: 92,
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
                  child: Icon(avatarIcon, color: AppColors.primary, size: 52),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
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
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 48, endIndent: 14),
      ],
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ProfileStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
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
