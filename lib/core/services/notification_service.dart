import 'package:supabase_flutter/supabase_flutter.dart';

class NotifModel {
  final String id;
  final String type;
  final String actorUsername;
  final String actorAvatar;
  final String? videoId;
  final bool isRead;
  final DateTime createdAt;

  NotifModel({
    required this.id,
    required this.type,
    required this.actorUsername,
    required this.actorAvatar,
    this.videoId,
    required this.isRead,
    required this.createdAt,
  });
}

class NotificationService {
  static final _db = Supabase.instance.client;

  static Future<List<NotifModel>> getMyNotifications() async {
    try {
      final me = _db.auth.currentUser;
      if (me == null) return [];

      final data = await _db
          .from('notifications')
          .select('*, actor:profiles!notifications_actor_id_fkey(username, avatar_url)')
          .eq('user_id', me.id)
          .order('created_at', ascending: false)
          .limit(50);

      return (data as List).map((n) {
        final actor = n['actor'] as Map<String, dynamic>?;
        return NotifModel(
          id: n['id'],
          type: n['type'],
          actorUsername: actor?['username'] ?? 'kullanici',
          actorAvatar: actor?['avatar_url'] ?? '',
          videoId: n['video_id'],
          isRead: n['is_read'] ?? false,
          createdAt: DateTime.parse(n['created_at']),
        );
      }).toList();
    } catch (e) {
      print('GetNotifications Error: $e');
      return [];
    }
  }

  static Future<int> getUnreadCount() async {
    try {
      final me = _db.auth.currentUser;
      if (me == null) return 0;

      final data = await _db
          .from('notifications')
          .select('id')
          .eq('user_id', me.id)
          .eq('is_read', false);

      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  static Future<void> markAllRead() async {
    try {
      final me = _db.auth.currentUser;
      if (me == null) return;

      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', me.id);
    } catch (e) {}
  }
}
