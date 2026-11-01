import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orang_tua/providers/notifikasi_ortu_provider.dart';
import '../providers/balita_kader_provider.dart';
import '../providers/dashboard_kader_provider.dart';
import '../providers/jadwal_posyandu_provider.dart';
import '../providers/monitoring_balita_provider.dart';
import 'balita/daftar_balita_screen.dart';
import 'beranda/beranda_kader_tab.dart';
import 'imunisasi/input_imunisasi_screen.dart';
import 'jadwal/jadwal_laporan_tab.dart';
import 'profil/profil_kader_screen.dart';

class DashboardKaderScreen extends StatefulWidget {
  const DashboardKaderScreen({super.key});

  @override
  State<DashboardKaderScreen> createState() => _DashboardKaderScreenState();
}

class _DashboardKaderScreenState extends State<DashboardKaderScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardKaderProvider>().muatDashboard();
      context.read<BalitaKaderProvider>().muatDaftar();
      context.read<JadwalPosyanduProvider>().muatDaftar();
      context.read<JadwalPosyanduProvider>().subscribeRealtime();
      context.read<MonitoringBalitaProvider>().muatData();

      final userId = context.read<AuthProvider>().profil?.id;
      if (userId != null) {
        final notifProvider = context.read<NotifikasiOrtuProvider>();
        notifProvider.muatNotifikasi(userId);
        notifProvider.subscribeRealtime(userId);
      }
    });
  }

  @override
  void dispose() {
    context.read<JadwalPosyanduProvider>().unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          BerandaKaderTab(),
          DaftarBalitaScreen(standalone: false),
          InputImunisasiScreen(standalone: false),
          JadwalLaporanTab(),
          ProfilKaderScreen(standalone: false),
        ],
      ),
      bottomNavigationBar: _KaderBottomBar(
        currentIndex: _currentIndex,
        onTap: _selectTab,
        onCenterTap: () => _selectTab(2),
      ),
    );
  }

  void _selectTab(int index) {
    setState(() => _currentIndex = index);
  }
}

class _KaderBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCenterTap;

  const _KaderBottomBar({
    required this.currentIndex,
    required this.onTap,
    required this.onCenterTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 76,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            _BottomItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Beranda',
              selected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _BottomItem(
              icon: Icons.article_outlined,
              activeIcon: Icons.article_rounded,
              label: 'Data',
              selected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            Expanded(
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onCenterTap,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF00B7B0), AppColors.primaryDark],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _BottomItem(
              icon: Icons.description_outlined,
              activeIcon: Icons.description_rounded,
              label: 'Laporan',
              selected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
            _BottomItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profil',
              selected: currentIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? activeIcon : icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
