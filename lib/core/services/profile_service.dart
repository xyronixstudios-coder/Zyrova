import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  static final _db = Supabase.instance.client;
  static final _storage = Supabase.instance.client.storage;

  static Future<String?> uploadAvatar(File imageFile) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return null;

      final fileName =
          '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _storage.from('avatars').upload(fileName, imageFile);

      final url = _storage.from('avatars').getPublicUrl(fileName);

      await _db.from('profiles').update({'avatar_url': url}).eq('id', user.id);

      return url;
    } catch (e) {
      print('UploadAvatar Error: $e');
      return null;
    }
  }

  static Future<bool> updateBanner({
    required String type,
    required String color1,
    required String color2,
    required String pattern,
  }) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return false;

      await _db.from('profiles').update({
        'banner_type': type,
        'banner_color': color1,
        'banner_color2': color2,
        'banner_pattern': pattern,
      }).eq('id', user.id);

      return true;
    } catch (e) {
      print('UpdateBanner Error: $e');
      return false;
    }
  }

  static Future<bool> updateBio(String bio) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return false;

      await _db.from('profiles').update({'bio': bio}).eq('id', user.id);
      return true;
    } catch (e) {
      print('UpdateBio Error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getProfileById(String userId) async {
    try {
      final data = await _db
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      print('GetProfileById Error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getMyProfile() async {
    final user = _db.auth.currentUser;
    if (user == null) return null;
    return getProfileById(user.id);
  }

  // 🔍 KULLANICI ARAMA
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final me = _db.auth.currentUser;
      final data = await _db
          .from('profiles')
          .select()
          .ilike('username', '%$query%')
          .limit(20);

      // Kendimi hariç tut
      return (data as List)
          .where((u) => u['id'] != me?.id)
          .map((u) => Map<String, dynamic>.from(u))
          .toList();
    } catch (e) {
      print('SearchUsers Error: $e');
      return [];
    }
  }
}

// profile_service extension
extension ProfileServiceExt on ProfileService {
  static Future<bool> updatePrivate(bool isPrivate) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      await Supabase.instance.client
          .from('profiles')
          .update({'is_private': isPrivate}).eq('id', user.id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
