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

  Future<void> _togglePrivate(bool value, AppStrings t) async {
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
            content: Text(
                value ? t.privateAccountOn : t.privateAccountOff),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.error}: $e'),
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
            title: Text(t.privateAccount,
                style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600)),
            subtitle: Text(t.privateAccountDesc,
                style: TextStyle(color: AppColors.textSecondary)),
            value: _privateAccount,
            onChanged: (v) => _togglePrivate(v, t),
          ),
          SwitchListTile(
            activeColor: AppColors.primary,
            title: Text(t.activityStatus,
                style: TextStyle(color: AppColors.text)),
            subtitle: Text(t.activityStatusDesc,
                style: TextStyle(color: AppColors.textSecondary)),
            value: _showActivity,
            onChanged: (v) => setState(() => _showActivity = v),
          ),
          SwitchListTile(
            activeColor: AppColors.primary,
            title: Text(t.allowTags,
                style: TextStyle(color: AppColors.text)),
            subtitle: Text(t.allowTagsDesc,
                style: TextStyle(color: AppColors.textSecondary)),
            value: _allowTags,
            onChanged: (v) => setState(() => _allowTags = v),
          ),
        ],
      ),
    );
  }
}
