import '../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../home/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _isRegister = false;

  Future<void> _submit() async {
    // Validasyon
    if (_userCtrl.text.trim().isEmpty && _isRegister) {
      _showSnack('Kullanıcı adı gerekli', AppColors.error);
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      _showSnack('E-posta gerekli', AppColors.error);
      return;
    }
    if (_passCtrl.text.length < 6) {
      _showSnack('Şifre en az 6 karakter olmalı', AppColors.error);
      return;
    }
    if (!_emailCtrl.text.contains('@') || !_emailCtrl.text.contains('.')) {
      _showSnack('Geçerli bir e-posta gir', AppColors.error);
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isRegister) {
        final res = await AuthService.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          username: _userCtrl.text.trim(),
        );
        if (res == null) throw Exception('Kayıt başarısız');
      } else {
        final res = await AuthService.signIn(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
        if (res == null) throw Exception('Giriş başarısız');
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      _showSnack('Hata: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/zyrova-logo.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100,
                      height: 100,
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
                SizedBox(height: 24),
                Text(
                  _isRegister ? 'Zyrova\'ya Kayıt Ol' : 'Zyrova\'ya Hoş Geldin',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Akıcı bir akış. Akıllı cache.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                SizedBox(height: 32),
                if (_isRegister) ...[
                  TextField(
                    controller: _userCtrl,
                    style: TextStyle(color: AppColors.text),
                    decoration: _inputDecor('Kullanıcı adı', Icons.person),
                  ),
                  SizedBox(height: 16),
                ],
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: AppColors.text),
                  decoration: _inputDecor('E-posta', Icons.email),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  style: TextStyle(color: AppColors.text),
                  decoration: _inputDecor('Şifre (en az 6 karakter)', Icons.lock),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isRegister ? 'Kayıt Ol' : 'Giriş Yap',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() => _isRegister = !_isRegister);
                  },
                  child: Text(
                    _isRegister
                        ? 'Hesabın var mı? Giriş yap'
                        : 'Hesabın yok mu? Kayıt ol',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
