import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _auth = Supabase.instance.client.auth;
  static final _db = Supabase.instance.client;

  // ============================================
  // GÜVENLİK SORULARI (sabit liste)
  // ============================================
  static const List<String> securityQuestions = [
    'İlk evcil hayvanının adı neydi?',
    'Annenin kızlık soyadı nedir?',
    'İlk gittiğin okulun adı nedir?',
    'En sevdiğin çocukluk arkadaşının adı?',
    'Doğduğun şehir hangisi?',
    'İlk arabanın markası neydi?',
    'En sevdiğin yemek nedir?',
    'İlk iş yerin neresiydi?',
  ];

  // ============================================
  // KAYIT OL
  // ============================================
  static Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String username,
    required String securityQuestion,
    required String securityAnswer,
    String languageCode = 'tr',
  }) async {
    try {
      // Kullanıcı adı benzersiz mi?
      final exists = await isUsernameTaken(username);
      if (exists) {
        throw Exception('Bu kullanıcı adı zaten alınmış');
      }

      final res = await _auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'language': languageCode,
          'security_question': securityQuestion,
          'security_answer': securityAnswer.trim().toLowerCase(),
        },
        emailRedirectTo: 'io.supabase.zyrova://login-callback/',
      );

      // 🔥 Profile tablosuna güvenlik bilgilerini de yaz
      if (res.user != null) {
        try {
          await _db.from('profiles').update({
            'security_question': securityQuestion,
            'security_answer': securityAnswer.trim().toLowerCase(),
          }).eq('id', res.user!.id);
        } catch (e) {
          print('Profile security update error: $e');
        }
      }

      return res;
    } catch (e) {
      print('SignUp Error: $e');
      rethrow;
    }
  }

  // ============================================
  // KULLANICI ADI BENZERSİZ Mİ?
  // ============================================
  static Future<bool> isUsernameTaken(String username) async {
    try {
      final res = await _db
          .from('profiles')
          .select('id')
          .ilike('username', username.trim())
          .maybeSingle();
      return res != null;
    } catch (e) {
      print('isUsernameTaken Error: $e');
      return false;
    }
  }

  // ============================================
  // KULLANICI ADI DEĞİŞTİR
  // ============================================
  static Future<bool> updateUsername(String newUsername) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final trimmed = newUsername.trim();
      if (trimmed.length < 3) throw Exception('En az 3 karakter');
      if (trimmed.length > 20) throw Exception('En fazla 20 karakter');

      final regex = RegExp(r'^[a-zA-Z0-9_.]+$');
      if (!regex.hasMatch(trimmed)) {
        throw Exception('Sadece harf, rakam, _ ve . kullanabilirsin');
      }

      final currentProfile = await _db
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .maybeSingle();

      if (currentProfile != null &&
          (currentProfile['username'] as String).toLowerCase() ==
              trimmed.toLowerCase()) {
        return true;
      }

      final taken = await isUsernameTaken(trimmed);
      if (taken) throw Exception('Bu kullanıcı adı zaten alınmış');

      await _db
          .from('profiles')
          .update({'username': trimmed}).eq('id', user.id);

      return true;
    } catch (e) {
      print('UpdateUsername Error: $e');
      rethrow;
    }
  }

  // ============================================
  // 🔥 GÜVENLİK SORUSU: Email'den soruyu al
  // ============================================
  static Future<String?> getSecurityQuestion(String email) async {
    try {
      // auth.users tablosundan user_id al
      final res = await _db
          .rpc('get_security_question_by_email', params: {'user_email': email});

      if (res != null && res is List && res.isNotEmpty) {
        return res[0]['security_question'] as String?;
      }
      return null;
    } catch (e) {
      print('GetSecurityQuestion Error: $e');
      return null;
    }
  }

  // ============================================
  // 🔥 GÜVENLİK SORUSU: Cevabı doğrula
  // ============================================
  static Future<bool> verifySecurityAnswer({
    required String email,
    required String answer,
  }) async {
    try {
      final res = await _db.rpc(
        'verify_security_answer',
        params: {
          'user_email': email,
          'user_answer': answer.trim().toLowerCase(),
        },
      );
      return res == true;
    } catch (e) {
      print('VerifySecurityAnswer Error: $e');
      return false;
    }
  }

  // ============================================
  // 🔥 GÜVENLİK SORUSU: Yeni şifre belirle
  // ============================================
  static Future<bool> resetPasswordWithSecurity({
    required String email,
    required String newPassword,
  }) async {
    try {
      // Not: Bu admin fonksiyonu gerektirir — aşağıdaki RPC ile yapıyoruz
      final res = await _db.rpc(
        'reset_password_with_security',
        params: {
          'user_email': email,
          'new_password': newPassword,
        },
      );
      return res == true;
    } catch (e) {
      print('ResetPasswordWithSecurity Error: $e');
      rethrow;
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
  // EMAIL DOĞRULAMA TEKRAR GÖNDER
  // ============================================
  static Future<bool> resendVerificationEmail(String email) async {
    try {
      await _auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: 'io.supabase.zyrova://login-callback/',
      );
      return true;
    } catch (e) {
      print('Resend Verification Error: $e');
      return false;
    }
  }

  // ============================================
  // ŞİFRE SIFIRLAMA EMAIL GÖNDER (yedek)
  // ============================================
  static Future<bool> sendPasswordReset(String email) async {
    try {
      await _auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.zyrova://reset-password/',
      );
      return true;
    } catch (e) {
      print('SendPasswordReset Error: $e');
      return false;
    }
  }

  // ============================================
  // YENİ ŞİFRE BELİRLE (deep link sonrası)
  // ============================================
  static Future<bool> updatePassword(String newPassword) async {
    try {
      if (newPassword.length < 6) {
        throw Exception('Şifre en az 6 karakter olmalı');
      }
      await _auth.updateUser(UserAttributes(password: newPassword));
      return true;
    } catch (e) {
      print('UpdatePassword Error: $e');
      rethrow;
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
  static bool get isEmailVerified =>
      _auth.currentUser?.emailConfirmedAt != null;

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
