import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/brand_widgets.dart';
import '../../auth/providers/auth_provider.dart';

class PengaturanNotifikasiScreen extends StatefulWidget {
  const PengaturanNotifikasiScreen({super.key});

  @override
  State<PengaturanNotifikasiScreen> createState() =>
      _PengaturanNotifikasiScreenState();
}

class _PengaturanNotifikasiScreenState
    extends State<PengaturanNotifikasiScreen> {
  SharedPreferences? _prefs;
  bool _isLoading = true;
  String _role = 'orang_tua';
  bool _notifikasiAktif = true;
  final Map<String, bool> _values = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final profilRole = context.read<AuthProvider>().profil?.role;
    final role = profilRole == 'kader' ? 'kader' : 'orang_tua';
    final prefs = await SharedPreferences.getInstance();
    final options = _optionsForRole(role);
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _role = role;
      _notifikasiAktif = prefs.getBool(_key('notifikasiAktif', role)) ?? true;
      _values
        ..clear()
        ..addEntries(
          options.map(
            (option) => MapEntry(
              option.key,
              prefs.getBool(_key(option.key, role)) ?? true,
            ),
          ),
        );
      _isLoading = false;
    });
  }

  String _key(String key, [String? role]) => '${role ?? _role}.$key';

  Future<void> _save(String key, bool value) async {
    await _prefs?.setBool(_key(key), value);
  }

  void _setNotifikasiAktif(bool value) {
    final options = _optionsForRole(_role);
    setState(() {
      _notifikasiAktif = value;
      for (final option in options) {
        _values[option.key] = value;
      }
    });
    _save('notifikasiAktif', value);
    for (final option in options) {
      _save(option.key, value);
    }
  }

  void _setToggle(String key, bool value) {
    if (!_notifikasiAktif) return;
    setState(() {
      _values[key] = value;
    });
    _save(key, value);
  }

  List<_NotificationOption> get _options => _optionsForRole(_role);

  List<_NotificationOption> _optionsForRole(String role) {
    if (role == 'kader') {
      return const [
        _NotificationOption(
          key: 'pendaftaranBalita',
          icon: Icons.how_to_reg_rounded,
          color: AppColors.primary,
          title: 'Pendaftaran Balita',
          subtitle: 'Balita baru yang menunggu verifikasi kader.',
        ),
        _NotificationOption(
          key: 'agendaPosyandu',
          icon: Icons.event_note_rounded,
          color: AppColors.info,
          title: 'Agenda Posyandu',
          subtitle: 'Pengingat jadwal layanan Posyandu mendatang.',
        ),
        _NotificationOption(
          key: 'jadwalImunisasi',
          icon: Icons.vaccines_rounded,
          color: AppColors.success,
          title: 'Jadwal Imunisasi',
          subtitle: 'Balita yang perlu imunisasi hari ini atau terlambat.',
        ),
        _NotificationOption(
          key: 'dataBelumLengkap',
          icon: Icons.assignment_late_rounded,
          color: AppColors.warning,
          title: 'Data Belum Lengkap',
          subtitle: 'Data balita yang perlu dilengkapi atau diperbarui.',
        ),
        _NotificationOption(
          key: 'inputPertumbuhan',
          icon: Icons.show_chart_rounded,
          color: Color(0xFF7E57C2),
          title: 'Input Pertumbuhan',
          subtitle: 'Pengingat berat dan tinggi badan yang belum diinput.',
        ),
        _NotificationOption(
          key: 'laporanBulanan',
          icon: Icons.assessment_rounded,
          color: Color(0xFFFF7043),
          title: 'Laporan Bulanan',
          subtitle: 'Pengingat rekap dan ekspor laporan akhir bulan.',
        ),
        _NotificationOption(
          key: 'suaraGetar',
          icon: Icons.vibration_rounded,
          color: AppColors.warning,
          title: 'Suara & Getar',
          subtitle: 'Aktifkan suara atau getaran saat notifikasi masuk.',
        ),
      ];
    }

    return const [
      _NotificationOption(
        key: 'verifikasiBalita',
        icon: Icons.verified_user_rounded,
        color: AppColors.primary,
        title: 'Verifikasi Balita',
        subtitle: 'Status pendaftaran balita disetujui atau ditolak.',
      ),
      _NotificationOption(
        key: 'jadwalImunisasi',
        icon: Icons.vaccines_rounded,
        color: AppColors.info,
        title: 'Jadwal Imunisasi',
        subtitle: 'Pengingat imunisasi balita yang akan datang.',
      ),
      _NotificationOption(
        key: 'agendaPosyandu',
        icon: Icons.event_note_rounded,
        color: AppColors.success,
        title: 'Agenda Posyandu',
        subtitle: 'Jadwal layanan Posyandu terdekat.',
      ),
      _NotificationOption(
        key: 'hasilPemeriksaan',
        icon: Icons.monitor_heart_rounded,
        color: AppColors.warning,
        title: 'Hasil Pemeriksaan',
        subtitle: 'Hasil imunisasi, pertumbuhan, dan status gizi balita.',
      ),
      _NotificationOption(
        key: 'edukasi',
        icon: Icons.menu_book_rounded,
        color: Color(0xFF7E57C2),
        title: 'Edukasi Kesehatan',
        subtitle: 'Artikel atau informasi edukasi kesehatan baru.',
      ),
      _NotificationOption(
        key: 'pengingatUlang',
        icon: Icons.alarm_rounded,
        color: Color(0xFFFF7043),
        title: 'Pengingat Ulang',
        subtitle: 'Reminder H-1 atau hari-H untuk jadwal penting.',
      ),
      _NotificationOption(
        key: 'suaraGetar',
        icon: Icons.vibration_rounded,
        color: AppColors.warning,
        title: 'Suara & Getar',
        subtitle: 'Aktifkan suara atau getaran saat notifikasi masuk.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _NotificationHeader(onBack: () => Navigator.pop(context)),
                  Transform.translate(
                    offset: const Offset(0, -22),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Column(
                        children: [
                          KaderHeroPanel(
                            title: 'Pengaturan Notifikasi',
                            subtitle: _notifikasiAktif
                                ? 'Notifikasi ${_roleLabel.toLowerCase()} aktif untuk pengingat dan informasi layanan.'
                                : 'Notifikasi ${_roleLabel.toLowerCase()} sedang dinonaktifkan.',
                            icon: Icons.notifications_active_rounded,
                          ),
                          const SizedBox(height: 14),
                          _MasterNotificationCard(
                            value: _notifikasiAktif,
                            onChanged: _setNotifikasiAktif,
                          ),
                          const SizedBox(height: 14),
                          _SettingsCard(
                            enabled: _notifikasiAktif,
                            children: [
                              for (var i = 0; i < _options.length; i++)
                                _NotificationToggleRow(
                                  icon: _options[i].icon,
                                  color: _options[i].color,
                                  title: _options[i].title,
                                  subtitle: _options[i].subtitle,
                                  value: _values[_options[i].key] ?? true,
                                  enabled: _notifikasiAktif,
                                  isLast: i == _options.length - 1,
                                  onChanged: (value) =>
                                      _setToggle(_options[i].key, value),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const _NotificationNote(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String get _roleLabel => _role == 'kader' ? 'Kader' : 'Orang Tua';
}

class _NotificationOption {
  final String key;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _NotificationOption({
    required this.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

class _NotificationHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _NotificationHeader({required this.onBack});

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
                'Pengaturan Notifikasi',
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

class _MasterNotificationCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MasterNotificationCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: value ? AppColors.surfaceMint : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          IconBadge(
            icon: value
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_rounded,
            color: value ? AppColors.primary : AppColors.textSecondary,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value ? 'Notifikasi Aktif' : 'Notifikasi Mati',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value
                      ? 'Aplikasi akan menampilkan pengingat dan pembaruan.'
                      : 'Semua kategori notifikasi aplikasi dimatikan.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool enabled;
  final List<Widget> children;

  const _SettingsCard({required this.enabled, required this.children});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
        child: Column(children: children),
      ),
    );
  }
}

class _NotificationToggleRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final bool isLast;
  final ValueChanged<bool> onChanged;

  const _NotificationToggleRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
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
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: enabled ? onChanged : null,
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}

class _NotificationNote extends StatelessWidget {
  const _NotificationNote();

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
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pengaturan ini berlaku untuk notifikasi yang ditampilkan aplikasi di perangkat ini.',
              style: TextStyle(
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
