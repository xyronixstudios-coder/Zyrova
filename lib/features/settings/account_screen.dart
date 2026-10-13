import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../auth/login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _username = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await AuthService.getProfile();
    if (mounted) {
      setState(() => _username = p?['username'] ?? '');
    }
  }

  Future<void> _changeUsername(AppStrings t) async {
    final ctrl = TextEditingController(text: _username);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(t.changeUsername,
            style: TextStyle(color: AppColors.text)),
        content: TextField(
          controller: ctrl,
          style: TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            hintText: t.changeUsernameHint,
            hintStyle: TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel,
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.save,
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await AuthService.updateUsername(ctrl.text);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(t.usernameChanged),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _changePassword(AppStrings t) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(t.changePassword,
            style: TextStyle(color: AppColors.text)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          style: TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            hintText: t.changePasswordHint,
            hintStyle: TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel,
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.save,
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (ok != true || ctrl.text.length < 6) return;
    try {
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(password: ctrl.text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(t.passwordChanged),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${t.error}: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteAccount(AppStrings t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(t.deleteAccount,
            style: TextStyle(color: AppColors.error)),
        content: Text(t.deleteAccountConfirm,
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel,
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.delete,
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (ok != true) return;
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Text(t.account, style: TextStyle(color: AppColors.text)),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.person, color: AppColors.text),
            title: Text(t.username,
                style: TextStyle(color: AppColors.text)),
            subtitle: Text('@$_username',
                style: TextStyle(color: AppColors.textSecondary)),
            trailing:
                Icon(Icons.edit, color: AppColors.primary, size: 20),
            onTap: () => _changeUsername(t),
          ),
          ListTile(
            leading: Icon(Icons.email, color: AppColors.text),
            title: Text(t.email,
                style: TextStyle(color: AppColors.text)),
            subtitle: Text(user?.email ?? '',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ListTile(
            leading: Icon(Icons.lock, color: AppColors.text),
            title: Text(t.changePassword,
                style: TextStyle(color: AppColors.text)),
            trailing: Icon(Icons.chevron_right,
                color: AppColors.textSecondary),
            onTap: () => _changePassword(t),
          ),
          Divider(color: AppColors.card),
          ListTile(
            leading: Icon(Icons.delete_forever, color: AppColors.error),
            title: Text(t.deleteAccountBtn,
                style: TextStyle(color: AppColors.error)),
            onTap: () => _deleteAccount(t),
          ),
        ],
      ),
    );
  }
}
