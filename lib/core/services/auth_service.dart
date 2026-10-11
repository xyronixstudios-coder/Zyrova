import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _auth = Supabase.instance.client.auth;
  static final _db = Supabase.instance.client;

  // ============================================
  // KAYIT OL (Trigger otomatik profil oluşturur)
  // ============================================
  static Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final res = await _auth.signUp(
        email: email,
        password: password,
        data: {'username': username},  // metadata'ya ekle
      );
      return res;
    } catch (e) {
      print('SignUp Error: $e');
      return null;
    }
  }

  // ============================================
  // GİRİŞ YAP
  // ============================================
  static Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('SignIn Error: $e');
      return null;
    }
  }

  // ============================================
  // ÇIKIŞ YAP
  // ============================================
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // ============================================
  // MEVCUT KULLANICI
  // ============================================
  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;

  // ============================================
  // PROFİL BİLGİSİ
  // ============================================
  static Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await _db
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return data;
    } catch (e) {
      print('GetProfile Error: $e');
      return null;
    }
  }
}
