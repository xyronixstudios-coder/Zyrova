import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Text(t.help, style: TextStyle(color: AppColors.text)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t.faq,
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              iconColor: AppColors.primary,
              collapsedIconColor: AppColors.textSecondary,
              title: Text('Video?',
                  style: TextStyle(
                      color: AppColors.text, fontWeight: FontWeight.w600)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(t.uploadFirst,
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(t.contact,
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: ListTile(
              leading: Icon(Icons.email, color: AppColors.primary),
              title: Text('xyronixstudios@gmail.com',
                  style: TextStyle(color: AppColors.text)),
            ),
          ),
        ],
      ),
    );
  }
}
