import 'package:supabase_flutter/supabase_flutter.dart';

class Comment {
  final String id;
  final String userId;
  final String videoId;
  final String content;
  final String author;
  final String authorAvatar;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.videoId,
    required this.content,
    required this.author,
    required this.authorAvatar,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return Comment(
      id: json['id'],
      userId: json['user_id'],
      videoId: json['video_id'],
      content: json['content'] ?? '',
      author: '@${profile?['username'] ?? 'kullanici'}',
      authorAvatar: profile?['avatar_url'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class CommentService {
  static final _db = Supabase.instance.client;

  // Yorum ekle
  static Future<Comment?> addComment({
    required String videoId,
    required String content,
  }) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return null;

      final res = await _db
          .from('comments')
          .insert({
            'user_id': user.id,
            'video_id': videoId,
            'content': content,
          })
          .select('*, profiles(username, avatar_url)')
          .single();

      return Comment.fromJson(res);
    } catch (e) {
      print('AddComment Error: $e');
      return null;
    }
  }

  // Yorumları çek
  static Future<List<Comment>> getComments(String videoId) async {
    try {
      final data = await _db
          .from('comments')
          .select('*, profiles(username, avatar_url)')
          .eq('video_id', videoId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => Comment.fromJson(item))
          .toList();
    } catch (e) {
      print('GetComments Error: $e');
      return [];
    }
  }

  // Yorum sil
  static Future<bool> deleteComment(String commentId) async {
    try {
      await _db.from('comments').delete().eq('id', commentId);
      return true;
    } catch (e) {
      print('DeleteComment Error: $e');
      return false;
    }
  }

  // Yorum sayısı
  static Future<int> getCommentCount(String videoId) async {
    try {
      final res = await _db
          .from('comments')
          .select('id')
          .eq('video_id', videoId);
      return (res as List).length;
    } catch (e) {
      print('GetCommentCount Error: $e');
      return 0;
    }
  }
}
