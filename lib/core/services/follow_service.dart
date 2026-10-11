import 'package:supabase_flutter/supabase_flutter.dart';

class FollowService {
  static final _db = Supabase.instance.client;

  static Future<bool> follow(String userId) async {
    try {
      final me = _db.auth.currentUser;
      if (me == null || me.id == userId) return false;

      await _db.from('follows').insert({
        'follower_id': me.id,
        'following_id': userId,
      });
      return true;
    } catch (e) {
      print('Follow Error: $e');
      return false;
    }
  }

  static Future<bool> unfollow(String userId) async {
    try {
      final me = _db.auth.currentUser;
      if (me == null) return false;

      await _db
          .from('follows')
          .delete()
          .eq('follower_id', me.id)
          .eq('following_id', userId);
      return true;
    } catch (e) {
      print('Unfollow Error: $e');
      return false;
    }
  }

  static Future<bool> isFollowing(String userId) async {
    try {
      final me = _db.auth.currentUser;
      if (me == null) return false;

      final res = await _db
          .from('follows')
          .select()
          .eq('follower_id', me.id)
          .eq('following_id', userId)
          .maybeSingle();
      return res != null;
    } catch (e) {
      return false;
    }
  }

  static Future<List<String>> getFollowingIds() async {
    try {
      final me = _db.auth.currentUser;
      if (me == null) return [];

      final res = await _db
          .from('follows')
          .select('following_id')
          .eq('follower_id', me.id);

      return (res as List)
          .map((e) => e['following_id'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Belirli kullanıcının takipçileri
  static Future<List<String>> getFollowersIds(String userId) async {
    try {
      final res = await _db
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId);
      return (res as List)
          .map((e) => e['follower_id'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Belirli kullanıcının takip ettikleri
  static Future<List<String>> getFollowingIdsOf(String userId) async {
    try {
      final res = await _db
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);
      return (res as List)
          .map((e) => e['following_id'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, int>> getCounts(String userId) async {
    try {
      final followers = await _db
          .from('follows')
          .select('id')
          .eq('following_id', userId);
      final following = await _db
          .from('follows')
          .select('id')
          .eq('follower_id', userId);

      return {
        'followers': (followers as List).length,
        'following': (following as List).length,
      };
    } catch (e) {
      return {'followers': 0, 'following': 0};
    }
  }
}
