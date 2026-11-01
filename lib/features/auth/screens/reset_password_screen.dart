import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _konfirmasiCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _berhasil = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _konfirmasiCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AuthProvider>();
    final berhasil = await provider.gantiPassword(_passwordCtrl.text);
    if (!mounted) return;
    if (berhasil) {
      await provider.logout();
      if (!mounted) return;
      setState(() => _berhasil = true);
    } else {
      CustomSnackbar.gagal(
        context,
        provider.error ?? 'Gagal mengubah password',
      );
    }
  }

  void _kembaliLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (_) => false,
      arguments: const {'role': 'orang_tua'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return PopScope(
      canPop: _berhasil,
      child: AuthScaffold(
        showBottomScene: false,
        child: _berhasil
            ? _ResetSuccess(onLogin: _kembaliLogin)
            : Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AuthBackButton(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _PasswordRules(),
                                const SizedBox(height: 34),
                                const Text(
                                  'Reset Password',
                                  style: TextStyle(
                                    color: AppColors.primaryDark,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                AuthTextField(
                                  controller: _passwordCtrl,
                                  label: 'Password Baru',
                                  hint: 'Masukkan password baru',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscure1,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure1
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure1 = !_obscure1),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Password wajib diisi';
                                    }
                                    if (v.length < 6) {
                                      return 'Minimal 6 karakter';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                AuthTextField(
                                  controller: _konfirmasiCtrl,
                                  label: 'Konfirmasi Password',
                                  hint: 'Konfirmasi password baru',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscure2,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure2
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure2 = !_obscure2),
                                  ),
                                  validator: (v) => v != _passwordCtrl.text
                                      ? 'Password tidak cocok'
                                      : null,
                                ),
                                const SizedBox(height: 26),
                                AuthPrimaryButton(
                                  label: 'Reset Password',
                                  isLoading: auth.isLoading,
                                  onPressed: _simpan,
                                ),
                              ],
                            ),
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
}

class _PasswordRules extends StatelessWidget {
  const _PasswordRules();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _RuleRow(
          icon: Icons.lock_rounded,
          label: 'Password minimal 6 karakter',
        ),
        SizedBox(height: 14),
        _RuleRow(
          icon: Icons.text_fields_rounded,
          label: 'Gunakan kombinasi huruf dan angka',
        ),
        SizedBox(height: 14),
        _RuleRow(
          icon: Icons.verified_user_rounded,
          label: 'Jangan gunakan password yang mudah ditebak',
        ),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RuleRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceMint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryDark),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _ResetSuccess extends StatelessWidget {
  final VoidCallback onLogin;

  const _ResetSuccess({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AuthSuccessMark(icon: Icons.check_rounded),
              const SizedBox(height: 26),
              const Text(
                'Berhasil!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Password Anda berhasil direset.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
              ),
              const SizedBox(height: 34),
              AuthPrimaryButton(label: 'Kembali ke Login', onPressed: onLogin),
            ],
          ),
        ),
      ),
    );
  }
}
