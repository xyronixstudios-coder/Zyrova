import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotifModel {
  final String id;
  final String type;
  final String actorUsername;
  final String actorAvatar;
  final String actorId;
  final String? videoId;
  final bool isRead;
  final DateTime createdAt;

  NotifModel({
    required this.id,
    required this.type,
    required this.actorUsername,
    required this.actorAvatar,
    required this.actorId,
    this.videoId,
    required this.isRead,
    required this.createdAt,
  });
}

class NotificationService {
  static final _db = Supabase.instance.client;

  // Tüm bildirimlerim
  static Future<List<NotifModel>> getMyNotifications() async {
    try {
      final me = _db.auth.currentUser;
      if (me == null) return [];

      final data = await _db
          .from('notifications')
          .select(
              '*, actor:profiles!notifications_actor_id_fkey(id, username, avatar_url)')
          .eq('user_id', me.id)
          .order('created_at', ascending: false)
          .limit(50);

      return (data as List).map((n) {
        final actor = n['actor'] as Map<String, dynamic>?;
        return NotifModel(
          id: n['id'],
          type: n['type'] ?? 'unknown',
          actorUsername: actor?['username'] ?? 'kullanici',
          actorAvatar: actor?['avatar_url'] ?? '',
          actorId: actor?['id'] ?? n['actor_id'] ?? '',
          videoId: n['video_id'],
          isRead: n['is_read'] ?? false,
          createdAt: DateTime.parse(n['created_at']).toLocal(),
        );
      }).toList();
    } catch (e) {
      print('GetNotifications Error: $e');
      return [];
    }
  }

  // Okunmamış sayısı
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

  // Tümünü okundu yap
  static Future<void> markAllRead() async {
    try {
      final me = _db.auth.currentUser;
      if (me == null) return;

      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', me.id);
    } catch (e) {
      print('markAllRead Error: $e');
    }
  }

  // Tek bir bildirimi okundu yap
  static Future<void> markRead(String notifId) async {
    try {
      await _db
          .from('notifications')
          .update({'is_read': true}).eq('id', notifId);
    } catch (e) {}
  }

  // 🔥 REALTIME: Yeni bildirimleri dinle
  static RealtimeChannel subscribeToMyNotifications(
    void Function(NotifModel) onNewNotification,
  ) {
    final me = _db.auth.currentUser;
    if (me == null) throw Exception('Not logged in');

    final channel = _db.channel('notifs_${me.id}');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: me.id,
          ),
          callback: (payload) async {
            try {
              // Actor profile'ını da çek
              final actorId = payload.newRecord['actor_id'] as String?;
              Map<String, dynamic>? actor;
              if (actorId != null) {
                actor = await _db
                    .from('profiles')
                    .select('id, username, avatar_url')
                    .eq('id', actorId)
                    .maybeSingle();
              }

              final notif = NotifModel(
                id: payload.newRecord['id'],
                type: payload.newRecord['type'] ?? 'unknown',
                actorUsername: actor?['username'] ?? 'kullanici',
                actorAvatar: actor?['avatar_url'] ?? '',
                actorId: actorId ?? '',
                videoId: payload.newRecord['video_id'],
                isRead: false,
                createdAt: DateTime.now(),
              );
              onNewNotification(notif);
            } catch (e) {
              print('Realtime notif parse error: $e');
            }
          },
        )
        .subscribe();
    return channel;
  }
}
