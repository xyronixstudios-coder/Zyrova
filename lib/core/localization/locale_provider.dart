import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('tr');

  Locale get locale => _locale;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString('language');

    if (saved != null) {
      // Kullanıcı daha önce dil seçmiş → onu kullan
      _locale = Locale(saved);
    } else {
      // İlk açılış → cihaz dilini al
      final deviceLang =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      _locale = deviceLang == 'tr' ? const Locale('tr') : const Locale('en');
    }
    notifyListeners();
  }

  Future<void> setLocale(String code) async {
    _locale = Locale(code);
    final p = await SharedPreferences.getInstance();
    await p.setString('language', code);
    notifyListeners();
  }
}
