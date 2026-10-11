import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import 'cache_screen.dart';
import 'account_screen.dart';
import 'privacy_screen.dart';
import 'notifications_screen.dart';
import 'appearance_screen.dart';
import 'language_screen.dart';
import 'help_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Text(t.settings,
            style: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        children: [
          _i(context, Icons.person, t.account,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AccountScreen()))),
          _i(context, Icons.lock, t.privacy,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PrivacyScreen()))),
          _i(context, Icons.notifications, t.notifications,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()))),
          _i(context, Icons.storage, t.storageCache,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CacheScreen()))),
          _i(context, Icons.palette, t.appearance,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AppearanceScreen()))),
          _i(context, Icons.language, t.language,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LanguageScreen()))),
          _i(context, Icons.help_outline, t.help,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HelpScreen()))),
          _i(
              context,
              Icons.info_outline,
              '${t.about} - Zyrova v${AppConstants.version}',
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()))),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _i(BuildContext c, IconData i, String l, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print('🔥 $l → Navigator.push');
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(i, color: AppColors.text),
              const SizedBox(width: 16),
              Expanded(
                child: Text(l,
                    style: TextStyle(color: AppColors.text, fontSize: 15)),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
