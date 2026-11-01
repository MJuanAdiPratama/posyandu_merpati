import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/brand_widgets.dart';

class PusatBantuanScreen extends StatelessWidget {
  const PusatBantuanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HelpHeader(onBack: () => Navigator.pop(context)),
            Transform.translate(
              offset: const Offset(0, -22),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const KaderHeroPanel(
                      title: 'Pusat Bantuan',
                      subtitle:
                          'Temukan panduan singkat untuk menggunakan fitur utama Posyandu Merpati.',
                      icon: Icons.help_rounded,
                    ),
                    const SizedBox(height: 14),
                    const SectionTitle(title: 'Panduan Cepat'),
                    const SizedBox(height: 10),
                    const _HelpCard(
                      icon: Icons.groups_rounded,
                      color: AppColors.primary,
                      title: 'Data Balita',
                      description:
                          'Gunakan menu Data Balita untuk melihat, menambah, memverifikasi, dan membuka detail data anak.',
                    ),
                    const SizedBox(height: 10),
                    const _HelpCard(
                      icon: Icons.vaccines_rounded,
                      color: AppColors.info,
                      title: 'Imunisasi',
                      description:
                          'Pilih balita dan jadwal imunisasi, isi data pemeriksaan, lalu simpan agar riwayat terbarui.',
                    ),
                    const SizedBox(height: 10),
                    const _HelpCard(
                      icon: Icons.show_chart_rounded,
                      color: AppColors.success,
                      title: 'Pertumbuhan',
                      description:
                          'Catat berat dan tinggi badan. Status gizi dihitung otomatis dari data balita dan pemeriksaan.',
                    ),
                    const SizedBox(height: 10),
                    const _HelpCard(
                      icon: Icons.event_note_rounded,
                      color: AppColors.accent,
                      title: 'Jadwal & Laporan',
                      description:
                          'Pantau jadwal Posyandu terdekat dan ekspor laporan untuk kebutuhan arsip layanan.',
                    ),
                    const SizedBox(height: 18),
                    const SectionTitle(title: 'Butuh Bantuan Lanjutan?'),
                    const SizedBox(height: 10),
                    _ContactCard(
                      items: const [
                        _ContactItem(
                          icon: Icons.email_outlined,
                          label: 'Email Admin',
                          value: 'admin@posyandumerpati.id',
                        ),
                        _ContactItem(
                          icon: Icons.schedule_rounded,
                          label: 'Jam Layanan',
                          value: 'Senin - Jumat, 08.00 - 16.00 WIB',
                        ),
                        _ContactItem(
                          icon: Icons.location_on_outlined,
                          label: 'Lokasi',
                          value: 'Posyandu Merpati',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _InfoNote(
                      text:
                          'Jika terjadi kendala akun, hubungi kader/admin Posyandu agar data dapat dicek dengan aman.',
                    ),
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

class _HelpHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _HelpHeader({required this.onBack});

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
                'Pusat Bantuan',
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

class _HelpCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _HelpCard({
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

class _ContactCard extends StatelessWidget {
  final List<_ContactItem> items;

  const _ContactCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _ContactRow(item: items[i]),
            if (i != items.length - 1)
              const Divider(height: 18, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

class _ContactItem {
  final IconData icon;
  final String label;
  final String value;

  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _ContactRow extends StatelessWidget {
  final _ContactItem item;

  const _ContactRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(item.icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoNote extends StatelessWidget {
  final String text;

  const _InfoNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.info,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
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
