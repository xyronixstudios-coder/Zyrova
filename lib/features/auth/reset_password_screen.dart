import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  Future<void> _save() async {
    final p1 = _passCtrl.text;
    final p2 = _confirmCtrl.text;

    if (p1.length < 6) {
      _snack('Şifre en az 6 karakter', AppColors.error);
      return;
    }
    if (p1 != p2) {
      _snack('Şifreler uyuşmuyor', AppColors.error);
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.updatePassword(p1);
      if (!mounted) return;
      _snack('Şifre güncellendi! ✅', AppColors.success);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      _snack('Hata: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: c),
    );
  }

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Icon(Icons.lock_reset, color: AppColors.primary, size: 80),
              const SizedBox(height: 24),
              Text('Yeni Şifre Belirle',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 32),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure1,
                style: TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  hintText: 'Yeni şifre (min 6)',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon:
                      Icon(Icons.lock, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure1 ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmCtrl,
                obscureText: _obscure2,
                style: TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  hintText: 'Şifreyi tekrar gir',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon:
                      Icon(Icons.lock, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure2 ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Şifreyi Güncelle',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
