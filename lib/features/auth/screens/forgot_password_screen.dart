import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _terkirim = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AuthProvider>();
    final berhasil = await provider.resetPasswordForEmail(
      _emailCtrl.text.trim(),
    );
    if (!mounted) return;
    if (berhasil) {
      setState(() => _terkirim = true);
      CustomSnackbar.sukses(
        context,
        'Link reset password telah dikirim ke email Anda',
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
    final auth = context.watch<AuthProvider>();

    return AuthScaffold(
      showBottomScene: false,
      child: Column(
        children: [
          const Align(alignment: Alignment.centerLeft, child: AuthBackButton()),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 38, 24, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Lupa Password',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Masukkan email Anda untuk menerima\nlink reset password',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 42),
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
                        const SizedBox(height: 28),
                        AuthPrimaryButton(
                          label: _terkirim
                              ? 'Link Terkirim'
                              : 'Kirim Link Reset',
                          isLoading: auth.isLoading,
                          onPressed: _terkirim ? null : _kirim,
                        ),
                        const SizedBox(height: 28),
                        const AuthInfoBox(
                          icon: Icons.info_rounded,
                          text:
                              'Link reset password akan dikirim ke email Anda. Silakan cek inbox atau folder spam.',
                        ),
                        if (_terkirim) ...[
                          const SizedBox(height: 18),
                          TextButton(
                            onPressed: () => setState(() => _terkirim = false),
                            child: const Text('Kirim ulang ke email lain'),
                          ),
                        ],
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
