import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/locale_provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  final langs = const [
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Text('${t.language} / Language',
            style: TextStyle(color: AppColors.text)),
      ),
      body: ListView(
        children: langs.map((l) {
          final selected = locale.locale.languageCode == l['code'];
          return Material(
            color: Colors.transparent,
            child: ListTile(
              leading: Text(l['flag']!,
                  style: const TextStyle(fontSize: 28)),
              title: Text(l['name']!,
                  style: TextStyle(color: AppColors.text)),
              trailing: selected
                  ? Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => locale.setLocale(l['code']!),
            ),
          );
        }).toList(),
      ),
    );
  }
}
