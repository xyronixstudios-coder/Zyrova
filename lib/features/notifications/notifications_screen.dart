import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/notification_service.dart';
import '../profile/user_profile_screen.dart';

class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() =>
      _NotificationsListScreenState();
}

class _NotificationsListScreenState
    extends State<NotificationsListScreen> {
  List<NotifModel> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    Future.delayed(const Duration(milliseconds: 500), () {
      NotificationService.markAllRead();
    });
  }

  Future<void> _load() async {
    final notifs = await NotificationService.getMyNotifications();
    if (!mounted) return;
    setState(() {
      _notifs = notifs;
      _loading = false;
    });
  }

  String _timeAgo(DateTime d, AppStrings t) {
    final diff = DateTime.now().difference(d);
    if (diff.isNegative) return t.justNow;
    if (diff.inMinutes < 1) return t.justNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes}${t.minutesAgo}';
    if (diff.inHours < 24) return '${diff.inHours}${t.hoursAgo}';
    if (diff.inDays < 7) return '${diff.inDays}${t.daysAgo}';
    return '${(diff.inDays / 7).floor()}${t.weeksAgo}';
  }

  String _icon(NotifModel n) {
    switch (n.type) {
      case 'like':
        return '❤️';
      case 'comment':
        return '💬';
      case 'follow':
        return '👤';
      default:
        return '🔔';
    }
  }

  String _message(NotifModel n, AppStrings t) {
    switch (n.type) {
      case 'like':
        return t.likeNotif;
      case 'comment':
        return t.commentNotif;
      case 'follow':
        return t.followNotif;
      default:
        return t.notifUnknown;
    }
  }

  void _openProfile(String userId) {
    if (userId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: userId),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Text(t.notifications,
            style: TextStyle(color: AppColors.text)),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _notifs.isEmpty
              ? _empty(t)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  backgroundColor: AppColors.card,
                  child: ListView.builder(
                    itemCount: _notifs.length,
                    itemBuilder: (context, i) => _tile(_notifs[i], t),
                  ),
                ),
    );
  }

  Widget _empty(AppStrings t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text(t.noNotifications,
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _tile(NotifModel n, AppStrings t) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openProfile(n.actorId),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          color: n.isRead
              ? Colors.transparent
              : AppColors.primary.withOpacity(0.08),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary,
                    backgroundImage: n.actorAvatar.isNotEmpty
                        ? NetworkImage(n.actorAvatar)
                        : null,
                    child: n.actorAvatar.isEmpty
                        ? Text(n.actorUsername[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 20))
                        : null,
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.background, width: 2),
                      ),
                      child: Center(
                        child: Text(_icon(n),
                            style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                            color: AppColors.text, fontSize: 14),
                        children: [
                          TextSpan(
                            text: '@${n.actorUsername} ',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: _message(n, t),
                            style: TextStyle(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_timeAgo(n.createdAt, t),
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12)),
                  ],
                ),
              ),
              if (!n.isRead)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
