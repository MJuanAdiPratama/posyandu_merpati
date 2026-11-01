import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomSnackbar {
  static void sukses(BuildContext context, String pesan) {
    _tampilkan(context, pesan, AppColors.success, Icons.check_circle_outline);
  }

  static void gagal(BuildContext context, String pesan) {
    _tampilkan(context, pesan, AppColors.error, Icons.error_outline);
  }

  static void info(BuildContext context, String pesan) {
    _tampilkan(context, pesan, AppColors.info, Icons.info_outline);
  }

  static void _tampilkan(
    BuildContext context,
    String pesan,
    Color warna,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(pesan, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
