import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/brand_widgets.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/notification_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/notifikasi_ortu_provider.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  String? _loadedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = Provider.of<AuthProvider>(context).profil?.id;
    if (userId == null || _loadedUserId == userId) return;

    _loadedUserId = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Tidak memanggil muatNotifikasi di sini — data sudah dimuat oleh
      // DashboardOrtuScreen.initState. Pull-to-refresh untuk muat ulang manual.
      context.read<NotifikasiOrtuProvider>().subscribeRealtime(userId);
    });
  }

  IconData _iconFromType(String type) {
    switch (type) {
      case 'hasil_imunisasi':
        return Icons.vaccines_rounded;
      case 'pertumbuhan':
        return Icons.show_chart_rounded;
      case 'reminder':
        return Icons.alarm_rounded;
      case 'pengumuman':
        return Icons.campaign_rounded;
      case 'verifikasi':
        return Icons.verified_user_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFromType(String type) {
    switch (type) {
      case 'hasil_imunisasi':
        return AppColors.success;
      case 'pertumbuhan':
        return AppColors.secondary;
      case 'reminder':
        return AppColors.accent;
      case 'pengumuman':
        return const Color(0xFF7E57C2);
      case 'verifikasi':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientPageHeader(
            title: 'Notifikasi',
            subtitle: 'Pengingat dan pembaruan layanan Posyandu.',
            icon: Icons.notifications_rounded,
            onBack: () => Navigator.pop(context),
            actions: [
              Consumer<NotifikasiOrtuProvider>(
                builder: (_, provider, __) => PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  tooltip: 'Opsi notifikasi',
                  onSelected: (value) async {
                    final userId = auth.profil?.id;
                    if (userId == null) return;
                    if (value == 'tandai_dibaca') {
                      await provider.tandaiSemuaDibaca(userId);
                    } else if (value == 'hapus_semua') {
                      final ok = await showConfirmationDialog(
                        context: context,
                        title: 'Hapus Semua Notifikasi',
                        message:
                            'Semua notifikasi akan dihapus permanen. Lanjutkan?',
                        confirmText: 'Hapus Semua',
                        icon: Icons.delete_sweep_rounded,
                      );
                      if (ok == true && context.mounted) {
                        await provider.hapusSemua(userId);
                        if (context.mounted) {
                          CustomSnackbar.sukses(
                            context,
                            'Semua notifikasi berhasil dihapus',
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'tandai_dibaca',
                      child: Row(
                        children: [
                          Icon(Icons.done_all_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Tandai semua dibaca'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'hapus_semua',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_sweep_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Hapus semua',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -10),
              child: Consumer<NotifikasiOrtuProvider>(
                builder: (_, provider, __) {
                  if (provider.isLoading) return const LoadingWidget();

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      final userId = auth.profil?.id;
                      if (userId != null) {
                        await provider.muatNotifikasi(userId);
                      }
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                      children: [
                        if (provider.daftar.isEmpty)
                          const EmptyStateWidget(
                            icon: Icons.notifications_off_outlined,
                            pesan: AppStrings.belumAdaNotifikasi,
                          )
                        else
                          ...provider.daftar
                              .take(50)
                              .map(
                                (notif) => Dismissible(
                                  key: ValueKey(notif.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                  confirmDismiss: (_) async {
                                    return showConfirmationDialog(
                                      context: context,
                                      title: 'Hapus Notifikasi',
                                      message: 'Hapus notifikasi ini?',
                                      icon: Icons.delete_outline_rounded,
                                    );
                                  },
                                  onDismissed: (_) => provider.hapus(notif.id),
                                  child: _NotifCard(
                                    notif: notif,
                                    color: _colorFromType(notif.type),
                                    icon: _iconFromType(notif.type),
                                    onTap: () {
                                      if (!notif.isRead) {
                                        provider.tandaiDibaca(notif.id);
                                      }
                                    },
                                  ),
                                ),
                              ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _NotifCard({
    required this.notif,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead
                ? AppColors.border
                : color.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Colored left border untuk unread ──────────────────────
            if (!notif.isRead)
              Container(
                width: 4,
                height: 76,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
            // ── Icon ──────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.only(
                left: notif.isRead ? 12 : 10,
                top: 12,
                bottom: 12,
                right: 0,
              ),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
            ),
            // ── Konten ────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: notif.isRead
                                  ? FontWeight.w700
                                  : FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (!notif.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 3),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notif.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      DateFormat(
                        'dd MMM yyyy • HH:mm',
                        'id_ID',
                      ).format(notif.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textDisabled,
                      ),
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
