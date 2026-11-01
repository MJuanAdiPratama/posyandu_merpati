import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _konfirmasiCtrl = TextEditingController();
  bool _obscure = true;
  bool _setuju = false;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _konfirmasiCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_setuju) {
      CustomSnackbar.gagal(
        context,
        'Anda perlu menyetujui syarat dan ketentuan terlebih dahulu',
      );
      return;
    }

    final provider = context.read<AuthProvider>();
    final berhasil = await provider.register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      nama: _namaCtrl.text.trim(),
    );
    if (!mounted) return;
    if (berhasil) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboardOrtu,
        (_) => false,
      );
    } else {
      CustomSnackbar.gagal(
        context,
        provider.error ?? AppStrings.gagalMenyimpan,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBottomScene: false,
      child: Column(
        children: [
          const Align(alignment: Alignment.centerLeft, child: AuthBackButton()),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          'Daftar Akun',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Buat akun orang tua baru',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        AuthTextField(
                          controller: _namaCtrl,
                          label: 'Nama Lengkap',
                          hint: 'Masukkan nama lengkap',
                          icon: Icons.person_outline_rounded,
                          validator: (v) => v == null || v.isEmpty
                              ? AppStrings.fieldWajibDiisi
                              : null,
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          hint: 'Masukkan email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return AppStrings.fieldWajibDiisi;
                            }
                            if (!v.contains('@')) {
                              return AppStrings.emailTidakValid;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          controller: _passCtrl,
                          label: 'Password',
                          hint: 'Buat password',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscure,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return AppStrings.fieldWajibDiisi;
                            }
                            if (v.length < 6) return AppStrings.passwordMinimal;
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          controller: _konfirmasiCtrl,
                          label: 'Konfirmasi Password',
                          hint: 'Konfirmasi password',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscure,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) => v != _passCtrl.text
                              ? AppStrings.passwordTidakSama
                              : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: Checkbox(
                                value: _setuju,
                                activeColor: AppColors.primary,
                                onChanged: (value) =>
                                    setState(() => _setuju = value ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Saya menyetujui Syarat & Ketentuan dan Kebijakan Privasi',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Consumer<AuthProvider>(
                          builder: (_, auth, __) => AuthPrimaryButton(
                            label: 'Daftar',
                            isLoading: auth.isLoading,
                            onPressed: _register,
                          ),
                        ),
                        const SizedBox(height: 24),
                        AuthLinkRow(
                          text: 'Sudah punya akun?',
                          action: 'Masuk sekarang',
                          onTap: () => Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.login,
                            (_) => false,
                            arguments: const {'role': 'orang_tua'},
                          ),
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
    );
  }
}
