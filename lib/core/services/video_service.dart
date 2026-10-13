import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class UserVideo {
  final String id;
  final String title;
  final String caption;
  final String videoUrl;
  final String thumbnailUrl;
  final String musicUrl;
  final String musicName;
  final String author;
  final String authorId;
  final String authorAvatar;
  final int likes;
  final int comments;
  final DateTime createdAt;
  final bool isLiked;
  final bool isStory;
  final bool isImage;

  UserVideo({
    required this.id,
    required this.title,
    required this.caption,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.musicUrl,
    required this.musicName,
    required this.author,
    required this.authorId,
    required this.authorAvatar,
    required this.likes,
    required this.comments,
    required this.createdAt,
    this.isLiked = false,
    this.isStory = false,
    this.isImage = false,
  });

  factory UserVideo.fromJson(Map<String, dynamic> json,
      {bool isLiked = false}) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return UserVideo(
      id: json['id'],
      title: json['title'] ?? '',
      caption: json['caption'] ?? '',
      videoUrl: json['video_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      musicUrl: json['music_url'] ?? '',
      musicName: json['music_name'] ?? '',
      author: '@${profile?['username'] ?? 'kullanici'}',
      authorId: json['user_id'] ?? '',
      authorAvatar: profile?['avatar_url'] ?? '',
      likes: json['likes_count'] ?? 0,
      comments: json['comments_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      isLiked: isLiked,
      isStory: json['is_story'] ?? false,
      isImage: json['is_image'] ?? false,
    );
  }

  UserVideo copyWith({int? likes, int? comments, bool? isLiked}) =>
      UserVideo(
        id: id,
        title: title,
        caption: caption,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        musicUrl: musicUrl,
        musicName: musicName,
        author: author,
        authorId: authorId,
        authorAvatar: authorAvatar,
        likes: likes ?? this.likes,
        comments: comments ?? this.comments,
        createdAt: createdAt,
        isLiked: isLiked ?? this.isLiked,
        isStory: isStory,
        isImage: isImage,
      );
}

class VideoService {
  static String? get currentUserId => _db.auth.currentUser?.id;
  static final _db = Supabase.instance.client;
  static final _storage = Supabase.instance.client.storage;

  // OTOMATİK KAPAK
  static Future<File?> generateThumbnail(File videoFile) async {
    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final bytes = await VideoThumbnail.thumbnailData(
        video: videoFile.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 480,
        quality: 75,
        timeMs: 500,
      );

      if (bytes == null) return null;

      final file = File(path);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      print('GenerateThumbnail Error: $e');
      return null;
    }
  }

  // 480p SIKIŞTIRMA
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
        return File(outputPath);
      }
      return null;
    } catch (e) {
      print('CompressVideo Error: $e');
      return null;
    }
  }

  // 🎵 MÜZİK EKLE
  static Future<File?> addMusicToVideo({
    required File video,
    required File music,
    double videoVolume = 0.2,
    double musicVolume = 1.0,
  }) async {
    try {
      final outputPath =
          '${video.path}_music_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // FFmpeg komutu — video sesini kıs, müziği ekle, ikisini birleştir
      final result = await Process.run('ffmpeg', [
        '-i', video.path,
        '-i', music.path,
        '-filter_complex',
        '[0:a]volume=$videoVolume[va];[1:a]volume=$musicVolume[ma];[va][ma]amix=inputs=2:duration=first:dropout_transition=0[aout]',
        '-map', '0:v',
        '-map', '[aout]',
        '-c:v', 'copy',
        '-c:a', 'aac',
        '-b:a', '128k',
        '-shortest',
        '-movflags', '+faststart',
        '-y',
        outputPath,
      ]);

      if (result.exitCode == 0 && await File(outputPath).exists()) {
        print('✅ Müzik eklendi');
        return File(outputPath);
      } else {
        print('FFmpeg stderr: ${result.stderr}');
      }
      return null;
    } catch (e) {
      print('AddMusic Error: $e');
      return null;
    }
  }

  // YÜKLE
  static Future<UserVideo?> uploadVideo({
    required File videoFile,
    required String title,
    required String caption,
    File? customCover,
    File? musicFile,
    bool isStory = false,
    bool isImage = false,
  }) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) throw Exception('Kullanici yok');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      File finalFile = videoFile;

      // 1. Müzik ekle (resim değilse ve müzik varsa)
      if (musicFile != null && !isImage) {
        print('🎵 Müzik birleştiriliyor...');
        final withMusic = await addMusicToVideo(
          video: finalFile,
          music: musicFile,
        );
        if (withMusic != null) {
          finalFile = withMusic;
        } else {
          print('⚠️ Müzik eklenemedi, video orijinal haliyle yüklenecek');
        }
      }

      // 2. Medya yükle
      final ext = isImage
          ? videoFile.path.split('.').last.toLowerCase()
          : 'mp4';
      final mediaName = '${user.id}/$timestamp.$ext';
      await _storage.from('videos').upload(mediaName, finalFile);
      final videoUrl = _storage.from('videos').getPublicUrl(mediaName);

      // 3. Müzik dosyasını da storage'a yükle
      String musicUrl = '';
      String musicName = '';
      if (musicFile != null) {
        try {
          final musicExt = musicFile.path.split('.').last.toLowerCase();
          final mName = '${user.id}/${timestamp}_music.$musicExt';
          await _storage.from('music').upload(mName, musicFile);
          musicUrl = _storage.from('music').getPublicUrl(mName);
          musicName = musicFile.path.split('/').last;
        } catch (e) {
          print('Music upload error: $e');
        }
      }

      // 4. Kapak yükle
      String thumbnailUrl = '';
      try {
        File? coverToUpload = customCover;
        if (coverToUpload == null && !isImage) {
          coverToUpload = await generateThumbnail(finalFile);
        }
        if (coverToUpload != null) {
          final thumbName = '${user.id}/$timestamp.jpg';
          await _storage
              .from('thumbnails')
              .upload(thumbName, coverToUpload);
          thumbnailUrl =
              _storage.from('thumbnails').getPublicUrl(thumbName);
          if (customCover == null && !isImage) {
            try {
              await coverToUpload.delete();
            } catch (_) {}
          }
        } else if (isImage) {
          thumbnailUrl = videoUrl;
        }
      } catch (e) {
        print('Cover upload error: $e');
      }

      // 5. DB'ye kaydet
      final insertData = <String, dynamic>{
        'user_id': user.id,
        'title': title,
        'caption': caption,
        'video_url': videoUrl,
        'thumbnail_url': thumbnailUrl,
        'music_url': musicUrl,
        'music_name': musicName,
        'is_story': isStory,
        'is_image': isImage,
      };
      if (isStory) {
        insertData['story_expires_at'] = DateTime.now()
            .add(const Duration(hours: 24))
            .toUtc()
            .toIso8601String();
      }

      final res = await _db
          .from('videos')
          .insert(insertData)
          .select('*, profiles(username, avatar_url)')
          .single();

      // Geçici dosyayı sil
      try {
        if (finalFile.path != videoFile.path) {
          await finalFile.delete();
        }
      } catch (_) {}

      return UserVideo.fromJson(res);
    } catch (e) {
      print('UploadVideo Error: $e');
      return null;
    }
  }

  // FEED'LER
  static Future<List<UserVideo>> getDiscoverVideos() async {
    try {
      final user = _db.auth.currentUser;
      final data = await _db
          .from('videos')
          .select('*, profiles(username, avatar_url)')
          .or('is_story.eq.false,is_story.is.null')
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
          .or('is_story.eq.false,is_story.is.null')
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
          .or('is_story.eq.false,is_story.is.null')
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

  static Future<List<UserVideo>> getStories() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final data = await _db
          .from('videos')
          .select('*, profiles(username, avatar_url)')
          .eq('is_story', true)
          .gt('story_expires_at', now)
          .order('created_at', ascending: false)
          .limit(50);

      return (data as List)
          .map((item) => UserVideo.fromJson(item))
          .toList();
    } catch (e) {
      print('GetStories Error: $e');
      return [];
    }
  }

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
