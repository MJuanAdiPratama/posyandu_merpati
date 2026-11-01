import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

class EmptyStateWidget extends StatelessWidget {
  final String? pesan;
  final IconData? icon;
  final VoidCallback? onRetry;

  const EmptyStateWidget({super.key, this.pesan, this.icon, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.inbox_outlined,
            size: 72,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            pesan ?? AppStrings.dataKosong,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ],
      ),
    );
  }
}
