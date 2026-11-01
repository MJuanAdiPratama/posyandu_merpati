import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../data/models/profile_model.dart';
import '../../providers/manajemen_pengguna_provider.dart';

class ManajemenPenggunaScreen extends StatefulWidget {
  const ManajemenPenggunaScreen({super.key});

  @override
  State<ManajemenPenggunaScreen> createState() =>
      _ManajemenPenggunaScreenState();
}

class _ManajemenPenggunaScreenState extends State<ManajemenPenggunaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManajemenPenggunaProvider>().muat();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: 'Manajemen Pengguna'),
      body: Consumer<ManajemenPenggunaProvider>(
        builder: (_, provider, __) => Column(
          children: [
            _FilterRole(
              filterAktif: provider.filterRole,
              onChanged: provider.setFilterRole,
            ),
            if (provider.isLoading)
              const LinearProgressIndicator(color: AppColors.primary),
            Expanded(
              child: provider.daftarPengguna.isEmpty && !provider.isLoading
                  ? const Center(
                      child: Text(
                        'Belum ada pengguna',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: provider.muat,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: provider.daftarPengguna.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _PenggunaCard(
                          pengguna: provider.daftarPengguna[i],
                          onTap: () => _tampilkanBottomSheet(
                            context,
                            provider,
                            provider.daftarPengguna[i],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _tampilkanBottomSheet(
    BuildContext context,
    ManajemenPenggunaProvider provider,
    ProfileModel pengguna,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _DetailPenggunaSheet(
        pengguna: pengguna,
        onToggleAktif: () async {
          Navigator.pop(context);
          final label = pengguna.isActive ? 'dinonaktifkan' : 'diaktifkan';
          final berhasil = await provider.toggleStatusAktif(pengguna);
          if (!context.mounted) return;
          if (berhasil) {
            CustomSnackbar.sukses(context, 'Pengguna berhasil $label');
          } else {
            CustomSnackbar.gagal(context, 'Gagal mengubah status pengguna');
          }
        },
        onUbahRole: (roleBaru) async {
          Navigator.pop(context);
          final berhasil = await provider.ubahRole(pengguna, roleBaru);
          if (!context.mounted) return;
          if (berhasil) {
            CustomSnackbar.sukses(
              context,
              'Role berhasil diubah menjadi $roleBaru',
            );
          } else {
            CustomSnackbar.gagal(context, 'Gagal mengubah role');
          }
        },
      ),
    );
  }
}

class _FilterRole extends StatelessWidget {
  final String filterAktif;
  final ValueChanged<String> onChanged;

  const _FilterRole({required this.filterAktif, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final opsi = ['semua', 'kader', 'orang_tua'];
    final label = {
      'semua': 'Semua',
      'kader': 'Kader',
      'orang_tua': 'Orang Tua',
    };

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: opsi.map((role) {
          final aktif = filterAktif == role;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label[role]!),
              selected: aktif,
              onSelected: (_) => onChanged(role),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: aktif ? Colors.white : AppColors.textPrimary,
                fontWeight: aktif ? FontWeight.w600 : FontWeight.normal,
              ),
              backgroundColor: AppColors.surfaceMint,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PenggunaCard extends StatelessWidget {
  final ProfileModel pengguna;
  final VoidCallback onTap;

  const _PenggunaCard({required this.pengguna, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isKader = pengguna.role == 'kader';
    final roleColor = isKader ? AppColors.roleKader : AppColors.roleOrangTua;
    final roleLabel = isKader ? 'Kader' : 'Orang Tua';

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.15),
          child: Text(
            pengguna.nama.isNotEmpty ? pengguna.nama[0].toUpperCase() : '?',
            style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          pengguna.nama,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          pengguna.email,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                roleLabel,
                style: TextStyle(
                  color: roleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              pengguna.isActive ? Icons.check_circle : Icons.cancel,
              color: pengguna.isActive ? AppColors.success : AppColors.error,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailPenggunaSheet extends StatelessWidget {
  final ProfileModel pengguna;
  final VoidCallback onToggleAktif;
  final ValueChanged<String> onUbahRole;

  const _DetailPenggunaSheet({
    required this.pengguna,
    required this.onToggleAktif,
    required this.onUbahRole,
  });

  @override
  Widget build(BuildContext context) {
    final roleLawan = pengguna.role == 'kader' ? 'orang_tua' : 'kader';
    final roleLawanLabel = pengguna.role == 'kader' ? 'Orang Tua' : 'Kader';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                child: Text(
                  pengguna.nama.isNotEmpty
                      ? pengguna.nama[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pengguna.nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      pengguna.email,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              pengguna.isActive ? Icons.block : Icons.check_circle_outline,
              color: pengguna.isActive ? AppColors.error : AppColors.success,
            ),
            title: Text(
              pengguna.isActive ? 'Nonaktifkan Pengguna' : 'Aktifkan Pengguna',
              style: TextStyle(
                color: pengguna.isActive ? AppColors.error : AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              pengguna.isActive
                  ? 'Pengguna tidak bisa login setelah dinonaktifkan'
                  : 'Pengguna bisa login kembali',
              style: const TextStyle(fontSize: 12),
            ),
            onTap: onToggleAktif,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.swap_horiz, color: AppColors.info),
            title: Text(
              'Ubah Role ke $roleLawanLabel',
              style: const TextStyle(
                color: AppColors.info,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Role saat ini: ${pengguna.role == 'kader' ? 'Kader' : 'Orang Tua'}. Perubahan efektif saat login berikutnya.',
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () =>
                _konfirmasiUbahRole(context, roleLawan, roleLawanLabel),
          ),
        ],
      ),
    );
  }

  void _konfirmasiUbahRole(
    BuildContext context,
    String roleBaru,
    String roleBaruLabel,
  ) async {
    final ok = await showConfirmationDialog(
      context: context,
      title: 'Konfirmasi Ubah Role',
      message:
          'Ubah role ${pengguna.nama} menjadi $roleBaruLabel? Perubahan akan efektif saat pengguna login berikutnya.',
      confirmText: 'Ubah',
      confirmColor: AppColors.info,
      icon: Icons.manage_accounts_outlined,
    );
    if (ok) onUbahRole(roleBaru);
  }
}
