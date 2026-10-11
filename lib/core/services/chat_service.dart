import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatModel {
  final String id;
  final String otherUserId;
  final String otherUsername;
  final String otherAvatar;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  ChatModel({
    required this.id,
    required this.otherUserId,
    required this.otherUsername,
    required this.otherAvatar,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.imageUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
        id: j['id'],
        chatId: j['chat_id'],
        senderId: j['sender_id'],
        content: j['content'] ?? '',
        imageUrl: j['image_url'],
        isRead: j['is_read'] ?? false,
        createdAt: DateTime.parse(j['created_at']).toLocal(),
      );
}

class FriendModel {
  final String userId;
  final String username;
  final String avatarUrl;

  FriendModel({
    required this.userId,
    required this.username,
    required this.avatarUrl,
  });
}

class ChatService {
  static final _db = Supabase.instance.client;
  static final _storage = Supabase.instance.client.storage;

  static Future<bool> isFriend(String otherUserId) async {
    try {
      final me = _db.auth.currentUser;
      if (me == null || me.id == otherUserId) return false;

      final f1 = await _db
          .from('follows')
          .select('id')
          .eq('follower_id', me.id)
          .eq('following_id', otherUserId)
          .maybeSingle();

      final f2 = await _db
          .from('follows')
          .select('id')
          .eq('follower_id', otherUserId)
          .eq('following_id', me.id)
          .maybeSingle();

      return f1 != null && f2 != null;
    } catch (e) {
      return false;
    }
  }

  static Future<List<FriendModel>> getMyFriends() async {
    try {
      final me = _db.auth.currentUser;
      if (me == null) return [];

      final following = await _db
          .from('follows')
          .select('following_id')
          .eq('follower_id', me.id);
      final followingIds =
          (following as List).map((e) => e['following_id'] as String).toList();
      if (followingIds.isEmpty) return [];

      final followers = await _db
          .from('follows')
          .select('follower_id')
          .eq('following_id', me.id)
          .inFilter('follower_id', followingIds);
      final friendIds =
          (followers as List).map((e) => e['follower_id'] as String).toList();
      if (friendIds.isEmpty) return [];

      final profiles = await _db
          .from('profiles')
          .select('id, username, avatar_url')
          .inFilter('id', friendIds);

      return (profiles as List)
          .map((p) => FriendModel(
                userId: p['id'],
                username: p['username'] ?? 'kullanici',
                avatarUrl: p['avatar_url'] ?? '',
              ))
          .toList();
    } catch (e) {
      print('GetMyFriends Error: $e');
      return [];
    }
  }

  static Future<String?> getOrCreateChat(String otherUserId) async {
    try {
      final me = _db.auth.currentUser;
      if (me == null || me.id == otherUserId) return null;
      if (!await isFriend(otherUserId)) return null;

      final ids = [me.id, otherUserId]..sort();
      final u1 = ids[0];
      final u2 = ids[1];

      final existing = await _db
          .from('chats')
          .select('id')
          .eq('user1_id', u1)
          .eq('user2_id', u2)
          .maybeSingle();
      if (existing != null) return existing['id'];

      final created = await _db
          .from('chats')
          .insert({'user1_id': u1, 'user2_id': u2})
          .select('id')
          .single();
      return created['id'];
    } catch (e) {
      print('GetOrCreateChat Error: $e');
      return null;
    }
  }

  // Metin mesajı
  static Future<bool> sendMessage(String chatId, String content) async {
    try {
      final me = _db.auth.currentUser;
      if (me == null || content.trim().isEmpty) return false;

      await _db.from('messages').insert({
        'chat_id': chatId,
        'sender_id': me.id,
        'content': content.trim(),
      });

      await _db.from('chats').update({
        'last_message': content.trim(),
        'last_message_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', chatId);
      return true;
    } catch (e) {
      print('SendMessage Error: $e');
      return false;
    }
  }

  // Fotoğraf mesajı
  static Future<bool> sendImageMessage(
      String chatId, File imageFile) async {
    try {
      final me = _db.auth.currentUser;
      if (me == null) return false;

      final fileName =
          '${me.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _storage.from('messages').upload(fileName, imageFile);
      final url = _storage.from('messages').getPublicUrl(fileName);

      await _db.from('messages').insert({
        'chat_id': chatId,
        'sender_id': me.id,
        'content': '📷 Fotoğraf',
        'image_url': url,
      });

      await _db.from('chats').update({
        'last_message': '📷 Fotoğraf',
        'last_message_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', chatId);
      return true;
    } catch (e) {
      print('SendImageMessage Error: $e');
      return false;
    }
  }

  // Mesaj sil
  static Future<bool> deleteMessage(String messageId) async {
    try {
      await _db.from('messages').delete().eq('id', messageId);
      return true;
    } catch (e) {
      print('DeleteMessage Error: $e');
      return false;
    }
  }

  static Future<List<MessageModel>> getMessages(String chatId) async {
    try {
      final data = await _db
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: true)
          .limit(100);
      return (data as List)
          .map((m) => MessageModel.fromJson(m))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<ChatModel>> getMyChats() async {
    try {
      final me = _db.auth.currentUser;
      if (me == null) return [];

      final data = await _db
          .from('chats')
          .select('*')
          .or('user1_id.eq.${me.id},user2_id.eq.${me.id}')
          .order('last_message_at', ascending: false);

      final List<ChatModel> chats = [];
      for (final c in (data as List)) {
        final otherId =
            c['user1_id'] == me.id ? c['user2_id'] : c['user1_id'];
        final profile = await _db
            .from('profiles')
            .select('username, avatar_url')
            .eq('id', otherId)
            .maybeSingle();
        final unread = await _db
            .from('messages')
            .select('id')
            .eq('chat_id', c['id'])
            .neq('sender_id', me.id)
            .eq('is_read', false);

        final parsed = DateTime.tryParse(c['last_message_at'] ?? '');
        final localTime = parsed?.toLocal() ?? DateTime.now();

        chats.add(ChatModel(
          id: c['id'],
          otherUserId: otherId,
          otherUsername: profile?['username'] ?? 'kullanici',
          otherAvatar: profile?['avatar_url'] ?? '',
          lastMessage: c['last_message'] ?? '',
          lastMessageAt: localTime,
          unreadCount: (unread as List).length,
        ));
      }
      return chats;
    } catch (e) {
      print('GetMyChats Error: $e');
      return [];
    }
  }

  static Future<void> markAsRead(String chatId) async {
    try {
      final me = _db.auth.currentUser;
      if (me == null) return;
      await _db
          .from('messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .neq('sender_id', me.id);
    } catch (e) {}
  }
}
