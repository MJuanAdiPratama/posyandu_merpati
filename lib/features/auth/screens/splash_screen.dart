import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/brand_widgets.dart';
import '../../../routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _minimumSplashDuration = Duration(milliseconds: 1400);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cekSesi());
  }

  Future<void> _cekSesi() async {
    final auth = context.read<AuthProvider>();
    final stopwatch = Stopwatch()..start();
    await auth.muatProfil();
    final remaining = _minimumSplashDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) return;

    final tujuan = auth.isLoggedIn
        ? (auth.isKader ? AppRoutes.dashboardKader : AppRoutes.dashboardOrtu)
        : AppRoutes.login;
    Navigator.pushNamedAndRemoveUntil(context, tujuan, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBottomScene: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(28, 30, 28, 28),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PosyanduLogo(size: 96),
                    const SizedBox(height: 18),
                    const Text(
                      AppStrings.appName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sehat Balita, Bahagia Keluarga',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 34),
                    Transform.translate(
                      offset: const Offset(0, 0),
                      child: Image.asset(
                        'assets/images/splash-family-posyandu.png',
                        height: 230,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Text(
              AppStrings.memuat,
              style: TextStyle(color: AppColors.primaryDark, fontSize: 13),
            ),
            const SizedBox(height: 14),
            const _SplashProgress(),
          ],
        ),
      ),
    );
  }
}

class _SplashProgress extends StatelessWidget {
  const _SplashProgress();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: const LinearProgressIndicator(
          minHeight: 4,
          backgroundColor: AppColors.surfaceTeal,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
