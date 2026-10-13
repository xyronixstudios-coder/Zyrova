import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/smart_cache.dart';
import '../../core/services/notification_service.dart';
import 'home_screen.dart';
import '../search/search_screen.dart';
import '../upload/upload_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../notifications/notifications_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  int _unreadNotifs = 0;
  RealtimeChannel? _notifChannel;

  // late ile tanımla, initState'te oluştur
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // ÖNCE ekranları oluştur
    _screens = [
      HomeScreen(onAddStory: () => _goToUpload()),
      const SearchScreen(),
      const UploadScreen(),
      const MessagesScreen(),
      const ProfileScreen(),
    ];

    // Sonra cache ve bildirimler
    SmartCache.instance.init();
    _loadUnread();
    _subscribeNotifs();
  }

  void _goToUpload() {
    if (mounted) {
      setState(() => _index = 2);
    }
  }

  @override
  void dispose() {
    _notifChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadUnread() async {
    final count = await NotificationService.getUnreadCount();
    if (mounted) setState(() => _unreadNotifs = count);
  }

  void _subscribeNotifs() {
    try {
      _notifChannel = NotificationService.subscribeToMyNotifications((n) {
        if (!mounted) return;
        setState(() => _unreadNotifs++);
        _showNotifBanner(n);
      });
    } catch (e) {
      print('Notification subscribe error: $e');
    }
  }

  void _showNotifBanner(NotifModel n) {
    final t = AppL.of(context);
    final msg = '@${n.actorUsername} ${
      n.type == 'like'
          ? t.likeNotif
          : n.type == 'comment'
              ? t.commentNotif
              : n.type == 'follow'
                  ? t.followNotif
                  : n.type == 'message'
                      ? 'sana mesaj gönderdi'
                      : t.notifUnknown
    }';

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.card,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        content: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            messenger.hideCurrentSnackBar();
            _goToNotificationsOrChat(n);
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                backgroundImage: n.actorAvatar.isNotEmpty
                    ? NetworkImage(n.actorAvatar)
                    : null,
                child: n.actorAvatar.isEmpty
                    ? Text(n.actorUsername[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Zyrova',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      msg,
                      style: TextStyle(
                          color: AppColors.text, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _goToNotificationsOrChat(NotifModel n) {
    if (n.type == 'message') {
      setState(() => _index = 3);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const NotificationsListScreen()),
      ).then((_) => _loadUnread());
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsListScreen()),
    ).then((_) => _loadUnread());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);
    final type = Responsive.of(context);

    if (type == ScreenType.mobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _screens[_index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) {
            if (_index != i) setState(() => _index = i);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home), label: t.home),
            BottomNavigationBarItem(
                icon: const Icon(Icons.search), label: t.discover),
            BottomNavigationBarItem(
              icon: const Icon(Icons.add_box,
                  size: 32, color: AppColors.primary),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _badgeIcon(Icons.message, _unreadNotifs),
              label: t.messages,
            ),
            BottomNavigationBarItem(
                icon: const Icon(Icons.person), label: t.profile),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Container(
            width: type == ScreenType.desktop ? 240 : 80,
            color: AppColors.surface,
            child: Column(
              children: [
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/zyrova-logo.png',
                    width: 44,
                    height: 44,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.flash_on,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _item(Icons.home, t.home, 0, type),
                _item(Icons.search, t.discover, 1, type),
                _item(Icons.add_box, t.upload, 2, type),
                _item(Icons.message, t.messages, 3, type,
                    badge: _unreadNotifs),
                _item(Icons.person, t.profile, 4, type),
                const Spacer(),
                _item(Icons.notifications, t.notifications, 5, type,
                    badge: _unreadNotifs, onTap: _openNotifications),
                _item(Icons.settings, t.settings, -1, type),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(child: _screens[_index]),
        ],
      ),
    );
  }

  Widget _badgeIcon(IconData icon, int count) {
    if (count == 0) return Icon(icon);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _item(IconData icon, String label, int index, ScreenType type,
      {int badge = 0, VoidCallback? onTap}) {
    final active = _index == index;
    final isSettings = index == -1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap();
          } else if (isSettings) {
            _openSettings();
          } else {
            setState(() => _index = index);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: type == ScreenType.desktop ? 16 : 12,
          ),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: type == ScreenType.desktop
              ? Row(
                  children: [
                    _withBadge(icon, active, badge),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: active
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: _withBadge(icon, active, badge),
                ),
        ),
      ),
    );
  }

  Widget _withBadge(IconData icon, bool active, int badge) {
    final ic = Icon(icon,
        color: active ? AppColors.primary : AppColors.textSecondary,
        size: 26);
    if (badge == 0) return ic;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ic,
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
            child: Text(
              badge > 99 ? '99+' : '$badge',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
