import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/agenda_imunisasi_provider.dart';
import '../providers/agenda_posyandu_provider.dart';
import '../providers/notifikasi_ortu_provider.dart';
import '../providers/ortu_balita_provider.dart';
import '../providers/pertumbuhan_provider.dart';
import '../providers/riwayat_imunisasi_provider.dart';
import 'balita/pertumbuhan_screen.dart';
import 'beranda/beranda_tab.dart';
import 'edukasi/edukasi_tab.dart';
import 'imunisasi/imunisasi_tab.dart';
import 'profil/profil_ortu_screen.dart';

class DashboardOrtuScreen extends StatefulWidget {
  final int initialIndex;

  const DashboardOrtuScreen({super.key, this.initialIndex = 0});

  @override
  State<DashboardOrtuScreen> createState() => _DashboardOrtuScreenState();
}

class _DashboardOrtuScreenState extends State<DashboardOrtuScreen> {
  static const int _profileTabIndex = 4;
  int _currentIndex = 0;
  bool _hasAppliedRouteIndex = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = _normalizeIndex(widget.initialIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final balitaProvider = context.read<OrtuBalitaProvider>();
      final notifProvider = context.read<NotifikasiOrtuProvider>();
      final pertumbuhanProvider = context.read<PertumbuhanProvider>();
      final agendaImunisasiProvider = context.read<AgendaImunisasiProvider>();
      final riwayatImunisasiProvider = context.read<RiwayatImunisasiProvider>();

      if (auth.profil == null) {
        balitaProvider.reset();
        pertumbuhanProvider.reset();
        agendaImunisasiProvider.reset();
        riwayatImunisasiProvider.reset();
        notifProvider.reset();
        return;
      }
      final userId = auth.profil!.id;

      await balitaProvider.muatByParent(userId);
      await notifProvider.muatNotifikasi(userId);
      notifProvider.subscribeRealtime(userId);

      if (mounted && balitaProvider.selected != null) {
        final balitaId = balitaProvider.selected!.id;
        await Future.wait([
          pertumbuhanProvider.muatByBalita(balitaId),
          agendaImunisasiProvider.muatByBalita(balitaId),
          riwayatImunisasiProvider.muatByBalita(balitaId),
        ]);
      } else {
        pertumbuhanProvider.reset();
        agendaImunisasiProvider.reset();
        riwayatImunisasiProvider.reset();
      }

      if (mounted) {
        context.read<AgendaPosyanduProvider>().muatDaftar();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasAppliedRouteIndex) return;
    _hasAppliedRouteIndex = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    final routeIndex = switch (args) {
      int value => value,
      {'initialIndex': final int value} => value,
      _ => null,
    };
    if (routeIndex == null) return;

    final index = _normalizeIndex(routeIndex);
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  void dispose() {
    context.read<NotifikasiOrtuProvider>().unsubscribe();
    super.dispose();
  }

  int _normalizeIndex(int index) {
    return index.clamp(0, _profileTabIndex);
  }

  void _setTab(int index) {
    setState(() => _currentIndex = _normalizeIndex(index));
  }

  void _openProfileTab() {
    _setTab(_profileTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          BerandaTab(onOpenProfile: _openProfileTab),
          const PertumbuhanScreen(standalone: false),
          const ImunisasiTab(),
          const EdukasiTab(),
          const ProfilOrtuScreen(),
        ],
      ),
      bottomNavigationBar: _OrtuBottomBar(
        currentIndex: _currentIndex,
        onTap: _setTab,
        onCenterTap: () =>
            Navigator.pushNamed(context, AppRoutes.registrasiBalita),
      ),
    );
  }
}

class _OrtuBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCenterTap;

  const _OrtuBottomBar({
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
              icon: Icons.show_chart_rounded,
              activeIcon: Icons.query_stats_rounded,
              label: 'Pertumbuhan',
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
              icon: Icons.vaccines_outlined,
              activeIcon: Icons.vaccines_rounded,
              label: 'Imunisasi',
              selected: currentIndex == 2,
              onTap: () => onTap(2),
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
