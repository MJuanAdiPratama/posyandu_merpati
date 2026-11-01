import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AuthProvider>();
    final berhasil = await provider.login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
    if (!mounted) return;
    if (berhasil) {
      final tujuan = provider.isKader
          ? AppRoutes.dashboardKader
          : AppRoutes.dashboardOrtu;
      Navigator.pushNamedAndRemoveUntil(context, tujuan, (_) => false);
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
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 110),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AuthHeader(
                          logoSize: 54,
                          titleSize: 22,
                          compact: true,
                        ),
                        const SizedBox(height: 44),
                        const Text(
                          'Login',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Masuk ke akun Anda',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 34),
                        AuthTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          hint: 'Masukkan email Anda',
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
                        const SizedBox(height: 18),
                        AuthTextField(
                          controller: _passCtrl,
                          label: 'Password',
                          hint: 'Masukkan password',
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
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.forgotPassword,
                            ),
                            child: const Text(
                              'Lupa password?',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Consumer<AuthProvider>(
                          builder: (_, auth, __) => AuthPrimaryButton(
                            label: 'Masuk',
                            isLoading: auth.isLoading,
                            onPressed: _login,
                          ),
                        ),
                        const SizedBox(height: 28),
                        AuthLinkRow(
                          text: 'Belum punya akun?',
                          action: 'Daftar sekarang',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.register,
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
