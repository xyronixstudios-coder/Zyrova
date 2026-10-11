import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';

class UserVideo {
  final String id;
  final String title;
  final String caption;
  final String videoUrl;
  final String author;
  final String authorId;
  final String authorAvatar;
  final int likes;
  final int comments;
  final DateTime createdAt;
  final bool isLiked;

  UserVideo({
    required this.id,
    required this.title,
    required this.caption,
    required this.videoUrl,
    required this.author,
    required this.authorId,
    required this.authorAvatar,
    required this.likes,
    required this.comments,
    required this.createdAt,
    this.isLiked = false,
  });

  factory UserVideo.fromJson(Map<String, dynamic> json,
      {bool isLiked = false}) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return UserVideo(
      id: json['id'],
      title: json['title'] ?? '',
      caption: json['caption'] ?? '',
      videoUrl: json['video_url'] ?? '',
      author: '@${profile?['username'] ?? 'kullanici'}',
      authorId: json['user_id'] ?? '',
      authorAvatar: profile?['avatar_url'] ?? '',
      likes: json['likes_count'] ?? 0,
      comments: json['comments_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      isLiked: isLiked,
    );
  }

  UserVideo copyWith({int? likes, int? comments, bool? isLiked}) =>
      UserVideo(
        id: id,
        title: title,
        caption: caption,
        videoUrl: videoUrl,
        author: author,
        authorId: authorId,
        authorAvatar: authorAvatar,
        likes: likes ?? this.likes,
        comments: comments ?? this.comments,
        createdAt: createdAt,
        isLiked: isLiked ?? this.isLiked,
      );
}

class VideoService {
  static final _db = Supabase.instance.client;
  static final _storage = Supabase.instance.client.storage;

  // ============================================
  // 480p SIKIŞTIRMA
  // ============================================
  static Future<File?> compressVideo(File input) async {
    try {
      final outputPath = '${input.path}_480p.mp4';
      final result = await Process.run('ffmpeg', [
        '-i', input.path,
        '-vf', 'scale=-2:720,unsharp=5:5:0.8:3:3:0.4',
        '-c:v', 'libx264',
        '-preset', 'fast',
        '-crf', '28',
        '-c:a', 'aac',
        '-b:a', '96k',
        '-movflags', '+faststart',
        '-y',
        outputPath,
      ]);

      if (result.exitCode == 0 && await File(outputPath).exists()) {
        print('✅ Video 480p sıkıştırıldı');
        return File(outputPath);
      }
      return null;
    } catch (e) {
      print('CompressVideo Error: $e');
      return null;
    }
  }

  // ============================================
  // YÜKLE
  // ============================================
  static Future<UserVideo?> uploadVideo({
    required File videoFile,
    required String title,
    required String caption,
  }) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) throw Exception('Kullanici yok');

      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.mp4';
      await _storage.from('videos').upload(fileName, videoFile);
      final videoUrl = _storage.from('videos').getPublicUrl(fileName);

      final res = await _db
          .from('videos')
          .insert({
            'user_id': user.id,
            'title': title,
            'caption': caption,
            'video_url': videoUrl,
          })
          .select('*, profiles(username, avatar_url)')
          .single();

      return UserVideo.fromJson(res);
    } catch (e) {
      print('UploadVideo Error: $e');
      return null;
    }
  }

  // 🌍 KEŞFET
  static Future<List<UserVideo>> getDiscoverVideos() async {
    try {
      final user = _db.auth.currentUser;
      final data = await _db
          .from('videos')
          .select('*, profiles(username, avatar_url)')
          .order('created_at', ascending: false)
          .limit(50);

      Set<String> likedIds = {};
      if (user != null) {
        final liked = await _db
            .from('likes')
            .select('video_id')
            .eq('user_id', user.id);
        likedIds =
            (liked as List).map((e) => e['video_id'] as String).toSet();
      }

      return (data as List)
          .map((item) => UserVideo.fromJson(item,
              isLiked: likedIds.contains(item['id'])))
          .toList();
    } catch (e) {
      print('GetDiscover Error: $e');
      return [];
    }
  }

  // 👥 TAKİP
  static Future<List<UserVideo>> getFollowingVideos() async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return [];

      final following = await _db
          .from('follows')
          .select('following_id')
          .eq('follower_id', user.id);

      final ids = (following as List)
          .map((e) => e['following_id'] as String)
          .toList();
      if (ids.isEmpty) return [];

      final data = await _db
          .from('videos')
          .select('*, profiles(username, avatar_url)')
          .inFilter('user_id', ids)
          .order('created_at', ascending: false)
          .limit(50);

      final liked = await _db
          .from('likes')
          .select('video_id')
          .eq('user_id', user.id);
      final likedIds =
          (liked as List).map((e) => e['video_id'] as String).toSet();

      return (data as List)
          .map((item) => UserVideo.fromJson(item,
              isLiked: likedIds.contains(item['id'])))
          .toList();
    } catch (e) {
      print('GetFollowing Error: $e');
      return [];
    }
  }

  // 🔥 POPÜLER
  static Future<List<UserVideo>> getPopularVideos() async {
    try {
      final user = _db.auth.currentUser;
      final thirtyDaysAgo = DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String();

      final data = await _db
          .from('videos')
          .select('*, profiles(username, avatar_url)')
          .gte('created_at', thirtyDaysAgo)
          .order('likes_count', ascending: false)
          .limit(50);

      Set<String> likedIds = {};
      if (user != null) {
        final liked = await _db
            .from('likes')
            .select('video_id')
            .eq('user_id', user.id);
        likedIds =
            (liked as List).map((e) => e['video_id'] as String).toSet();
      }

      return (data as List)
          .map((item) => UserVideo.fromJson(item,
              isLiked: likedIds.contains(item['id'])))
          .toList();
    } catch (e) {
      print('GetPopular Error: $e');
      return [];
    }
  }

  // KENDİ VİDEOLARIM
  static Future<List<UserVideo>> getMyVideos() async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return [];

      final data = await _db
          .from('videos')
          .select('*, profiles(username, avatar_url)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => UserVideo.fromJson(item))
          .toList();
    } catch (e) {
      print('GetMyVideos Error: $e');
      return [];
    }
  }

  // BELİRLİ KULLANICININ VİDEOLARI
  static Future<List<UserVideo>> getUserVideos(String userId) async {
    try {
      final data = await _db
          .from('videos')
          .select('*, profiles(username, avatar_url)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => UserVideo.fromJson(item))
          .toList();
    } catch (e) {
      print('GetUserVideos Error: $e');
      return [];
    }
  }

  static Future<List<UserVideo>> getVideos() => getDiscoverVideos();

  static Future<void> deleteVideo(String id, String videoUrl) async {
    try {
      final path = videoUrl.split('/videos/').last;
      await _storage.from('videos').remove([path]);
      await _db.from('videos').delete().eq('id', id);
    } catch (e) {
      print('DeleteVideo Error: $e');
    }
  }

  static Future<Directory> getVideoDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${dir.path}/zyrova_videos');
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }
    return videoDir;
  }
}
