import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeepLinkService {
  static final _appLinks = AppLinks();
  static StreamSubscription? _sub;

  // Callback'ler — main.dart set eder
  static void Function(String? code)? onPasswordReset;
  static void Function()? onEmailVerified;

  static Future<void> init() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (e) {
      print('InitialLink Error: $e');
    }

    _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen(_handle, onError: (e) {
      print('Link Stream Error: $e');
    });
  }

  static Future<void> _handle(Uri uri) async {
    print('🔗 DEEP LINK: $uri');

    // Email doğrulama callback
    if (uri.host == 'login-callback' ||
        uri.path.contains('login-callback')) {
      await _exchangeCode(uri);
      onEmailVerified?.call();
      return;
    }

    // Şifre sıfırlama callback
    if (uri.host == 'reset-password' ||
        uri.path.contains('reset-password')) {
      final code = uri.queryParameters['code'];
      if (code != null) {
        try {
          await Supabase.instance.client.auth
              .exchangeCodeForSession(code);
        } catch (e) {
          print('ExchangeCode Error: $e');
        }
      }
      onPasswordReset?.call(code);
      return;
    }
  }

  static Future<void> _exchangeCode(Uri uri) async {
    final code = uri.queryParameters['code'];
    if (code == null) return;
    try {
      await Supabase.instance.client.auth.exchangeCodeForSession(code);
    } catch (e) {
      print('ExchangeCode (login) Error: $e');
    }
  }

  static void dispose() {
    _sub?.cancel();
  }
}
