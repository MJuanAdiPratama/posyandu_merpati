import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

class LoadingWidget extends StatelessWidget {
  final String? pesan;
  const LoadingWidget({super.key, this.pesan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (pesan != null) ...[
            const SizedBox(height: 12),
            Text(
              pesan ?? AppStrings.memuat,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
