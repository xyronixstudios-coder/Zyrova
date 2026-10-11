import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});
  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _privateAccount = false;
  bool _showActivity = true;
  bool _allowTags = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('profiles')
          .select('is_private')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _privateAccount = data?['is_private'] ?? false;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePrivate(bool value) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('profiles')
          .update({'is_private': value}).eq('id', user.id);

      setState(() => _privateAccount = value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value
                ? 'Gizli hesap açıldı'
                : 'Gizli hesap kapatıldı'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Text(t.privacy, style: TextStyle(color: AppColors.text)),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            activeColor: AppColors.primary,
            title: Text('Gizli Hesap',
                style: TextStyle(
                    color: AppColors.text, fontWeight: FontWeight.w600)),
            subtitle: Text(
                'Sadece takipçilerin videolarını görebilir',
                style: TextStyle(color: AppColors.textSecondary)),
            value: _privateAccount,
            onChanged: _togglePrivate,
          ),
          SwitchListTile(
            activeColor: AppColors.primary,
            title: Text('Aktivite Durumu',
                style: TextStyle(color: AppColors.text)),
            subtitle: Text('Çevrimiçi durumunu göster',
                style: TextStyle(color: AppColors.textSecondary)),
            value: _showActivity,
            onChanged: (v) => setState(() => _showActivity = v),
          ),
          SwitchListTile(
            activeColor: AppColors.primary,
            title: Text('Etiketlemeye İzin Ver',
                style: TextStyle(color: AppColors.text)),
            subtitle: Text('Başkaları seni etiketleyebilir',
                style: TextStyle(color: AppColors.textSecondary)),
            value: _allowTags,
            onChanged: (v) => setState(() => _allowTags = v),
          ),
        ],
      ),
    );
  }
}
