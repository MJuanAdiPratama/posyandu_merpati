import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class PosyanduLogo extends StatelessWidget {
  final double size;

  const PosyanduLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(painter: _DoveHouseLogoPainter()),
    );
  }
}

class _DoveHouseLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bird = Path()
      ..moveTo(size.width * 0.21, size.height * 0.42)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.22,
        size.width * 0.42,
        size.height * 0.27,
        size.width * 0.47,
        size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.30,
        size.width * 0.68,
        size.height * 0.28,
        size.width * 0.76,
        size.height * 0.34,
      )
      ..cubicTo(
        size.width * 0.64,
        size.height * 0.43,
        size.width * 0.54,
        size.height * 0.55,
        size.width * 0.48,
        size.height * 0.66,
      )
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.58,
        size.width * 0.28,
        size.height * 0.52,
        size.width * 0.21,
        size.height * 0.42,
      )
      ..close();
    canvas.drawPath(bird, white);

    final wing = Path()
      ..moveTo(size.width * 0.38, size.height * 0.40)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.23,
        size.width * 0.44,
        size.height * 0.13,
        size.width * 0.56,
        size.height * 0.10,
      )
      ..cubicTo(
        size.width * 0.59,
        size.height * 0.25,
        size.width * 0.54,
        size.height * 0.36,
        size.width * 0.44,
        size.height * 0.47,
      )
      ..close();
    canvas.drawPath(wing, white);

    final tail = Path()
      ..moveTo(size.width * 0.22, size.height * 0.43)
      ..lineTo(size.width * 0.06, size.height * 0.26)
      ..lineTo(size.width * 0.10, size.height * 0.50)
      ..lineTo(size.width * 0.03, size.height * 0.63)
      ..lineTo(size.width * 0.27, size.height * 0.57)
      ..close();
    canvas.drawPath(tail, white);

    final beak = Path()
      ..moveTo(size.width * 0.77, size.height * 0.35)
      ..lineTo(size.width * 0.88, size.height * 0.39)
      ..lineTo(size.width * 0.77, size.height * 0.43)
      ..close();
    canvas.drawPath(beak, white);

    canvas.drawCircle(
      Offset(size.width * 0.66, size.height * 0.35),
      size.width * 0.018,
      Paint()..color = AppColors.primaryDark,
    );

    final house = Path()
      ..moveTo(size.width * 0.50, size.height * 0.68)
      ..lineTo(size.width * 0.66, size.height * 0.52)
      ..lineTo(size.width * 0.83, size.height * 0.68)
      ..moveTo(size.width * 0.56, size.height * 0.66)
      ..lineTo(size.width * 0.56, size.height * 0.86)
      ..lineTo(size.width * 0.80, size.height * 0.86)
      ..lineTo(size.width * 0.80, size.height * 0.66);
    canvas.drawPath(house, stroke);

    canvas.drawLine(
      Offset(size.width * 0.68, size.height * 0.69),
      Offset(size.width * 0.68, size.height * 0.80),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.63, size.height * 0.745),
      Offset(size.width * 0.73, size.height * 0.745),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HealthHeroIllustration extends StatelessWidget {
  final bool isKader;
  final double height;

  const HealthHeroIllustration({
    super.key,
    required this.isKader,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: height * 0.08,
            child: Container(
              width: height * 1.22,
              height: height * 1.02,
              decoration: const BoxDecoration(
                color: AppColors.surfaceMint,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 26,
            child: Icon(
              Icons.local_hospital_outlined,
              size: height * 0.32,
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            right: 20,
            top: 14,
            child: Icon(
              Icons.favorite_rounded,
              size: height * 0.18,
              color: AppColors.secondary.withValues(alpha: 0.38),
            ),
          ),
          Positioned(
            right: 32,
            bottom: 16,
            child: Icon(
              Icons.child_care_rounded,
              size: height * 0.44,
              color: isKader ? AppColors.accent : AppColors.primaryLight,
            ),
          ),
          Positioned(
            bottom: 10,
            child: Container(
              width: height * 0.56,
              height: height * 0.72,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(height * 0.2),
              ),
              child: Icon(
                isKader
                    ? Icons.medical_services_rounded
                    : Icons.family_restroom_rounded,
                color: Colors.white,
                size: height * 0.32,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: height * 1.32,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.surfaceTeal.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RolePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const RolePill({
    super.key,
    required this.icon,
    required this.label,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SoftHeaderCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SoftHeaderCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.surfaceMint],
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class KaderHeroPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;

  const KaderHeroPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SoftHeaderCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

class GradientPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? bottom;
  final double bottomPadding;

  const GradientPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onBack,
    this.actions = const [],
    this.bottom,
    this.bottomPadding = 36,
  });

  @override
  Widget build(BuildContext context) {
    final hasDetail = subtitle != null || icon != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, 0, 8, bottomPadding),
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
                if (onBack != null)
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: onBack,
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (actions.isEmpty)
                  const SizedBox(width: 48)
                else
                  SizedBox(
                    width: 48.0 * actions.length,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions,
                    ),
                  ),
              ],
            ),
            if (hasDetail) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (subtitle != null)
                    Expanded(
                      child: Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (bottom != null) ...[const SizedBox(height: 12), bottom!],
          ],
        ),
      ),
    );
  }
}

class KaderActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const KaderActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              IconBadge(icon: icon, color: color, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoTextRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoTextRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconBadge({
    super.key,
    required this.icon,
    this.color = AppColors.primary,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    this.color = AppColors.success,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class UserScreenShell extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;

  const UserScreenShell({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: title, actions: actions),
      body: ListView(padding: padding, children: children),
    );
  }
}

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: leading,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: actions,
      bottom: bottom,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
      ),
    );
  }
}
