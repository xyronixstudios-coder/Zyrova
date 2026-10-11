import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  String _theme = 'dark';
  String _accent = '#1E90FF';

  String get theme => _theme;
  String get accent => _accent;
  bool get isDark => _theme == 'dark';

  Color get accentColor {
    final hex = _accent.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _theme = p.getString('theme') ?? 'dark';
    _accent = p.getString('accent') ?? '#1E90FF';
    notifyListeners();
  }

  Future<void> setTheme(String value) async {
    _theme = value;
    final p = await SharedPreferences.getInstance();
    await p.setString('theme', value);
    notifyListeners();
  }

  Future<void> setAccent(String value) async {
    _accent = value;
    final p = await SharedPreferences.getInstance();
    await p.setString('accent', value);
    notifyListeners();
  }
}
