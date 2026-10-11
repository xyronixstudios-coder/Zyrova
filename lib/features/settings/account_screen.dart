import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _changePassword(BuildContext context, AppStrings t) async {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(t.passwordChanged),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {}
  }

  Future<void> _deleteAccount(BuildContext context, AppStrings t) async {
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
    if (context.mounted) {
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
            onTap: () => _changePassword(context, t),
          ),
          Divider(color: AppColors.card),
          ListTile(
            leading: Icon(Icons.delete_forever, color: AppColors.error),
            title: Text(t.deleteAccount,
                style: TextStyle(color: AppColors.error)),
            onTap: () => _deleteAccount(context, t),
          ),
        ],
      ),
    );
  }
}
