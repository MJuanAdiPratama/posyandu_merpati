import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';

class SmallDateBadge extends StatelessWidget {
  final DateTime date;
  final bool muted;

  const SmallDateBadge({super.key, required this.date, required this.muted});

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.textDisabled : AppColors.primary;
    return Container(
      width: 54,
      height: 58,
      decoration: BoxDecoration(
        color: muted ? AppColors.divider : AppColors.surfaceMint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('dd').format(date),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            DateFormat('MMM', 'id_ID').format(date).toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
