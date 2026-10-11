import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Text(t.about, style: TextStyle(color: AppColors.text)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/zyrova-logo.png',
                    width: 100, height: 100,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text('Z',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 56,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Zyrova',
                    style: TextStyle(
                        color: AppColors.text,
                        fontSize: 28,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(t.tagline,
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('${t.version} ${AppConstants.version}',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(t.producer,
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _tile(t.studio, 'Xyronix Studios'),
          _tile(t.developer, 'Eren Mut'),
          const SizedBox(height: 24),
          Text(t.aboutApp,
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _tile(t.license, 'MIT'),
          _tile(t.technology, 'Flutter + Supabase'),
          _tile(t.storageCache, '200 MB'),
          const SizedBox(height: 24),
          Text(t.contact,
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _linkTile(context, t.gmail, 'xyronixstudios@gmail.com',
              'mailto:xyronixstudios@gmail.com'),
          _linkTile(context, t.webSite, 'xyronix-os-hub',
              'https://xyronixstudios-coder.github.io/xyronix-os-hub/'),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Text('© 2026 Xyronix Studios',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(t.allRightsReserved,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(String l, String v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: TextStyle(color: AppColors.textSecondary)),
          Text(v,
              style: TextStyle(
                  color: AppColors.text, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _linkTile(BuildContext c, String l, String v, String url) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          title: Text(l,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          subtitle: Text(v,
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600)),
          trailing: Icon(Icons.open_in_new,
              color: AppColors.primary, size: 18),
          onTap: () => _launch(url),
        ),
      ),
    );
  }
}
