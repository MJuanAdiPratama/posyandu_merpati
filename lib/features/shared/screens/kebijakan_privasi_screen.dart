import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/brand_widgets.dart';

class KebijakanPrivasiScreen extends StatelessWidget {
  const KebijakanPrivasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _PrivacyHeader(onBack: () => Navigator.pop(context)),
            Transform.translate(
              offset: const Offset(0, -22),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const KaderHeroPanel(
                      title: 'Kebijakan Privasi',
                      subtitle:
                          'Ringkasan cara Posyandu Merpati menjaga dan menggunakan data layanan keluarga.',
                      icon: Icons.privacy_tip_rounded,
                    ),
                    const SizedBox(height: 14),
                    const _TrustStrip(),
                    const SizedBox(height: 18),
                    const SectionTitle(title: 'Data yang Dikelola'),
                    const SizedBox(height: 10),
                    const _PrivacySection(
                      icon: Icons.child_care_rounded,
                      color: AppColors.primary,
                      title: 'Data Balita dan Orang Tua',
                      description:
                          'Aplikasi menyimpan identitas balita, data orang tua, alamat, nomor kontak, dan status verifikasi untuk kebutuhan layanan Posyandu.',
                    ),
                    const SizedBox(height: 10),
                    const _PrivacySection(
                      icon: Icons.vaccines_rounded,
                      color: AppColors.info,
                      title: 'Data Imunisasi dan Pertumbuhan',
                      description:
                          'Catatan imunisasi, jadwal, berat badan, tinggi badan, status gizi, dan riwayat pemeriksaan digunakan untuk pemantauan kesehatan anak.',
                    ),
                    const SizedBox(height: 10),
                    const _PrivacySection(
                      icon: Icons.notifications_active_rounded,
                      color: AppColors.warning,
                      title: 'Notifikasi Layanan',
                      description:
                          'Notifikasi digunakan untuk pengingat jadwal, pembaruan status, dan informasi layanan yang berkaitan dengan data balita.',
                    ),
                    const SizedBox(height: 18),
                    const SectionTitle(title: 'Cara Kami Melindungi Data'),
                    const SizedBox(height: 10),
                    const _PolicyListCard(
                      items: [
                        'Akses akun dibatasi berdasarkan role kader dan orang tua.',
                        'Data aplikasi tersimpan melalui layanan backend yang menerapkan autentikasi.',
                        'Informasi balita hanya ditampilkan kepada pengguna yang berwenang.',
                        'Perubahan data penting dilakukan melalui fitur yang terverifikasi di aplikasi.',
                      ],
                    ),
                    const SizedBox(height: 18),
                    const SectionTitle(title: 'Hak Pengguna'),
                    const SizedBox(height: 10),
                    const _PrivacySection(
                      icon: Icons.verified_user_rounded,
                      color: AppColors.success,
                      title: 'Kontrol dan Pembaruan Data',
                      description:
                          'Pengguna dapat meminta pembaruan data melalui kader/admin Posyandu jika ada informasi yang tidak sesuai.',
                    ),
                    const SizedBox(height: 10),
                    const _PrivacySection(
                      icon: Icons.support_agent_rounded,
                      color: Color(0xFF7E57C2),
                      title: 'Bantuan Privasi',
                      description:
                          'Jika ada pertanyaan terkait privasi atau keamanan akun, hubungi admin Posyandu Merpati.',
                    ),
                    const SizedBox(height: 14),
                    const _LastUpdatedCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _PrivacyHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 42),
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
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: onBack,
            ),
            const Expanded(
              child: Text(
                'Kebijakan Privasi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _TrustTile(
            icon: Icons.lock_rounded,
            label: 'Aman',
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _TrustTile(
            icon: Icons.shield_rounded,
            label: 'Terjaga',
            color: AppColors.success,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _TrustTile(
            icon: Icons.group_rounded,
            label: 'Terbatas',
            color: AppColors.info,
          ),
        ),
      ],
    );
  }
}

class _TrustTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TrustTile({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _PrivacySection({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, color: color, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyListCard extends StatelessWidget {
  final List<String> items;

  const _PolicyListCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceMint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[i],
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (i != items.length - 1)
              const Divider(height: 18, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

class _LastUpdatedCard extends StatelessWidget {
  const _LastUpdatedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: const Row(
        children: [
          Icon(Icons.update_rounded, color: AppColors.primary, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Terakhir diperbarui: Juni 2026',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;

  const _SoftCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
