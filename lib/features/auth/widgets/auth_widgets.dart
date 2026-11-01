import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/brand_widgets.dart';

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final bool showBottomScene;

  const AuthScaffold({
    super.key,
    required this.child,
    this.showBottomScene = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned.fill(child: _SoftBackground()),
          if (showBottomScene) const Positioned.fill(child: _BottomScene()),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  final double logoSize;
  final double titleSize;
  final bool compact;

  const AuthHeader({
    super.key,
    this.logoSize = 72,
    this.titleSize = 28,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PosyanduLogo(size: logoSize),
        SizedBox(height: compact ? 10 : 16),
        Text(
          AppStrings.appName,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sehat Balita, Bahagia Keluarga',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Kembali',
      onPressed: () => Navigator.maybePop(context),
      icon: const Icon(Icons.arrow_back_rounded),
      color: AppColors.textPrimary,
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: suffixIcon,
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class AuthInfoBox extends StatelessWidget {
  final IconData icon;
  final String text;

  const AuthInfoBox({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthLinkRow extends StatelessWidget {
  final String text;
  final String action;
  final VoidCallback onTap;

  const AuthLinkRow({
    super.key,
    required this.text,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(action, style: const TextStyle(fontSize: 12.5)),
        ),
      ],
    );
  }
}

class AuthSuccessMark extends StatelessWidget {
  final IconData icon;

  const AuthSuccessMark({super.key, this.icon = Icons.check_rounded});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      decoration: const BoxDecoration(
        color: AppColors.surfaceMint,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 42),
        ),
      ),
    );
  }
}

class _SoftBackground extends StatelessWidget {
  const _SoftBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            AppColors.surfaceMint.withValues(alpha: 0.36),
            Colors.white,
          ],
        ),
      ),
    );
  }
}

class _BottomScene extends StatelessWidget {
  const _BottomScene();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: 96,
          width: double.infinity,
          child: CustomPaint(painter: _BottomScenePainter()),
        ),
      ),
    );
  }
}

class _BottomScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ground = Paint()
      ..color = AppColors.surfaceMint.withValues(alpha: 0.72);
    final accent = Paint()..color = AppColors.primary.withValues(alpha: 0.10);

    final path = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.52,
        size.width * 0.52,
        size.height * 0.70,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.88,
        size.width,
        size.height * 0.58,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, ground);

    void tree(double x, double h) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h, 7, h),
          const Radius.circular(4),
        ),
        accent,
      );
      canvas.drawCircle(Offset(x + 3.5, size.height - h), 13, accent);
    }

    tree(size.width * 0.12, 42);
    tree(size.width * 0.74, 34);

    final house = Path()
      ..moveTo(size.width * 0.22, size.height * 0.72)
      ..lineTo(size.width * 0.28, size.height * 0.61)
      ..lineTo(size.width * 0.34, size.height * 0.72)
      ..lineTo(size.width * 0.34, size.height * 0.88)
      ..lineTo(size.width * 0.22, size.height * 0.88)
      ..close();
    canvas.drawPath(house, accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
