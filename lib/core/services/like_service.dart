import 'package:supabase_flutter/supabase_flutter.dart';

class LikeService {
  static final _db = Supabase.instance.client;

  // Beğeni ekle (duplicate koruması ile)
  static Future<bool> likeVideo(String videoId) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return false;

      // 🔥 Zaten beğenmiş mi?
      final existing = await _db
          .from('likes')
          .select('id')
          .eq('user_id', user.id)
          .eq('video_id', videoId)
          .maybeSingle();

      if (existing != null) {
        print('Already liked');
        return true;
      }

      await _db.from('likes').insert({
        'user_id': user.id,
        'video_id': videoId,
      });
      return true;
    } catch (e) {
      print('LikeVideo Error: $e');
      return false;
    }
  }

  // Beğeniyi geri al
  static Future<bool> unlikeVideo(String videoId) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return false;

      await _db
          .from('likes')
          .delete()
          .eq('user_id', user.id)
          .eq('video_id', videoId);
      return true;
    } catch (e) {
      print('UnlikeVideo Error: $e');
      return false;
    }
  }

  // Beğendi mi?
  static Future<bool> hasLiked(String videoId) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return false;

      final res = await _db
          .from('likes')
          .select()
          .eq('user_id', user.id)
          .eq('video_id', videoId)
          .maybeSingle();

      return res != null;
    } catch (e) {
      print('HasLiked Error: $e');
      return false;
    }
  }

  // Beğeni sayısı
  static Future<int> getLikeCount(String videoId) async {
    try {
      final res = await _db
          .from('likes')
          .select('id')
          .eq('video_id', videoId);

      return (res as List).length;
    } catch (e) {
      print('GetLikeCount Error: $e');
      return 0;
    }
  }
}
